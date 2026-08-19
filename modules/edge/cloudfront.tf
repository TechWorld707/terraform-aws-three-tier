resource "aws_cloudfront_cache_policy" "frontend" {
  name        = "${var.name}-frontend-cache"
  comment     = "Static frontend caching for ${var.name}"
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "api" {
  name        = "${var.name}-api-no-cache"
  comment     = "Disable API response caching for ${var.name}"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "api" {
  name    = "${var.name}-api-origin-request"
  comment = "Forward application API request values to the ALB"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"

    headers {
      items = [
        "Accept",
        "Authorization",
        "Content-Type",
        "Origin",
        "Referer",
        "User-Agent"
      ]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name = substr("${var.name}-security-headers", 0, 128)

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = true
    }

    xss_protection {
      mode_block = true
      override   = true
      protection = true
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  #checkov:skip=CKV2_AWS_47:The attached CloudFront WAF includes AWSManagedRulesKnownBadInputsRuleSet, but Checkov cannot resolve the dynamically generated managed rule.
  #checkov:skip=CKV_AWS_310:Origin failover requires duplicate origins and is deferred because this portfolio environment uses one frontend bucket and one application ALB.
  #checkov:skip=CKV_AWS_374:The application is intentionally globally available; geographic restrictions are not a project requirement.
  #checkov:skip=CKV_AWS_86:CloudFront standard access logging is deferred until a dedicated centralized log-archive bucket is implemented; WAF logging remains enabled.
  enabled         = true
  is_ipv6_enabled = var.enable_ipv6
  comment         = "Edge distribution for ${var.name}"
  price_class     = var.price_class

  default_root_object = var.default_root_object
  web_acl_id          = aws_wafv2_web_acl.cloudfront.arn

  aliases = var.domain_name == null ? [] : [
    var.domain_name
  ]

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "frontend-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  origin {
    domain_name = var.alb_domain_name
    origin_id   = "application-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id           = "frontend-s3"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    cache_policy_id            = aws_cloudfront_cache_policy.frontend.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]
  }

  ordered_cache_behavior {
    path_pattern               = "/api/*"
    target_origin_id           = "application-alb"
    viewer_protocol_policy     = "https-only"
    compress                   = true
    cache_policy_id            = aws_cloudfront_cache_policy.api.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.api.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    allowed_methods = [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == null
    acm_certificate_arn            = var.acm_certificate_arn

    ssl_support_method = (
      var.acm_certificate_arn == null
      ? null
      : "sni-only"
    )

    minimum_protocol_version = (
      var.acm_certificate_arn == null
      ? "TLSv1"
      : "TLSv1.2_2021"
    )
  }

  tags = local.common_tags

  lifecycle {
    precondition {
      condition = (
        (
          var.domain_name == null &&
          var.acm_certificate_arn == null
        ) ||
        (
          var.domain_name != null &&
          var.acm_certificate_arn != null
        )
      )

      error_message = "domain_name and acm_certificate_arn must either both be null or both be provided."
    }
  }
}