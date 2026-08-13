terraform {
  required_version = ">= 1.15"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.59"
      configuration_aliases = [aws.ram]
    }
  }
}


provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "ram"
  region = "us-east-1"
}
module "cloudwan" {
  source = "./legacy-cloudwan"

  providers = {
    aws     = aws
    aws.ram = aws.ram
  }
}
