terraform {
  backend "s3" {
    region         = "me-south-1"
    bucket         = "devops-bootcamp-remote-state-bryan"
    key            = "bryan/labs/terraform.tfstate"
    dynamodb_table = "devops-bootcamp-locks-bryan"
    encrypt        = true
  }
}
