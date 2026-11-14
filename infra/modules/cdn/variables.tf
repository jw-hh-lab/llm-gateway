variable "name" {
  type = string
}

variable "origin_domain" {
  description = "원본 서버 도메인 (EC2 퍼블릭 DNS)"
  type        = string
}
