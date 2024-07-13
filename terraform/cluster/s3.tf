# To avoid same s3 bucket names
resource "random_string" "k8s_s3-randomname" {
  length = 9
  special = false
  upper = false
  lower = true
}

# Create a S3 bucket
resource "aws_s3_bucket" "k8s_s3-bucket" {
  bucket = "k8s-${random_string.k8s_s3-randomname.result}"
  force_destroy = true
  tags = var.s3Tags
 depends_on = [
    random_string.k8s_s3-randomname
  ]
}

# Create a S3 ACL (Access Control List)
resource "aws_s3_bucket_acl" "k8s_s3-acl" {
  bucket = aws_s3_bucket.k8s_s3-bucket.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.k8s_s3-aclownership]
}

# Create a S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "k8s_s3-aclownership" {
  bucket = aws_s3_bucket.k8s_s3-bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}