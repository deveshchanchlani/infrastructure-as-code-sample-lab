variable "private_key_path" {
  description = "path to private key to inject into the instances to allow ssh"
  default     = "./ssh/id_rsa"
}

variable "public_key_path" {
  description = "path to public key to inject into the instances to allow ssh"
  default     = "./ssh/id_rsa.pub"
}

variable "key_name" {
  description = "master key for the lab"
  default     = "lab-key"
}

variable "name" {
  description = "A name to be applied to make everything unique and personal"
}

variable "aws_region" {
  description = "Bahrain"
  default     = "me-south-1"
}

# Ubuntu Server 18.04 LTS 
variable "aws_amis" {
  description = "What to put on the servers!"
  default = {
    me-south-1 = "ami-051274f257aba97f9"
  }
}
