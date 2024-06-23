resource "aws_instance" "k8s_ec2-master" {
    ami = var.amiId
    subnet_id = aws_subnet.k8s_vpc-publicsubnet.id
    instance_type = var.instanceType
    key_name = var.ec2Key
    associate_public_ip_address = true
    security_groups = [ aws_security_group.k8s_vpc-sg.id ]
    root_block_device {
    volume_type = "gp3"
    volume_size = "8"
    delete_on_termination = true
    }

    tags = var.ec2MasterTags
    
    user_data_base64 = base64encode("${templatefile("scripts/install_k8s_msr.sh", {

    access_key = var.accessKey
    private_key = var.secretKey
    region = var.region
    s3buckit_name = "k8s-${random_string.k8s_s3-randomname.result}"
    })}")

    depends_on = [
    aws_s3_bucket.k8s_s3-bucket,
    random_string.k8s_s3-randomname
  ]

    
} 




resource "aws_instance" "k8s_ec2-worker" {
    ami = var.amiId
    count = var.workerNumber
    subnet_id = aws_subnet.k8s_vpc-publicsubnet.id
    instance_type = var.instanceType
    key_name = var.ec2Key
    associate_public_ip_address = true
    security_groups = [ aws_security_group.k8s_vpc-sg.id ]
    root_block_device {
    volume_type = "gp3"
    volume_size = "8"
    delete_on_termination = true
    }

    tags = var.ec2WorkerTags

    user_data_base64 = base64encode("${templatefile("scripts/install_k8s_wrk.sh", {

    access_key = var.accessKey
    private_key = var.secretKey
    region = var.region
    s3buckit_name = "k8s-${random_string.k8s_s3-randomname.result}"
    worker_number = "${count.index + 1}"

    })}")
  
    depends_on = [
      aws_s3_bucket.k8s_s3-bucket,
      random_string.k8s_s3-randomname,
      aws_instance.ec2_instance_msr
  ]
}