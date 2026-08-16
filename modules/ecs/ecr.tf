resource "aws_ecr_repository" "application" {
  name                 = lower(var.name)
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = var.ecr_kms_key_arn == null ? "AES256" : "KMS"
    kms_key         = var.ecr_kms_key_arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-application"
    }
  )
}

resource "aws_ecr_lifecycle_policy" "application" {
  repository = aws_ecr_repository.application.name

  policy = jsonencode(
    {
      rules = [
        {
          rulePriority = 1
          description  = "Remove untagged images after one day"
          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = 1
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 2
          description  = "Retain the 20 most recent tagged images"
          selection = {
            tagStatus = "tagged"
            tagPrefixList = [
              "sha-",
              "release-",
            ]
            countType   = "imageCountMoreThan"
            countNumber = 20
          }
          action = {
            type = "expire"
          }
        },
      ]
    }
  )
}