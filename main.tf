provider "aws" {
  region = "${var.AWS_REGION}"
  //access_key = "${ACCESS_KEY}"
  //secret_key = "${SECRET_KEY}"
}
#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=->
//vpc
resource "aws_vpc" "wafp1-vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_support   = "true"
    enable_dns_hostnames = "true" 
    enable_classiclink   = "false"
    instance_tenancy     = "default"    
    
    tags = {
        Name     = "wafp1-vpc"
        Location = "${var.AWS_REGION}"
        Environment = "${var.ENVIRONMENT}"
    }
}
#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=->
//public subnet1
resource "aws_subnet" "wafp1-pubsub-1" {
    vpc_id                  = "${aws_vpc.wafp1-vpc.id}"
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = "true" // false for private
    availability_zone = "${var.AWS_REGION}a"
    tags = {
        Name = "wafp1-pubsub-1"
        Location = "${var.AWS_REGION}"
        Environment = "${var.ENVIRONMENT}"
    }
}

//public subnet2
resource "aws_subnet" "wafp1-pubsub-2" {
    vpc_id                  = "${aws_vpc.wafp1-vpc.id}"
    cidr_block              = "10.0.4.0/24"
    map_public_ip_on_launch = "true" // false for private
    availability_zone = "${var.AWS_REGION}b"
    tags = {
        Name = "wafp1-pubsub-2"
        Location = "${var.AWS_REGION}"
        Environment = "${var.ENVIRONMENT}"
    }
}

//private subnet1
resource "aws_subnet" "wafp1-prisub-1" {
    vpc_id                  = "${aws_vpc.wafp1-vpc.id}"
    cidr_block              = "10.0.2.0/24"
    map_public_ip_on_launch = "false" //true for public
    availability_zone = "${local.WEBSERVER1_AZ}"
    tags = {
        Name = "wafp1-prisub-1"
        Location = "${var.AWS_REGION}"
        Environment = "${var.ENVIRONMENT}"
    }
}

//private subnet2
resource "aws_subnet" "wafp1-prisub-2" {
    vpc_id                  = "${aws_vpc.wafp1-vpc.id}"
    cidr_block              = "10.0.3.0/24"
    map_public_ip_on_launch = "false" //true for public
    availability_zone = "${local.WEBSERVER2_AZ}"
    tags = {
        Name = "wafp1-prisub-2"
        Location = "${var.AWS_REGION}"
        Environment = "${var.ENVIRONMENT}"
    }
}
//according to artical on aws
//https://aws.amazon.com/premiumsupport/knowledge-center/public-load-balancer-private-ec2/
//To attach Amazon EC2 instances located in a private subnet,
//create public subnets in the same Availability Zones as the private subnets used by the backend instances.
//Then, associate the public subnets with your load balancer.

#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=->
//Create Internet Gateway
resource "aws_internet_gateway" "wafp1-igw" {
  vpc_id = "${aws_vpc.wafp1-vpc.id}"
  tags = {
    Name = "wafp1-igw"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
}

//Create Custom Route Table
resource "aws_route_table" "wafp1-crt-dflt-to-intrnt" {
  vpc_id = "${aws_vpc.wafp1-vpc.id}"
  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = "${aws_internet_gateway.wafp1-igw.id}"
  }

  tags = {
    Name = "wafp1-crt-dflt-to-intrnt"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
}

//Associate CRT and Subnet
resource "aws_route_table_association" "wafp1-crt-dflt-to-intrnt-pubsub-1" {
  subnet_id      = "${aws_subnet.wafp1-pubsub-1.id}"
  route_table_id = "${aws_route_table.wafp1-crt-dflt-to-intrnt.id}"
}
resource "aws_route_table_association" "wafp1-crt-dflt-to-intrnt-pubsub-2" {
  subnet_id      = "${aws_subnet.wafp1-pubsub-2.id}"
  route_table_id = "${aws_route_table.wafp1-crt-dflt-to-intrnt.id}"
}
#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=->

//Create a Security Group
resource "aws_security_group" "wafp1-ssh-allow" {
  vpc_id = "${aws_vpc.wafp1-vpc.id}"
//--egress
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

//--ingress
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    // This means, all ip address are allowed to ssh !
    // Do not do it in the production.
    // Put your office or home address in it!
    cidr_blocks = ["0.0.0.0/0"]
    description= "Allow SSH"
  }

  tags = {
    Name = "wafp1-ssh-allow"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }

}
#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-> eip for bastion

//optional it's only if you want a static ip...
//don't forget to delet it if it's not alocated to any resource
//it's will coast for you a moany 
resource "aws_eip" "wafp1-eip-bastion" {
  depends_on = [aws_internet_gateway.wafp1-igw]
  instance = "${aws_instance.bastion.id}"
  vpc      = true
  tags = {
    Name = "wafp1-eip-bastion"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
}

//associate ElasticIP to an Instance
resource "aws_eip_association" "wafp1-eip-bastion" {
  instance_id   = "${aws_instance.bastion.id}"
  allocation_id = "${aws_eip.wafp1-eip-bastion.id}"
  depends_on = [ aws_eip.wafp1-eip-bastion ]
}

#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-> cerate private and public key

resource "tls_private_key" "wafp1-p1-tpk" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "wafp1-ssh-key.pem"
}

resource "aws_key_pair" "wafp1-key-pair" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.wafp1-p1-tpk.public_key_openssh
}


//save the pem localy
resource "local_file" "wafp1-pem" { 
  filename        = "${path.module}/wafp1.pem"
  content         = "${tls_private_key.wafp1-p1-tpk.private_key_pem}"
  file_permission = "0600"
}
#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-> bastion instance

//bastion instance
resource "aws_instance" "bastion" {
  ami                    = "${var.AMI}"
  instance_type          = "${var.INSTNC_TYPE}"
  availability_zone      = "${local.ANSIBLE_AZ}"
  subnet_id              = "${aws_subnet.wafp1-pubsub-1.id}"
  vpc_security_group_ids = ["${aws_security_group.wafp1-ssh-allow.id}"]
  //the Public SSH key
  key_name = "${aws_key_pair.wafp1-key-pair.key_name}"
  associate_public_ip_address = false
  //volume
  root_block_device {
    delete_on_termination = true
    //iops attribute not supported for root_block_device with volume_type gp2
    //iops = 100
    volume_size = 8
    volume_type = "gp2"
  }
  tags = {
    Name     = "wafp1-bastion"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }

  //depends_on = [ "${aws_security_group.wafp1-ssh-allow.id}" ]
}

resource "null_resource" "copy-bastion-pem" {
  depends_on = [
    aws_eip_association.wafp1-eip-bastion,
    aws_instance.webserver1,
    aws_instance.webserver2,
    ]

  triggers = {
    build_number = timestamp()
  }

  provisioner "file" {
    content     = "${tls_private_key.wafp1-p1-tpk.private_key_pem}"
    destination = "~/.ssh/wafp1.pem"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${tls_private_key.wafp1-p1-tpk.private_key_pem}"
      host        = "${aws_eip.wafp1-eip-bastion.public_ip}"
    }
  }

  provisioner "file" {
    source      = "./ansible.tar"
    destination = "~/ansible.tar"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${tls_private_key.wafp1-p1-tpk.private_key_pem}"
      host        = "${aws_eip.wafp1-eip-bastion.public_ip}"
    }
  }
}

resource "null_resource" "local-exec" {
  provisioner "local-exec" {
    command = "echo 'export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY' > test.delete ; exho 'export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY >> test.delete"
    interpreter = ["/bin/bash", "-c"]
  }
}


resource "null_resource" "remote-exec" {
  depends_on = [
    null_resource.copy-bastion-pem,
    null_resource.local-exec,
  ]

  provisioner "remote-exec" {
    inline = [
      "chmod 0600 ~/.ssh/wafp1.pem",
      "sudo amazon-linux-extras install ansible2 -y",
      "sudo yum install python3 python3-pip -y",
      "sudo yum install python2-pip -y",
      "pip install boto3",
      "tar -xvf ~/ansible.tar",
      "cd ~/ansible",
      "ansible-playbook -i aws_ec2.yaml playbook/install-todo-webapp.yaml",
      #"sleep 30",
      "sudo yum -y install cowsay",
      "sleep 15",
      "cowsay Finished to install ToDoList WebApp!",
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${tls_private_key.wafp1-p1-tpk.private_key_pem}"
      host        = "${aws_eip.wafp1-eip-bastion.public_ip}"
    }
  }
}


#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-> ngw for private subnet 1

//eip for ngw-az1
resource "aws_eip" "wafp1-eip-ngw-az1" {
  vpc      = true
  tags = {
    Name = "wafp1-eip-ngw-az1"
    Location = "${var.AWS_REGION}"
  }
}

//public ngw-az1 for the private subnet 1
resource "aws_nat_gateway" "wafp1-ngw-az1" {
  allocation_id = "${aws_eip.wafp1-eip-ngw-az1.id}"
  subnet_id     = "${aws_subnet.wafp1-pubsub-1.id}"

  tags = {
    Name = "wafp1-ngw-az1"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
  depends_on = [ aws_eip.wafp1-eip-ngw-az1 ]
}

//Create Custom Route Table for private subnet to ngw1
resource "aws_route_table" "wafp1-crt-dflt-to-intrnt-ngw1" {
  vpc_id = "${aws_vpc.wafp1-vpc.id}"
  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = "${aws_nat_gateway.wafp1-ngw-az1.id}"
  }

  tags = {
    Name = "wafp1-crt-dflt-to-intrnt-ngw1"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
}

//Associate CRT and Subnet
resource "aws_route_table_association" "wafp1-crt-dflt-to-intrnt-prisub-1" {
  subnet_id      = "${aws_subnet.wafp1-prisub-1.id}"
  route_table_id = "${aws_route_table.wafp1-crt-dflt-to-intrnt-ngw1.id}"
}

#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-> ngw for private subnet 2

//eip for ngw-az2
resource "aws_eip" "wafp1-eip-ngw-az2" {
  vpc      = true
  tags = {
    Name = "wafp1-eip-ngw-az2"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
}

//public ngw-az2 for the private subnet 1
resource "aws_nat_gateway" "wafp1-ngw-az2" {
  allocation_id = "${aws_eip.wafp1-eip-ngw-az2.id}"
  subnet_id     = "${aws_subnet.wafp1-pubsub-2.id}"

  tags = {
    Name = "wafp1-ngw-az2"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
  depends_on = [ aws_eip.wafp1-eip-ngw-az2 ]
}

//Create Custom Route Table for private subnet to ngw1
resource "aws_route_table" "wafp1-crt-dflt-to-intrnt-ngw2" {
  vpc_id = "${aws_vpc.wafp1-vpc.id}"
  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = "${aws_nat_gateway.wafp1-ngw-az2.id}"
  }

  tags = {
    Name = "wafp1-crt-dflt-to-intrnt-ngw2"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
}

//Associate CRT and Subnet
resource "aws_route_table_association" "wafp1-crt-dflt-to-intrnt-prisub-2" {
  subnet_id      = "${aws_subnet.wafp1-prisub-2.id}"
  route_table_id = "${aws_route_table.wafp1-crt-dflt-to-intrnt-ngw2.id}"
}



#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-> webserver instances
//webserver security group
resource "aws_security_group" "wafp1-sg-webservers" {
  vpc_id = "${aws_vpc.wafp1-vpc.id}"
//--egress
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
//--ingress
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${aws_subnet.wafp1-pubsub-1.cidr_block}", "${aws_subnet.wafp1-pubsub-2.cidr_block}"]
    description= "Allow SSH from pubsub-1-and-2"
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["${aws_subnet.wafp1-pubsub-1.cidr_block}", "${aws_subnet.wafp1-pubsub-2.cidr_block}"]
    description= "Allow HTTP from pubsub-1-and-2"
  }
  tags = {
    Name = "wafp1-sg-webservers"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
}
#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-> 
//webserver1 instnace
resource "aws_instance" "webserver1" {
  ami           = "${var.AMI}"
  instance_type = "${var.INSTNC_TYPE}"
  availability_zone = "${local.WEBSERVER1_AZ}"
  subnet_id = "${aws_subnet.wafp1-prisub-1.id}"
  vpc_security_group_ids = ["${aws_security_group.wafp1-sg-webservers.id}"]
  key_name = "${aws_key_pair.wafp1-key-pair.key_name}"
  associate_public_ip_address = false
  root_block_device {
    delete_on_termination = true
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name     = "wafp1-webserver1"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
    Role = "webserver"
  }
}

//webserver2 instance
resource "aws_instance" "webserver2" {
  ami           = "${var.AMI}"
  instance_type = "${var.INSTNC_TYPE}"
  availability_zone = "${local.WEBSERVER2_AZ}"
  subnet_id = "${aws_subnet.wafp1-prisub-2.id}"
  vpc_security_group_ids = ["${aws_security_group.wafp1-sg-webservers.id}"]
  key_name = "${aws_key_pair.wafp1-key-pair.key_name}"
  associate_public_ip_address = false
  root_block_device {
    delete_on_termination = true
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name     = "wafp1-webserver2"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
    Role = "webserver"
  }
}

#<-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-> ELB (Elastic load Balancer)
//Target Group

resource "aws_lb_target_group" "wafp1-webapp-tg" {
  name = "wafp1-webapp-tg"
  port = "8080"
  protocol = "HTTP"
  vpc_id = "${aws_vpc.wafp1-vpc.id}"

  health_check {
    path = "/"
    port = "8080"
    healthy_threshold = "5"
    unhealthy_threshold = "2"
    timeout = "5"
    interval = "10"
    matcher = "200"  # has to be HTTP 200 or fails
  }
  
  tags = {
    Name = "wafp1-webapp-tg"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
}

//App Load Balancer (ALB) security greoup (SG)
resource "aws_security_group" "wafp1-alb-sg" {
  vpc_id = "${aws_vpc.wafp1-vpc.id}"
//--egress
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

//--ingress
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description= "Allow HTTP from internet"
  }

  tags = {
    Name = "wafp1-alb-sg"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }

}


//App Load Balancer (ALB)

resource "aws_lb" "wafp1-alb" {
  name               = "wafp1-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.wafp1-alb-sg.id}"]
  subnets            = ["${aws_subnet.wafp1-pubsub-1.id}", "${aws_subnet.wafp1-pubsub-2.id}"]

  enable_deletion_protection = false

  tags = {
    Name = "wafp1-alb"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}"
  }
}

//load balancer listener
resource "aws_lb_listener" "wafp1-alb-http-listener" {
  load_balancer_arn = "${aws_lb.wafp1-alb.arn}"
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.wafp1-webapp-tg.arn}"
  }

  tags = {
    Name = "wafp1-alb-http-listener"
    Location = "${var.AWS_REGION}"
    Environment = "${var.ENVIRONMENT}" 
  }
}

// aws lb attachment group
resource "aws_lb_target_group_attachment" "wafp1-alb-tg-to-webserver1" {
  target_group_arn = "${aws_lb_target_group.wafp1-webapp-tg.arn}"
  target_id        = "${aws_instance.webserver1.id}"
  port             = 8080
}
resource "aws_lb_target_group_attachment" "wafp1-alb-tg-to-webserver2" {
  target_group_arn = "${aws_lb_target_group.wafp1-webapp-tg.arn}"
  target_id        = "${aws_instance.webserver2.id}"
  port             = 8080
}

//resource "aws_alb_target_group_attachment" "test" {
//  target_group_arn = "${aws_alb_target_group.test.arn}"
//  count            = length("${var.WEB_INSTANCE_LIST}")
//  target_id        = "${var.WEB_INSTANCE_LIST[count.index]}"
//  #target_id        = "${element(var.WEB_INSTANCE_LIST, count.index)}"
//  port             = "80"
//}