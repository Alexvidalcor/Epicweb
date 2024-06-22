variable "accessKey" { 
        description = "Access key to AWS console"
}

variable "secretKey" {  
        description = "Secret key to AWS console"
}

variable "ec2Key" {
        description = "Key to enter in you Ec2 instances"
        default = "mykey" 
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
        default = "ami-0a6b2839d44d781b2" #Ubuntu 20.04
}

variable "instanceType" {
        default = "t3.medium"
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