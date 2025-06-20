terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }

    github = {
      source = "integrations/github"
      version = "6.6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "baby"
}


provider "github" {
  token = local.github_token
}