# 최신 Amazon Linux 2023(ARM) 이미지. SSM 에이전트가 미리 깔려 있어서 SSH 없이 접속 가능
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------- IAM 역할: EC2가 키 없이 AWS 서비스를 쓰게 해 주는 신분증 ----------
resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

# SSM 접속(Session Manager)용 AWS 관리형 정책
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 앱에 필요한 최소 권한: 우리 프로젝트 경로의 SSM 파라미터 읽기 + Nova Micro 호출
resource "aws_iam_role_policy" "app" {
  name = "${var.name}-app"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadProjectParams"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.name}/*"
      },
      {
        Sid    = "InvokeNovaMicro"
        Effect = "Allow"
        Action = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/amazon.nova-micro-v1:0",
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/*nova-micro*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ---------- EC2 ----------
resource "aws_instance" "k3s" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true # 부팅 직후 k3s 설치용 인터넷. Elastic IP가 붙으면 그걸로 바뀜

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_gb
    encrypted   = true
  }

  # IMDSv2 강제(보안). hop 2는 Pod 안에서도 역할 자격 증명을 받을 수 있게
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # 처음 켜질 때 k3s 설치. 기본 Ingress(traefik)는 끄고 ingress-nginx를 따로 올림
  user_data = <<-SH
    #!/bin/bash
    set -eux
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --write-kubeconfig-mode 644" sh -
  SH

  tags = { Name = "${var.name}-k3s" }

  lifecycle {
    ignore_changes = [ami, user_data] # 새 AMI가 나와도 서버를 갈아엎지 않게
  }
}

# Elastic IP: 껐다 켜도 주소 고정 (월 ~$3.6, 꺼 둬도 나감)
resource "aws_eip" "k3s" {
  domain   = "vpc"
  instance = aws_instance.k3s.id
  tags     = { Name = "${var.name}-eip" }
}
