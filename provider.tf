terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0"
    }
  }
}

provider "aws" {
  region     = local.aws_region
  profile    = "default"
  access_key = local.aws_access_key
  secret_key = local.aws_secret_key
}
