output "nodes" {
  value = aws_instance.lab_nodes.*.public_ip
}

output "vol-id" {
  value = aws_ebs_volume.data-vol.id
}

output "device-name" {
  value = aws_volume_attachment.first-vol.device_name
}

output "cidr-block" {
  value = aws_vpc.lab.cidr_block
}

output "subnet-id" {
  value = aws_subnet.lab_subnet.*.id
}

output "ingress-rules" {
  value = aws_security_group.allow-traffic.ingress
}

output "elb-dns" {
  value = aws_elb.lab_elb_web.dns_name
}