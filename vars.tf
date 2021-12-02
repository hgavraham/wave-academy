variable "AWS_REGION" {
  default = "us-east-1"
}

variable "AMI" {
  default = "ami-02e136e904f3da870"
}
variable "INSTNC_TYPE" {
  default = "t2.micro"
}

variable "ENVIRONMENT" {
  default = "wafp1-test"
}

locals {
  ANSIBLE_AZ = "${var.AWS_REGION}a"
  WEBSERVER1_AZ = "${var.AWS_REGION}a"
  WEBSERVER2_AZ = "${var.AWS_REGION}b"
}


//variable "WEB_INSTANCE_LIST" {
//  description = "Push these instances to ALB TG"
//  type = "list"
//  default = ["${aws_instance.webserver1.id}", "${aws_instance.webserver2.id}"]
//}


