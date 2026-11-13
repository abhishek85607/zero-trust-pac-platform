terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    kms = "http://localhost:4566"
    iam = "http://localhost:4566"
  }
}

resource "aws_kms_key" "zt_data_key" {
  description             = "Zero-Trust KMS key for S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "zt_audit_logs" {
  bucket = "zero-trust-audit-logs-2026"
}

resource "aws_s3_bucket_public_access_block" "zt_public_block" {
  bucket                  = aws_s3_bucket.zt_audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "zt_s3_encryption" {
  bucket = aws_s3_bucket.zt_audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.zt_data_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_iam_role" "zt_app_role" {
  name = "zero-trust-s3-reader-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "zt_least_privilege_policy" {
  name = "zt-s3-read-only"
  role = aws_iam_role.zt_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.zt_audit_logs.arn,
        "${aws_s3_bucket.zt_audit_logs.arn}/*"
      ]
    }]
  })
}

output "kms_key_arn" {
  value = aws_kms_key.zt_data_key.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.zt_audit_logs.bucket
}

output "iam_role_arn" {
  value = aws_iam_role.zt_app_role.arn
}
