output "s3_secrets" {
  value = {
    bucket = try(aws_s3_object.secrets[0].bucket, "")
    key    = try(aws_s3_object.secrets[0].key, "")
  }
}
