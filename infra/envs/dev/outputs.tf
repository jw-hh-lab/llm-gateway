output "instance_id" {
  value = module.compute.instance_id
}

output "public_ip" {
  value = module.compute.public_ip
}

output "public_dns" {
  value = module.compute.public_dns
}

output "api_url" {
  value = "https://${module.cdn.domain_name}"
}
