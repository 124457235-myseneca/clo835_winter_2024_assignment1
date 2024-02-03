output "instance_ip" {
  value = aws_instance.aws_ins_web.public_ip
}

output "lb_dns" {
  value = aws_lb.webapp-alb.dns_name
}
