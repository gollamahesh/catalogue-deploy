terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }

  backend "s3" {
    bucket = "mahesh-roboshop-remote-state"
    key = "catalogue-dev"
    region = "us-east-1"
    dynamodb_table = "roboshop-lock-file"
  } 
}

# Configure the AWS Provider

provider "aws" {

  region = "us-east-1"
   
}