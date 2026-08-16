mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"cloudfront.amazonaws.com\"},\"Action\":\"s3:GetObject\",\"Resource\":\"*\"}]}"
    }
  }
}

mock_provider "random" {}

override_resource {
  target          = random_id.bucket_suffix
  override_during = plan

  values = {
    hex = "a1b2c3d4"
    id  = "test-suffix"
  }
}

override_resource {
  target          = aws_cloudfront_distribution.this
  override_during = plan

  values = {
    arn            = "arn:aws:cloudfront::123456789012:distribution/TEST123"
    domain_name    = "d123example.cloudfront.net"
    hosted_zone_id = "Z2FDTNDATAQYW2"
    id             = "TEST123"
  }
}

variables {
  name                      = "test-platform-dev"
  alb_domain_name           = "test-alb.us-east-1.elb.amazonaws.com"
  frontend_source_directory = "../../frontend"
  frontend_force_destroy    = true

  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  enable_ipv6         = true
  waf_rate_limit      = 1000

  domain_name         = null
  acm_certificate_arn = null

  tags = {
    Environment = "test"
  }
}

run "edge_platform_plan" {
  command = plan

  assert {
    condition = (
      aws_s3_bucket.frontend.bucket ==
      "test-platform-dev-frontend-a1b2c3d4"
    )

    error_message = "The frontend bucket must use the configured name and deterministic suffix."
  }

  assert {
    condition     = aws_s3_bucket.frontend.force_destroy
    error_message = "The development frontend bucket must support controlled teardown."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.frontend.block_public_acls &&
      aws_s3_bucket_public_access_block.frontend.block_public_policy &&
      aws_s3_bucket_public_access_block.frontend.ignore_public_acls &&
      aws_s3_bucket_public_access_block.frontend.restrict_public_buckets
    )

    error_message = "Every frontend S3 public-access protection must be enabled."
  }

  assert {
    condition = (
      one(
        aws_s3_bucket_versioning.frontend.versioning_configuration
      ).status == "Enabled"
    )

    error_message = "Frontend bucket versioning must be enabled."
  }

  assert {
    condition = (
      one(
        one(
          aws_s3_bucket_server_side_encryption_configuration.frontend.rule
        ).apply_server_side_encryption_by_default
      ).sse_algorithm == "AES256"
    )

    error_message = "Frontend objects must use S3 encryption."
  }

  assert {
    condition     = length(aws_s3_object.frontend) == 3
    error_message = "The three required frontend assets must be uploaded."
  }

  assert {
    condition = (
      aws_cloudfront_origin_access_control.frontend.signing_behavior ==
      "always"
    )

    error_message = "CloudFront must always sign private S3 requests."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.enabled
    error_message = "The CloudFront distribution must be enabled."
  }

  assert {
    condition = (
      one(
        aws_cloudfront_distribution.this.default_cache_behavior
      ).target_origin_id == "frontend-s3"
    )

    error_message = "The default CloudFront behavior must use the frontend S3 origin."
  }

  assert {
    condition = (
      one(
        aws_cloudfront_distribution.this.ordered_cache_behavior
      ).target_origin_id == "application-alb"
    )

    error_message = "The API CloudFront behavior must use the Application Load Balancer origin."
  }

  assert {
    condition = (
      one(
        aws_cloudfront_distribution.this.default_cache_behavior
      ).viewer_protocol_policy == "redirect-to-https"
    )

    error_message = "Frontend HTTP requests must redirect to HTTPS."
  }

  assert {
    condition = (
      one(
        aws_cloudfront_distribution.this.ordered_cache_behavior
      ).path_pattern == "/api/*"
    )

    error_message = "CloudFront must route /api/* requests to the ALB."
  }

  assert {
    condition     = aws_wafv2_web_acl.cloudfront.scope == "CLOUDFRONT"
    error_message = "The WAF web ACL must use CloudFront scope."
  }

  assert {
    condition     = length(aws_wafv2_web_acl.cloudfront.rule) == 4
    error_message = "WAF must include rate limiting and three managed rule groups."
  }

  assert {
    condition = (
      output.application_url ==
      "https://d123example.cloudfront.net"
    )

    error_message = "Without a custom domain, the application URL must use the CloudFront hostname."
  }
}