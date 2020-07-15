output "webservers" {
  value = aws_instance.webserver.*.public_ip
}
output "databases" {
  value = aws_instance.database.*.public_ip
}
output "elb_dns_name" {
  value = aws_lb.ELB.dns_name
}
