output "s3_secrets" {
  value = {
    bucket = aws_s3_object.secrets.bucket
    key    = aws_s3_object.secrets.key
  }
}