terraform {
  backend "s3" {
    region         = "me-south-1"
    bucket         = "devops-bootcamp-remote-state"
    key            = "global/s3/terraform.tfstate"
    dynamodb_table = "devops-bootcamp-locks"
    encrypt        = true
  }
}
