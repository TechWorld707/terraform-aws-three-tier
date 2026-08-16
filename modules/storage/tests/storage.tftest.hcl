mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"DenyInsecureTransport\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:*\",\"Resource\":\"*\"}]}"
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

variables {
  name        = "test-platform-dev"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"

  force_destroy      = false
  versioning_enabled = true

  object_expiration_days                 = 90
  noncurrent_version_expiration_days     = 30
  abort_incomplete_multipart_upload_days = 7

  tags = {
    Environment = "test"
  }
}

run "application_storage_plan" {
  command = plan

  assert {
    condition = (
      aws_s3_bucket.submissions.bucket ==
      "test-platform-dev-submissions-a1b2c3d4"
    )

    error_message = "The bucket name must contain the application name and deterministic suffix."
  }

  assert {
    condition     = aws_s3_bucket.submissions.force_destroy == false
    error_message = "The bucket must not allow forced deletion by default."
  }

  assert {
    condition = (
      one(
        aws_s3_bucket_ownership_controls.submissions.rule
      ).object_ownership == "BucketOwnerEnforced"
    )

    error_message = "S3 ACLs must be disabled using BucketOwnerEnforced ownership."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.submissions.block_public_acls &&
      aws_s3_bucket_public_access_block.submissions.block_public_policy &&
      aws_s3_bucket_public_access_block.submissions.ignore_public_acls &&
      aws_s3_bucket_public_access_block.submissions.restrict_public_buckets
    )

    error_message = "Every S3 public-access protection must be enabled."
  }

  assert {
    condition = (
      one(
        aws_s3_bucket_versioning.submissions.versioning_configuration
      ).status == "Enabled"
    )

    error_message = "Submission bucket versioning must be enabled."
  }

  assert {
    condition = (
      one(
        one(
          aws_s3_bucket_server_side_encryption_configuration.submissions.rule
        ).apply_server_side_encryption_by_default
      ).sse_algorithm == "aws:kms"
    )

    error_message = "Submission objects must use KMS encryption."
  }

  assert {
    condition = (
      one(
        one(
          aws_s3_bucket_server_side_encryption_configuration.submissions.rule
        ).apply_server_side_encryption_by_default
      ).kms_master_key_id == var.kms_key_arn
    )

    error_message = "The configured application KMS key must encrypt submission objects."
  }

  assert {
    condition = (
      one(
        aws_s3_bucket_server_side_encryption_configuration.submissions.rule
      ).bucket_key_enabled
    )

    error_message = "S3 Bucket Keys must be enabled."
  }

  assert {
    condition = (
      one(
        one(
          aws_s3_bucket_lifecycle_configuration.submissions.rule
        ).expiration
      ).days == 90
    )

    error_message = "Submission objects must use the configured expiration period."
  }

  assert {
    condition = (
      one(
        one(
          aws_s3_bucket_lifecycle_configuration.submissions.rule
        ).noncurrent_version_expiration
      ).noncurrent_days == 30
    )

    error_message = "Noncurrent object versions must expire after the configured period."
  }

  assert {
    condition = (
      one(
        one(
          aws_s3_bucket_lifecycle_configuration.submissions.rule
        ).abort_incomplete_multipart_upload
      ).days_after_initiation == 7
    )

    error_message = "Incomplete multipart uploads must be removed."
  }
}