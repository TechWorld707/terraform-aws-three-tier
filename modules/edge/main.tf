locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "edge"
    }
  )

  frontend_bucket_name = (
    "${var.name}-frontend-${random_id.bucket_suffix.hex}"
  )

  frontend_files = {
    for filename, content_type in {
      "index.html" = "text/html; charset=utf-8"
      "app.js"     = "application/javascript; charset=utf-8"
      "style.css"  = "text/css; charset=utf-8"
    } :
    filename => content_type
    if fileexists("${var.frontend_source_directory}/${filename}")
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4

  keepers = {
    name = var.name
  }
}