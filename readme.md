# KH Labs - Infrastructure as Code
## Hashicorp Terraform used to provision AWS infrastructure

This lab uses terraform to provision a 2-layered architecture, with 2 worker nodes and 1 or more controlplane nodes. It also provisions a bastion node for ssh access to the other nodes. This is an HA configuration, so we use 2 availability zones for the workers and controlplanes. This results in 5 subnets and 3 security groups. The workers are in an autoscaling group with an elb distributing work to them.


