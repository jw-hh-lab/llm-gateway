terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "llm-tollgate-tfstate-c3b2ea"
    key          = "dev/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "ap-northeast-2"
  default_tags { tags = { Project = "llm-tollgate", Env = "dev", ManagedBy = "terraform" } }
}
