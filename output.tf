output "wafp-part1-vpc-id" {
  value       = "${aws_vpc.wafp1-vpc.id}"
  description = "The id ot the wafp vpc"
}
/*
output "bastion_public_ip" {
  value = "http://${aws_instance.bastion.public_ip}"
}

output "bastion_public_dns" {
  value = "http://${aws_instance.bastion.public_dns}"
}
*/

output "webserver1_private_ip" {
  value = "http://${aws_instance.webserver1.private_ip}"
}

output "webserver2_private_ip" {
  value = "http://${aws_instance.webserver2.private_ip}"
}

output "bastion_eip_public_ip" {
  value = "http://${aws_eip.wafp1-eip-bastion.public_ip}"
}

output "bastion_eip_public_dns" {
  value = "http://${aws_eip.wafp1-eip-bastion.public_dns}"
}

output "bastion_ssh_web" {
  value = "https://console.aws.amazon.com/ec2/v2/connect/ec2-user/${aws_instance.bastion.id}"
}

output "ToDoList_WebApp_DNS_name" {
  value = "http://${aws_lb.wafp1-alb.dns_name}/"
  }
