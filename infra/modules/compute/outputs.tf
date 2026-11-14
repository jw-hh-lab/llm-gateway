output "instance_id" {
  value = aws_instance.k3s.id
}

output "public_ip" {
  value = aws_eip.k3s.public_ip
}

output "public_dns" {
  value = aws_eip.k3s.public_dns
}
