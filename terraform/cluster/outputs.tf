output "instance_msr_public_ip" {
  description = "Public address IP of master"
  value       = aws_instance.k8s_ec2-master.public_ip
}

output "instance_wrks_public_ip" {
  description = "Public address IP of worker"
  value       = aws_instance.k8s_ec2-worker.*.public_ip
}

output "instance_msr_privte_ip" {
  description = "Private IP address of master"
  value       = aws_instance.k8s_ec2-master.private_ip
}

output "s3_bucket_name" {
  description = "The S3 bucket name"
  value       = "k8s-${random_string.k8s_s3-bucket.result}"
}