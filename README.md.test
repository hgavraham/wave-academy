# Final Project

1. Create **VPC *(vpc-)***
    * IPv4 CIDR: 10.0.0.0/16
    * tags: <br> 
        * Name: fp-p1-vpc <br>
        * Location: us-east-1
    * click *create*
    * after creation click on the *Action* in the rghit side ane enable the:<br>
      DNS hostnames<br>
      DNS resolution
    
> NOTE: when you create a ***vpc*** a **security group** *(sg-)*, **route table** *(rtb-)* and **DHCP Options Sets** *(dopt)* will create automatically.<br>
NOTE: you need to create un **internet gateway** *(igw-)* and configure a **route table** the the **igw-** *(internet gateway)*) 

2. Create **Internet Gateway *(igw-)***
    * tags:
        * Name: fp-p1-igw
    * after the *igw* created, select the *igw* and attached him to the VPC<br>
3. Configure **route table** the the **internet gateway**
    1. go to *route table* tab
    2. select the route table was create by default with the vpc<br>
     select *Route* tab in the bottom panel<br>
     click *Edit routes*<br>
     click *Add route*<br>
     destenatio *0.0.0.0/0* --> target *igw-(id)*
4. Create 3 **Subnet *(subnet-)***
    #### public subnet - 1
    1. vpc (by tag name): fp-p1-vpc
    2. tags: <br> 
        * Name: fp-p1-pubsub-1 <br>
        * Location: us-east-1
    3. AZ: us-east-1a
    4. subnet: 10.0.1.0/24
    #### private subnet - 1
    1. vpc (by tag name): fp-p1-vpc
    2. tags: <br> 
        * Name: fp-p1-prisub-1 <br>
        * Location: us-east-1
    3. AZ: us-east-1a
    4. subnet: 10.0.2.0/24
    #### private subnet - 2
    1. vpc (by tag name): fp-p1-vpc
    2. tags: <br> 
        * Name: fp-p1-prisub-2 <br>
        * Location: us-east-1
    3. AZ: us-east-1b
    4. subnet: 10.0.3.0/24

5. Create EC2 instances
    #### bastion instance
    1. AMI: ami-02e136e904f3da870 (amazon linux | (64-bit x86))
    2. type: t2.micro
    3. vpc (by tag name): fp-p1-vpc
    4. subnet (by name): fp-p1-pubsub-1
    5. Auto-assign Public IP: 
    6. storage: 8GB
    7. storage: Delete on Termination: yes
    8. tags: <br> 
        * Name: fp-p1-bastion <br>
        * Location: us-east-1
    9. 
    






[md file baseline](https://guides.github.com/features/mastering-markdown/)