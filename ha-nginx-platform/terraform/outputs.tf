output "alb_dns_name" {
  description = "Public URL of the load balancer — open this in a browser"
  value       = aws_lb.main.dns_name
}

output "website_urls" {
  description = "Direct path-based URLs for each of the 5 sites"
  value = {
    employee = "http://${aws_lb.main.dns_name}/employee/"
    customer = "http://${aws_lb.main.dns_name}/customer/"
    insurance = "http://${aws_lb.main.dns_name}/insurance/"
    reports  = "http://${aws_lb.main.dns_name}/reports/"
    support  = "http://${aws_lb.main.dns_name}/support/"
  }
}

output "nginx_public_ips" {
  description = "Public IPs of the 2 Nginx servers (for SSH / Ansible inventory)"
  value       = aws_instance.nginx[*].public_ip
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring server (for SSH / Ansible inventory)"
  value       = aws_instance.monitoring.public_ip
}

output "prometheus_url" {
  description = "Prometheus UI (only reachable from your IP)"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana UI (only reachable from your IP, default login admin/admin)"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}
