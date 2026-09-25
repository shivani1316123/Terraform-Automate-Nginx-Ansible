# High-Availability Automated Nginx Web Platform

Five websites, served through an **Nginx reverse proxy** on **two EC2 servers** behind an
**AWS Application Load Balancer**. **Terraform** builds the AWS infrastructure, **Ansible**
configures the servers, **CloudWatch** detects failures, and **systemd + EC2 auto-recovery + Ansible**
bring things back.

```
                    Internet
                       |
              AWS Application Load Balancer   (health check: GET /health)
                       |
          +------------+------------+
          |                         |
   EC2 nginx-1 (AZ-a)         EC2 nginx-2 (AZ-b)
   Nginx :80  reverse proxy   Nginx :80  reverse proxy
     /employee  -> 127.0.0.1:8001
     /customer  -> 127.0.0.1:8002
     /insurance -> 127.0.0.1:8003
     /reports   -> 127.0.0.1:8004
     /support   -> 127.0.0.1:8005
     /          -> landing page
          |
   CloudWatch alarms -> SNS email -> (you) -> ansible-playbook site.yml
```

**Terraform creates things. Ansible configures things.** Terraform never installs Nginx and
Ansible never creates AWS resources. Terraform hands Ansible the server IPs by writing
`ansible/inventory.ini` automatically.

---

## 1. Where every command runs

| Place | What runs there |
|---|---|
| **Your computer** (Linux, macOS, or WSL2 Ubuntu on Windows) | Terraform, Ansible, AWS CLI, SSH, curl. This is the "control machine". Every command in this guide is run here unless it says otherwise. |
| **AWS** | Created by Terraform: VPC, subnets, ALB, 2 EC2 servers, alarms. |
| **The 2 EC2 servers** | Nginx and the websites. Ansible logs in over SSH and configures them. You only SSH in manually for the failure tests. |

## 2. One-time setup on your computer

```bash
# Ansible + tools
sudo apt update && sudo apt install -y ansible unzip curl

# Terraform (official HashiCorp repository)
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip && sudo ./aws/install

# Give the CLI your credentials (IAM user access key; needs EC2, ELB, VPC, CloudWatch, SNS permissions)
aws configure
aws sts get-caller-identity        # must print your account ID
```

Check versions: `terraform -version` (>= 1.5) and `ansible --version`.

## 3. Step-by-step workflow

### Step 1 - Create an SSH key pair
```bash
ssh-keygen -t ed25519 -f ~/.ssh/ha-nginx-key -N ""
```
Creates `ha-nginx-key` (private, never share) and `ha-nginx-key.pub` (public). Terraform uploads
the public key to AWS so the servers accept it; Ansible logs in with the private key.

### Step 2 - Configure Terraform
```bash
cd ha-nginx-platform/terraform
cp terraform.tfvars.example terraform.tfvars
curl -s https://checkip.amazonaws.com        # your public IP
nano terraform.tfvars                         # set ssh_allowed_cidr = "<your-ip>/32"
```
`ssh_allowed_cidr` makes SSH (port 22) reachable only from your IP.

### Step 3 - Build the infrastructure
```bash
terraform init        # downloads the AWS and local providers
terraform fmt         # tidies formatting
terraform validate    # syntax check
terraform plan        # shows exactly what will be created; creates nothing
terraform apply       # type "yes"; takes about 3 minutes
```
Terraform creates: VPC, 2 public subnets (2 AZs), internet gateway, route table, 2 security groups,
key pair, 2 EC2 servers, ALB + target group + listener, SNS topic, 3 CloudWatch alarms, and the file
`ansible/inventory.ini`.

Useful outputs any time: `terraform output`

> Right after this step the ALB shows both servers as **unhealthy**. That is expected: Nginx is not
> installed yet, so `/health` does not answer. Step 5 fixes it.

### Step 4 - Test that Ansible can reach the servers
```bash
cd ../ansible
cat inventory.ini                        # written by Terraform
ansible nginx_servers -m ping            # expect "pong" from nginx-1 and nginx-2
```
If it times out, wait one minute (servers are still booting) and retry.

### Step 5 - Configure Nginx and deploy the websites
```bash
ansible-playbook site.yml
```
What happens on each server (one server at a time, `serial: 1`, so the other keeps serving):

1. **nginx role**: installs Nginx, removes the default site, writes the config files, adds a systemd
   override so Nginx restarts itself if it crashes, validates with `nginx -t`, starts and enables Nginx.
2. **websites role**: creates `/var/www/<site>/`, copies the shared CSS, renders each site's
   `index.html` from one template plus the data in `group_vars/all.yml`.
3. **post_tasks**: calls `/health` and all 5 site URLs locally; the play fails if any does not return 200.

Dry run before changing anything: `ansible-playbook site.yml --check --diff`.
One server only: `ansible-playbook site.yml --limit nginx-1`.

### Step 6 - Open the platform
```bash
cd ../terraform
terraform output website_urls
```
Give the ALB about a minute to mark the targets healthy, then open the `alb_dns_name` in a browser.
You get the landing page, and `/employee/`, `/customer/`, `/insurance/`, `/reports/`, `/support/`.
The footer of every page says which server answered.

### Step 7 - Prove load balancing
```bash
ALB=$(terraform output -raw alb_dns_name)
for i in $(seq 1 10); do curl -sI http://$ALB/ | grep -i x-served-by; done
```
You should see both `nginx-1` and `nginx-2`.

### Step 8 - Prove failure detection and recovery

**A. Server outage (ALB failover).**
```bash
$(terraform output -json ssh_commands | jq -r '.[0]') 'sudo systemctl stop nginx'
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn) --region ap-south-1
for i in $(seq 1 6); do curl -sI http://$ALB/ | grep -i x-served-by; done   # only nginx-2 now
```
After about 30 seconds the ALB marks nginx-1 unhealthy and stops sending traffic to it. The site stays up.
CloudWatch raises the `unhealthy-hosts` alarm (and emails you if `alert_email` is set). Restore:
`ssh ... 'sudo systemctl start nginx'`.

**B. Nginx crash (automatic process recovery).** SSH to a server and run `sudo pkill -9 nginx`, then
`systemctl status nginx` a few seconds later: systemd has restarted it (`Restart=always`, 5 s delay).

**C. Configuration drift (Ansible reconfigures).** On a server delete the proxy config:
`sudo rm /etc/nginx/conf.d/reverse-proxy.conf && sudo systemctl reload nginx`. Then, from your computer,
run `ansible-playbook site.yml`. Ansible rewrites the file and reloads Nginx, because playbooks
describe the desired state and are safe to re-run.

**D. Hardware failure.** The `auto-recover` alarm on each instance moves a failed instance to healthy
hardware automatically (same instance ID, same disk).

### Step 9 - Destroy everything (stops all charges)
```bash
cd terraform
terraform destroy      # type "yes"
```
The ALB costs money per hour, so destroy when you finish a demo.

---

## 4. What each file does

| File | Purpose |
|---|---|
| `terraform/providers.tf` | Pins Terraform and provider versions; sets the region and default tags. |
| `terraform/variables.tf` | Every setting you can change (region, instance type, key paths, your IP). |
| `terraform/vpc.tf` | VPC, 2 public subnets in different AZs, internet gateway, route table. |
| `terraform/security-groups.tf` | ALB: port 80 from the internet. Servers: port 80 **only from the ALB**, port 22 only from your IP. |
| `terraform/ec2.tf` | Ubuntu 22.04 AMI lookup, key pair, 2 servers (one per AZ), and the generated Ansible inventory. |
| `terraform/inventory.tpl` | Template for `ansible/inventory.ini`. |
| `terraform/alb.tf` | Load balancer, target group with the `/health` check, listener on port 80. |
| `terraform/monitoring.tf` | SNS topic, unhealthy-host alarm, per-instance auto-recover alarm. |
| `terraform/outputs.tf` | ALB address, website URLs, server IPs, SSH commands. |
| `ansible/ansible.cfg` | Default inventory, sudo on, SSH pipelining. |
| `ansible/group_vars/all.yml` | **The data for all 5 websites** (title, port, colors, text, stats). Add a site by adding an entry. |
| `ansible/site.yml` | The playbook: runs both roles, then verifies. |
| `roles/nginx/tasks/main.yml` | Installs and configures Nginx. |
| `roles/nginx/templates/backends.conf.j2` | 5 private server blocks on `127.0.0.1:8001-8005`. |
| `roles/nginx/templates/reverse-proxy.conf.j2` | The public server block on port 80: `/health`, the landing page and the 5 proxy routes. |
| `roles/nginx/templates/proxy-params.conf.j2` | Headers and timeouts shared by all proxy routes. |
| `roles/websites/files/style.css` | Shared design system. |
| `roles/websites/templates/index.html.j2` | Template that produces each website. |
| `roles/websites/templates/hub.html.j2` | Landing page at `/`. |

## 5. How the reverse proxy works

A browser requests `http://<ALB>/insurance/`:

1. The ALB picks a healthy server and forwards the request to its port 80.
2. Nginx's public server block matches `location /insurance/`.
3. `proxy_pass http://app_insurance/;` forwards it to `127.0.0.1:8003`. The trailing `/` removes the
   `/insurance` prefix, so the backend sees a plain `/` and serves `/var/www/insurance/index.html`.
4. The backend answers through the proxy back to the browser.

The backends listen on `127.0.0.1` only, so nobody can reach a site except through the proxy.
`location = /insurance` redirects to `/insurance/` so relative links such as `style.css` resolve correctly.

## 6. Troubleshooting

| Symptom | Fix |
|---|---|
| `ansible ... UNREACHABLE` | Wait a minute for boot; check `ssh_allowed_cidr` still matches your IP (`curl checkip.amazonaws.com`); `ssh -i ~/.ssh/ha-nginx-key ubuntu@<ip>` manually. |
| ALB targets stay unhealthy | Run `ansible-playbook site.yml`; on a server run `curl -i localhost/health` and `sudo nginx -t`. |
| 502 from the ALB | All targets unhealthy; see the row above. |
| 404 on `/employee/` | Check `ls /var/www/employee` and `/var/log/nginx/error.log`. |
| `terraform apply` says key file not found | Fix `public_key_path` in `terraform.tfvars`. |
| Your IP changed | Update `ssh_allowed_cidr`, run `terraform apply`. |

## 7. Ideas to extend the project

* **Docker**: run each site as a container on 8001-8005 instead of a plain Nginx block. The proxy
  config does not change; add a `docker` role to Ansible. **Implemented below.**
* **Prometheus/Grafana**: add `nginx-prometheus-exporter` via a new Ansible role.
* **HTTPS**: ACM certificate + a 443 listener on the ALB.
* **Auto Scaling Group**: replace the two `aws_instance` resources with a launch template + ASG.
* **Private subnets + NAT + SSM**: remove public IPs and SSH for a production-style setup.

## 8. Docker variant

This runs each of the 5 websites as its own Docker container instead of static files served
directly by Nginx. The reverse proxy in `roles/nginx` does not change at all — it still forwards
`/employee/` to `127.0.0.1:8001`, etc. Only *what's listening* on those ports changes: a container
instead of an Nginx `server {}` block.

```
EC2
 |
 +-- Nginx (unchanged) -- public reverse proxy on :80
 |
 +-- Docker
      +-- web-employee   container -> 127.0.0.1:8001
      +-- web-customer   container -> 127.0.0.1:8002
      +-- web-insurance  container -> 127.0.0.1:8003
      +-- web-reports    container -> 127.0.0.1:8004
      +-- web-support    container -> 127.0.0.1:8005
```

New files added for this:

| File | Purpose |
|---|---|
| `ansible/requirements.yml` | Declares the `community.docker` collection the new role needs. |
| `ansible/site-docker.yml` | Playbook variant: runs the `nginx` role, then `docker` instead of `websites`. |
| `roles/docker/tasks/main.yml` | Installs Docker Engine, builds one image per site, runs one container per site, bound to `127.0.0.1` only. |
| `roles/docker/templates/Dockerfile.j2` | `nginx:1.27-alpine` base image, copies in that site's `index.html` and `style.css`. |

It reuses the same website content: each site's `index.html` is rendered from the existing
`roles/websites/templates/index.html.j2` and `group_vars/all.yml`, then baked into that site's
own Docker image, so the pages look identical to the non-Docker version.

### Steps to switch to the Docker version

You need the infrastructure from Steps 1-4 already applied (VPC, EC2 servers, ALB, inventory).
From there:

```bash
cd ha-nginx-platform/ansible

# 1. Install the collection the docker role depends on
ansible-galaxy collection install -r requirements.yml

# 2. Run the Docker playbook instead of site.yml
ansible-playbook site-docker.yml
```

What happens on each server (one at a time, so the other keeps serving):
1. The `nginx` role runs exactly as before — public reverse proxy on port 80.
2. The `docker` role installs Docker Engine from Docker's official apt repository, installs the
   Python `docker` SDK (needed by Ansible's Docker modules), then for every site in
   `group_vars/all.yml`: writes a build context to `/opt/docker-sites/<slug>/`, builds an image
   `ha-nginx/<slug>:latest`, and runs it as container `web-<slug>` published only to
   `127.0.0.1:<port>` — so, as before, nothing but Nginx can reach it.
3. `post_tasks` checks `/health` and all 5 proxied URLs return 200, same as the static version.

Open the site the same way as before:
```bash
cd ../terraform && terraform output website_urls
```

### Checking and troubleshooting the containers

SSH into a server (`terraform output ssh_commands`) and run:
```bash
docker ps                              # 5 containers, all "Up"
docker logs web-employee               # that site's Nginx access/error log
docker inspect web-employee | grep IPAddress
curl -i http://127.0.0.1:8001/         # bypasses the reverse proxy, hits the container directly
```

To update a site's content after changing `group_vars/all.yml`, just re-run the playbook —
`docker_image` rebuilds the image and `docker_container` (with `recreate: true`) replaces the
running container:
```bash
ansible-playbook site-docker.yml --limit nginx-1   # roll out to one server at a time
```

### Switching back to static files

Nothing needs to be undone — `site.yml` (the static version) and `site-docker.yml` (this version)
both write to the same reverse-proxy config, so re-running `ansible-playbook site.yml` puts the
static files back. The old containers keep running on their ports until you remove them:
```bash
docker stop web-employee web-customer web-insurance web-reports web-support
docker rm   web-employee web-customer web-insurance web-reports web-support
```
