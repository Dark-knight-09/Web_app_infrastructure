locals {
  aws_region     = "us-east-1"
  aws_access_key = "<AWS_ACCESS_KEY>"
  aws_secret_key = "<AWS_secret_Key>"
}

variable "Tomcat_server" {
  description = "Tomcat server"
  default     = "Tomcat_server"
}



variable "bastition_server" {
  description = "bastion server"
  default     = "bastion server"
}

data "aws_ami" "tomcat_server_image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.20241010.0-kernel-6.1-x86_64"]
  }
}

output "aws_ami_image" {
  value = data.aws_ami.tomcat_server_image.name

}

output "bastion_server_ip" {
  value = aws_instance.bastion_server.public_ip
}


output "alb_ip_address" {
  value = aws_lb.server_load_balancer.dns_name
}


