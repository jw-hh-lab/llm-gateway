# 밤 자동 정지: EventBridge Scheduler가 매일 정해진 시각에 EC2 StopInstances API를 직접 호출
# (Lambda 없이 AWS API를 바로 부르는 "유니버설 타깃" 방식이라 코드가 필요 없음. 월 1,400만 번까지 무료)

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Scheduler가 EC2를 끌 때 쓰는 신분증: 우리 서버 1대를 "끄는" 권한만
resource "aws_iam_role" "scheduler" {
  name = "${var.name}-scheduler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id } }
    }]
  })
}

resource "aws_iam_role_policy" "stop_ec2" {
  name = "${var.name}-stop-ec2"
  role = aws_iam_role.scheduler.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ec2:StopInstances"
      Resource = "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/${var.instance_id}"
    }]
  })
}

resource "aws_scheduler_schedule" "nightly_stop" {
  name                         = "${var.name}-nightly-stop"
  schedule_expression          = var.stop_cron
  schedule_expression_timezone = "Asia/Seoul" # 한국 시간 기준

  flexible_time_window {
    mode = "OFF" # 정확히 그 시각에 실행
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ InstanceIds = [var.instance_id] })
  }
}
