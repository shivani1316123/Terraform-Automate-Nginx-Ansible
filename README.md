# High Availability Nginx Reverse Proxy Web Application using Terraform , Ansible & Cloudwatch for Monitoring & Alarm Alert

- Automated AWS infrastructure provisioning using Terraform to deploy a high-availability Nginx reverse-proxy web platform hosting five websites across multiple EC2 instances.
- Automated Nginx configuration and deployment using Ansible, reducing manual server setup and configuration effort.
- Implemented AWS CloudWatch monitoring, metrics and alarms to detect infrastructure and application issues.
- Improved deployment consistency and operational efficiency by automating infrastructure provisioning, server configuration, and monitoring workflows.

Nginx Reverse Proxy - it acts as an intermediate gateway that accepts incoming client traffic and forwarding it to one or more backend application servers. This setup is commonly used to protect the backend infrastructure , handle SSL termination and enable load balancing.

Project Implementation Flow

1. **EC2 Instance Setup:** Launched the EC2 instances and installed and updated the required software packages and dependencies.

2. **Infrastructure Provisioning Using Terraform:** Automated the provisioning of AWS infrastructure using Terraform, following the four key phases: `terraform init`, `terraform validate`, `terraform plan`, and `terraform apply`.

3. **Nginx Configuration Using Ansible:** Configured the Nginx servers using Ansible to implement the reverse proxy mechanism and route incoming requests to the five web applications.

4. **Failure Detection and Automated Recovery:** Simulated an EC2 instance failure by making one instance unhealthy. Monitored the failure through AWS health checks and CloudWatch alarms, triggered the recovery process, and re-executed the Ansible playbook (`site.yml`) to restore the Nginx configuration.

5. **Application Recovery and High Availability:** Verified that the failed instance recovered successfully and the application returned to a healthy state. This automated workflow minimizes manual intervention, improves availability, and ensures reliable application delivery.


Project Output:

<img width="975" height="490" alt="image" src="https://github.com/user-attachments/assets/654c8c08-020b-44db-beea-723212a453e0" />

<img width="975" height="487" alt="image" src="https://github.com/user-attachments/assets/06cdef04-4fdf-48bc-85ab-1223be3148c0" />

#DevOps #Cloud #DevopsLife #InfrastructureasaCode #IaC #Ansible #CloudWatch



