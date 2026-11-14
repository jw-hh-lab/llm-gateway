output "domain_name" {
  description = "API 접속 주소 (https://<이 값>)"
  value       = aws_cloudfront_distribution.this.domain_name
}
