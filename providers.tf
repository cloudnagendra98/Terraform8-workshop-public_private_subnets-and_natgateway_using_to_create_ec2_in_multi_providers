terraform {
  required_providers {
    aws = {
      version = ">= 5.54.1"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.8.4"
}

provider "aws" {
  region = "us-west-1"

}

provider "aws" {
  alias  = "west"
  region = "us-west-2"

}


