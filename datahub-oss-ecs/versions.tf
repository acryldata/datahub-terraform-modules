terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.0"
    }
  }

  # This reference deployment uses the local backend by default so it runs out of the box.
  # For any real environment, configure a remote backend (S3) instead,
  # so state is shared and locked across whoever runs `terraform apply`. Example:
  #
  # backend "s3" {
  #   bucket         = "<your-terraform-state-bucket>"
  #   key            = "datahub-ecs/terraform.tfstate"
  #   region         = "<your-region>"
  # }
}
