# High-Availability Automated Nginx Web Platform (with Prometheus + Grafana)

Terraform provisions the AWS infrastructure; Ansible configures the servers.
5 static web apps sit behind an ALB and 2 Nginx reverse-proxy servers, path-routed
as `/employee`, `/customer`, `/insurance`, `/reports`, `/support`. A third server
runs Prometheus + Grafana to monitor everything.

## 1. Architecture

```
                     Internet
                        |
                 [ Application Load Balancer ]   (port 80, health check /health)
                    /              \
        [ Nginx Web Server 1 ]  [ Nginx Web Server 2 ]     <- AZ-a / AZ-b
        - reverse proxy              - reverse proxy
        - 5 static sites             - 5 static sites
        - node_exporter :9100        - node_exporter :9100
        - nginx_exporter :9113       - nginx_exporter :9113
                    \              /
                (scraped over private IP)
                        |
              [ Monitoring Server ]
              - Prometheus :9090  (scrapes both web servers + itself)
              - Grafana    :3000  (dashboards, datasource = local Prometheus)
              - node_exporter :9100 (self-monitoring)
```

Everything lives in one VPC across 2 public subnets (2 AZs). Security groups:
- **ALB SG**: 80 open to the internet
- **Web SG**: 80 from ALB only, 22 from your IP, 9100/9113 from the monitoring server only
- **Monitoring SG**: 9090/3000/22 from your IP only — Prometheus and Grafana are never exposed publicly

## 2. Repo layout

```
ha-nginx-platform/
├── terraform/                  # infra: VPC, subnets, ALB, EC2 x3, security groups
└── ansible/
    ├── site.yml                 # nginx + websites -> webservers group
    ├── site-monitoring.yml      # node_exporter/nginx_exporter -> webservers,
    │                            # node_exporter/prometheus/grafana -> monitoring
    └── roles/
        ├── nginx/               # reverse proxy config, stub_status, /health
        ├── websites/            # 5 static sites (employee/customer/insurance/reports/support)
        ├── node_exporter/       # host metrics (installed on all 3 servers)
        ├── nginx_exporter/      # nginx metrics (installed on the 2 web servers)
        ├── prometheus/          # Prometheus server + scrape config
        └── grafana/             # Grafana + provisioned datasource + dashboard
```

## 3. Prerequisites

- AWS account with an IAM user/role that has EC2, VPC, and ELB permissions
- AWS CLI configured: `aws configure`
- Terraform >= 1.5: `terraform -version`
- Ansible >= 2.14 on your machine: `ansible --version`
- An EC2 key pair created in your target region:
  ```bash
  aws ec2 create-key-pair --key-name ha-nginx-key \
    --query 'KeyMaterial' --output text --region ap-south-1 > ~/.ssh/ha-nginx-key.pem
  chmod 400 ~/.ssh/ha-nginx-key.pem
  ```
- Your public IP in CIDR form (for locking down SSH/Prometheus/Grafana):
  ```bash
  curl -s https://checkip.amazonaws.com
  # append /32, e.g. 49.36.11.20/32
  ```

## 4. Step-by-step: provision the infrastructure (Terraform)

```bash
cd ha-nginx-platform/terraform

# 1. Copy the example vars file and fill in your key name + IP
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# 2. Initialize providers
terraform init

# 3. Review the plan (3 EC2 instances, VPC, ALB, target group, 3 security groups)
terraform plan

# 4. Apply
terraform apply
# type "yes" when prompted

# 5. Note the outputs — you'll need these for the Ansible inventory
terraform output
```

You should see `nginx_public_ips`, `monitoring_public_ip`, `alb_dns_name`,
`prometheus_url`, and `grafana_url` in the output.

## 5. Step-by-step: configure the servers (Ansible)

```bash
cd ../ansible

# 1. Copy the inventory template and fill in the IPs from `terraform output`
cp inventory.ini.example inventory.ini
nano inventory.ini

# 2. Test connectivity to all 3 servers
ansible all -m ping

# 3. Deploy Nginx + the 5 websites to the web servers
ansible-playbook site.yml

# 4. Deploy Prometheus + Grafana + exporters
ansible-playbook site-monitoring.yml
```

`site.yml` finishes with a health check against `/health` and each site path,
so a failed deploy shows up immediately in the Ansible output rather than
silently leaving a broken server in the target group.

## 6. Verify the platform

**Websites (via the ALB):**
```bash
terraform -chdir=../terraform output website_urls
curl -i http://<alb_dns_name>/employee/
```
Open any of the 5 URLs in a browser — the ALB will route to whichever web
server is healthy.

**Monitoring:**
```bash
# Prometheus — check both web servers show as "up" under Status > Targets
open http://<monitoring_public_ip>:9090/targets

# Grafana — default login is admin / admin (you'll be prompted to change it)
open http://<monitoring_public_ip>:3000
```
The **HA Nginx Platform - Overview** dashboard is already provisioned on
first login (Dashboards → HA Nginx Platform → Overview) with panels for:
targets up, CPU %, memory %, Nginx requests/sec, active connections, and
disk free %.

## 7. Simulating a failure (to see the HA part in action)

```bash
# Stop nginx on one web server
ssh -i ~/.ssh/ha-nginx-key.pem ubuntu@<nginx_public_ip_1> "sudo systemctl stop nginx"

# Watch the ALB target group mark it unhealthy (takes ~30-45s with the
# health_check settings in alb.tf), then confirm the site is still reachable
curl -i http://<alb_dns_name>/employee/

# In Prometheus, the "up" metric for that instance's node_exporter/nginx_exporter
# job will flip to 0, and the Grafana dashboard's "Targets Up" stat will drop

# Bring it back
ssh -i ~/.ssh/ha-nginx-key.pem ubuntu@<nginx_public_ip_1> "sudo systemctl start nginx"
```

## 8. Making changes

- **Site content**: edit `ansible/roles/websites/templates/index.html.j2` /
  `style.css.j2`, or the `sites` list in `ansible/roles/websites/defaults/main.yml`,
  then re-run `ansible-playbook site.yml`.
- **Nginx config / new routes**: edit `ansible/roles/nginx/templates/nginx.conf.j2`,
  re-run `ansible-playbook site.yml`.
- **Scrape targets / alerting rules**: edit
  `ansible/roles/prometheus/templates/prometheus.yml.j2`, re-run
  `ansible-playbook site-monitoring.yml`.
- **Dashboard**: edit
  `ansible/roles/grafana/files/ha-nginx-overview-dashboard.json` (or just
  edit it live in the Grafana UI and export the JSON back into this file),
  re-run `ansible-playbook site-monitoring.yml`.

## 9. Tearing everything down

```bash
cd terraform
terraform destroy
# type "yes" when prompted
```

This removes both EC2 web servers, the monitoring server, the ALB, target
group, security groups, and the VPC. Nothing else in your AWS account is
touched.

## 10. Notes / things to call out in an interview

- Prometheus and Grafana are **not** internet-facing — only reachable from
  your own IP, which is the same principle as keeping a database or admin
  panel off the public internet.
- `node_exporter` runs on all 3 servers (including the monitoring server
  itself), so the monitoring stack monitors its own host too.
- The ALB's own health check (`/health`) is independent of Prometheus —
  even if the monitoring server is down, the ALB still stops routing to an
  unhealthy web server.
- Everything is idempotent: re-running `ansible-playbook site.yml` or
  `site-monitoring.yml` any number of times converges to the same state
  rather than erroring or duplicating resources.
