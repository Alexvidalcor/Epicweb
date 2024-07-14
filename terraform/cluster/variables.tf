variable "accessKey" { 
        description = "Access key to AWS console"
}

variable "secretKey" {  
        description = "Secret key to AWS console"
}

variable "ec2Key" {
        description = "Key to enter in you Ec2 instances"
        default = "putavalidkeyname" 
}
variable "workerNumber" {
        description = "Number of worker instances to be join on cluster."
        default = 2
}

variable "region" {
        description = "The region zone on AWS"
        type        = string
}

variable "amiId" {
        description = "The AMI to use"
        default = "ami-07a73a89333ac3eff" # Amazon Linux 2023 ARMx64
}

variable "instanceType" {
        default = "t4g.medium"
}


# -------------------------------------
# ---------- EXTRA VARS
# -------------------------------------

variable "s3Name" {
  description = "S3 bucket name"
  type        = string
}

variable "sgName" {
  description = "S3 bucket name"
  type        = string
}


# -------------------------------------
# ---------- TAGS
# -------------------------------------

variable "vpcTags" {
  description = "VPC tags to use"
  type        = map(string)
}

variable "subnetTags" {
  description = "Subnet tags to use"
  type        = map(string)
}

variable "igwTags" {
  description = "Internet gateway tags to use"
  type        = map(string)
}

variable "publicRtTags" {
  description = "Internet gateway tags to use"
  type        = map(string)
}

variable "ec2MasterTags" {
  description = "Tags to use for the EC2 master instance"
  type        = map(string)
}

variable "ec2WorkerTags" {
  description = "Tags to use for the EC2 worker instances"
  type        = map(string)
}

variable "s3Tags" {
  description = "S3 bucket tags to use"
  type        = map(string)
}

variable "ssmTags" {
  description = "Ssm tags to use"
  type        = map(string)
}