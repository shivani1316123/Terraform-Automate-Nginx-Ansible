# High Availability Nginx Reverse Proxy Web Application using Terraform , Ansible & Cloudwatch for Monitoring & Alarm Alert

## 📌 Project Overview

This project demonstrates the deployment of a **High Availability Nginx Reverse Proxy Web Application on AWS** using Terraform for infrastructure provisioning, Ansible for configuration management, and Amazon CloudWatch for monitoring and alarm notifications.

The platform hosts five websites — **Employee, Customer, Insurance, Reports, and Support** — across multiple Amazon EC2 instances distributed across Availability Zones. An AWS Application Load Balancer (ALB) distributes incoming traffic across healthy Nginx servers, improving application availability and reliability.

The infrastructure and server configurations are automated to reduce manual effort, improve deployment consistency, and simplify operational recovery.

## 🛠️ Technologies Used

| Technology                          | Purpose                                                     |
| ----------------------------------- | ----------------------------------------------------------- |
| AWS EC2                             | Hosts the Nginx reverse proxy servers                       |
| AWS Application Load Balancer (ALB) | Distributes incoming traffic across healthy instances       |
| AWS VPC                             | Provides network isolation and connectivity                 |
| AWS Security Groups                 | Controls inbound and outbound traffic                       |
| AWS CloudWatch                      | Monitors metrics, logs, and infrastructure health           |
| Terraform                           | Automates AWS infrastructure provisioning                   |
| Ansible                             | Automates Nginx installation and configuration              |
| Nginx                               | Routes incoming requests to the five websites               |
| AWS SNS                             | Sends email notifications for configured alarms, if enabled |
| Linux (Ubuntu)                      | Operating system for the EC2 instances                      |
| Git & GitHub                        | Version control and project documentation                   |

## 🏗️ Architecture

The project uses a multi-instance architecture to provide high availability and reliable application delivery.

**Request flow:**

Client → AWS Application Load Balancer → Healthy EC2 Instance → Nginx Reverse Proxy → Requested Website

**Infrastructure automation flow:**

Terraform → AWS Infrastructure → Ansible → Nginx Configuration → CloudWatch Monitoring → Alarm Notification and Recovery Workflow

### Key Components

* **Terraform:** Provisions AWS resources using Infrastructure as Code (IaC).
* **Application Load Balancer:** Routes incoming HTTP requests to healthy registered targets.
* **EC2 Instances:** Host Nginx reverse proxy servers across multiple Availability Zones.
* **Nginx Reverse Proxy:** Routes requests to the appropriate website based on URL paths.
* **Ansible:** Automates software installation, configuration deployment, and server recovery tasks.
* **CloudWatch:** Monitors infrastructure metrics and triggers alarms when configured thresholds or health conditions are met.
* **Automated Recovery:** Supports a recovery workflow using alarms and configuration automation to restore service.

## 🌐 Websites Hosted

The Nginx reverse proxy routes requests to five websites:

1. Employee
2. Customer
3. Insurance
4. Reports
5. Support

Each website is accessed through its configured URL path, allowing multiple applications to be served through a common entry point.

## ⚙️ Project Implementation Flow

### Step 1: EC2 Instance Setup

* Launched and prepared the EC2 instances.
* Installed and updated the required Linux packages and dependencies.
* Configured the required network access and security group rules.

### Step 2: Infrastructure Provisioning Using Terraform

Automated AWS infrastructure provisioning using Terraform and its four key workflow commands:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

These commands initialize the working directory, validate the configuration, preview infrastructure changes, and create the required AWS resources.

### Step 3: Nginx Configuration Using Ansible

* Configured Ansible inventory for the EC2 instances.
* Automated Nginx installation and configuration.
* Configured reverse proxy rules to route requests to the five websites.
* Executed the Ansible playbook to deploy the configuration.

```bash
ansible-playbook -i inventory.ini site.yml
```

### Step 4: Monitoring and Failure Detection

* Configured AWS CloudWatch monitoring and alarms.
* Simulated an instance or application health failure.
* Used health checks and configured monitoring metrics to detect the issue.
* Triggered the configured alarm and notification workflow.

### Step 5: Recovery and Validation

* Executed the configured recovery workflow for the affected server.
* Re-ran the Ansible playbook when required to restore the Nginx configuration.
* Verified the target health status and application accessibility.
* Confirmed that requests could be served through the available healthy instances.

**Outcome:** The project demonstrates automated infrastructure provisioning, configuration management, health monitoring, and recovery procedures while reducing manual operational effort.

## 📊 Project Output

The following screenshots demonstrate the deployed application and project output.

### Nginx Reverse Proxy Application Output
![Project Output 1](https://github.com/user-attachments/assets/654c8c08-020b-44db-beea-723212a453e0)

![Project Output 2](https://github.com/user-attachments/assets/06cdef04-4fdf-48bc-85ab-1223be3148c0)

## 🎯 Key Benefits

* Automated AWS infrastructure provisioning using Terraform.
* Consistent Nginx configuration through Ansible.
* High availability through multiple EC2 instances and an Application Load Balancer.
* Centralized infrastructure monitoring with CloudWatch.
* Faster troubleshooting through health checks and alarm notifications.
* Reduced manual configuration and operational effort.
* Improved deployment consistency and application reliability.

## 📚 Key Learnings

* Infrastructure as Code (IaC) using Terraform.
* Configuration management and automation using Ansible.
* Nginx reverse proxy configuration and URL-based routing.
* AWS networking, EC2, security groups, and load balancing.
* CloudWatch metrics, alarms, and monitoring workflows.
* High availability, health checks, and failure-recovery procedures.

## 🚀 Future Enhancements

* Integrate a CI/CD pipeline using Jenkins or GitHub Actions.
* Add HTTPS using AWS Certificate Manager.
* Implement centralized log analysis and dashboards.
* Integrate automated notifications and recovery using AWS Lambda and SNS.
* Introduce Auto Scaling to replace failed instances automatically.

## 👩‍💻 Author

**Shivani Shetty**

GitHub: [shivani1316123](https://github.com/shivani1316123)

Project Repository: [Terraform-Automate-Nginx-Ansible](https://github.com/shivani1316123/Terraform-Automate-Nginx-Ansible)

## 🏷️ Tags

`DevOps` `AWS` `Terraform` `Ansible` `Nginx` `CloudWatch` `Infrastructure as Code` `High Availability` `Load Balancing` `Linux` `Cloud Engineering`


