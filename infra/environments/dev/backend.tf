terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "cloud-native-app-tfstate-88450bab" # 👈 YOUR bucket
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud-native-app-tflock"
    encrypt        = true
  }
}   