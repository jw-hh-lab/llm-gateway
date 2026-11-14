# VPC: 우리 프로젝트 전용 사설 네트워크. 10.10.0.0/16은 나중에 다른 VPC(예: EKS 실습 10.20.0.0/16)와 피어링해도 겹치지 않게 고른 대역
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # EC2에 퍼블릭 DNS 이름이 붙어야 CloudFront 원본으로 쓸 수 있음
  tags                 = { Name = "${var.name}-vpc" }
}

# 인터넷 게이트웨이: VPC와 인터넷 사이의 문 (무료)
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

# 퍼블릭 서브넷 2개(2a, 2c). 지금은 2a만 쓰지만, 9~10주차 ALB는 가용 영역 2개가 필수라 미리 만들어 둠 (서브넷은 무료)
resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false # 공인 IP는 Elastic IP로만 붙임
  tags                    = { Name = "${var.name}-public-${each.key}" }
}

# 라우팅 테이블: "VPC 밖(0.0.0.0/0)으로 가는 건 인터넷 게이트웨이로" (무료)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# CloudFront가 원본 서버로 요청을 보낼 때 쓰는 IP 목록(AWS가 관리)
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# 보안 그룹: 80번은 CloudFront에서 오는 것만 허용. SSH(22)는 아예 안 열고 SSM으로 접속
resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "k3s node: HTTP from CloudFront only"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${var.name}-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "http_from_cloudfront" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP from CloudFront"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

# 나가는 건 전부 허용 (Gemini API, GHCR 이미지, 패키지 설치, SSM 통신)
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
