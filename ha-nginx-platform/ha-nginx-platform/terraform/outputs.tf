output "alb_dns_name" {
  description = "Public entry point of the platform"
  value       = aws_lb.web.dns_name
}

output "website_urls" {
  description = "URL of every website (served through the Nginx reverse proxy)"
  value       = { for s in var.site_slugs : s => "http://${aws_lb.web.dns_name}/${s}/" }
}

output "instance_public_ips" {
  value = aws_instance.nginx[*].public_ip
}

output "ssh_commands" {
  value = [for ip in aws_instance.nginx[*].public_ip : "ssh -i ${var.private_key_path} ubuntu@${ip}"]
}

output "target_group_arn" {
  description = "Used by the failover test: aws elbv2 describe-target-health"
  value       = aws_lb_target_group.web.arn
}
