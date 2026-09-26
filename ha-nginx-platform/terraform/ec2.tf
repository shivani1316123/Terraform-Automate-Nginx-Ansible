# ---------------------------------------------------------------------------
# 2 Nginx web servers, one per AZ, behind the ALB
# ---------------------------------------------------------------------------
resource "aws_instance" "nginx" {
  count                       = 2
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[count.index].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
    Role = "nginx"
  }
}

# ---------------------------------------------------------------------------
# 1 monitoring server: Prometheus + Grafana
# ---------------------------------------------------------------------------
resource "aws_instance" "monitoring" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-monitoring"
    Role = "monitoring"
  }
}
