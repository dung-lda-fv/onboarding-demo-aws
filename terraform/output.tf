output "instance_id" {
  value = aws_instance.app_server.id
}

output "instance_ip" {
  value = aws_instance.app_server.private_ip
}