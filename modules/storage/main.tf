locals {
  bucket_name = "${var.name}-submissions-${random_id.bucket_suffix.hex}"

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "storage"
    }
  )
}

resource "random_id" "bucket_suffix" {
  byte_length = 4

  keepers = {
    name = var.name
  }
}

resource "aws_s3_bucket" "submissions" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    local.common_tags,
    {
      Name    = local.bucket_name
      Purpose = "Application submission archive"
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "submissions" {
  bucket = aws_s3_bucket.submissions.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "submissions" {
  bucket = aws_s3_bucket.submissions.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "submissions" {
  bucket = aws_s3_bucket.submissions.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "submissions" {
  bucket = aws_s3_bucket.submissions.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "submissions" {
   #checkov:skip=CKV_AWS_300:The configuration below already aborts incomplete multipart uploads using a validated variable; this finding is a static-analysis false positive.
   bucket = aws_s3_bucket.submissions.id

  rule {
    id     = "submission-archive-retention"
    status = "Enabled"

    filter {
      prefix = "submissions/"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }

    dynamic "expiration" {
      for_each = var.object_expiration_days > 0 ? [1] : []

      content {
        days = var.object_expiration_days
      }
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.submissions
  ]
}

data "aws_iam_policy_document" "submissions" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.submissions.arn,
      "${aws_s3_bucket.submissions.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "submissions" {
  bucket = aws_s3_bucket.submissions.id
  policy = data.aws_iam_policy_document.submissions.json

  depends_on = [
    aws_s3_bucket_public_access_block.submissions
  ]
}