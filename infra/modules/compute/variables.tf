variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "root_volume_gb" {
  type    = number
  default = 30
}
