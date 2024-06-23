# To avoid same s3 bucket names
resource "random_string" "k8s_s3-randomname" {
  length = 9
  special = false
  upper = false
  lower = true
}

# Create a S3 ACL (Access Control List)
resource "aws_s3_bucket_acl" "k8s_s3-acl" {
  bucket = aws_s3_bucket.s3buckit.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

# Create a S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "k8s_s3-aclownership" {
  bucket = aws_s3_bucket.s3buckit.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

# Create a S3 bucket
resource "aws_s3_bucket" "k8s_s3-bucket" {
  bucket = "k8s-${random_string.s3name.result}"
  force_destroy = true
 depends_on = [
    random_string.s3name
  ]
}