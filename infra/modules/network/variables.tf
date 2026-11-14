variable "name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_subnets" {
  description = "가용 영역 => CIDR"
  type        = map(string)
  default = {
    "ap-northeast-2a" = "10.10.1.0/24"
    "ap-northeast-2c" = "10.10.2.0/24"
  }
}
