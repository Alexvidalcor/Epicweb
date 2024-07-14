resource "aws_ssm_parameter" "k8s_ssm-parameter1" {
  name  = "kubeadm_join_command"
  type  = "SecureString"
  value = "readytobeoverwritten"
  tags = var.ssmTags
}