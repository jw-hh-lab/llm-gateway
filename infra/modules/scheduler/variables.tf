variable "name" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "stop_cron" {
  description = "정지 시각 (Asia/Seoul). 기본: 매일 밤 12시"
  type        = string
  default     = "cron(0 0 * * ? *)"
}
