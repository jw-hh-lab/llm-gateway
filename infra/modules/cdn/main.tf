# CloudFront: 사용자 앞단의 HTTPS 입구. 인증서 없이도 *.cloudfront.net 주소로 HTTPS를 제공하고,
# 원본(EC2)까지는 HTTP 80으로 넘김(보안 그룹이 CloudFront IP만 허용)

# AWS가 미리 만들어 둔 정책(관리형 정책)
data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled" # API 응답은 고객마다 다르므로 캐시하지 않음
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader" # Authorization 헤더·쿼리·쿠키를 원본에 그대로 전달
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  comment         = "${var.name} API"
  price_class     = "PriceClass_200" # 한국 엣지 포함, 가장 비싼 남미 등은 제외
  is_ipv6_enabled = true

  origin {
    origin_id   = "ec2"
    domain_name = var.origin_domain # EC2 퍼블릭 DNS (CloudFront 원본은 IP를 못 받음)

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30 # 응답(스트리밍 조각) 사이 최대 대기. 회의에서 정한 30초
      origin_keepalive_timeout = 5
    }
  }

  default_cache_behavior {
    target_origin_id         = "ec2"
    viewer_protocol_policy   = "redirect-to-https" # http로 오면 https로 돌려보냄
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
    compress                 = false # SSE 스트리밍은 압축하면 조각이 모였다가 나갈 수 있어서 끔
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # *.cloudfront.net 기본 인증서(무료). 도메인은 나중에
  }

  tags = { Name = "${var.name}-cdn" }
}
