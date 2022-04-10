        # AWS Provider
    provider "aws" {
        region = "us-east-1"
    }    
    
    resource "aws_vpc" "Proyecto" {
        cidr_block = "10.0.0.0/16"
    
        tags = {
          "Name" = "Proyecto"
        }      
    }
    
    
    
    resource "aws_internet_gateway" "Internet" {
        vpc_id = aws_vpc.Proyecto.id  
    }
    
    
    
    resource "aws_subnet" "Public_Subnet_1" {
    
        vpc_id = aws_vpc.Proyecto.id
        cidr_block = "10.0.1.0/24"
        availability_zone = "us-east-1a"
    
        tags = {
          "Name" = "Public_Subnet_1"
        }  
    }
    
    
    resource "aws_subnet" "Public_Subnet_2" {
    
        vpc_id = aws_vpc.Proyecto.id
        cidr_block = "10.0.2.0/24"
        availability_zone = "us-east-1b"
    
        tags = {
          "Name" = "Public_Subnet_2"
        }  
    }
    
    
    
    
    resource "aws_subnet" "Private_Subnet_1" {
        vpc_id = aws_vpc.Proyecto.id
        cidr_block = "10.0.3.0/24"
        availability_zone = "us-east-1a"
    
        tags = {
          "Name" = "SUBNET-PRIVATE"
        }
      
    }
    
    resource "aws_subnet" "Private_Subnet_2" {
        vpc_id = aws_vpc.Proyecto.id
        cidr_block = "10.0.4.0/24"
        availability_zone = "us-east-1b"
    
        tags = {
          "Name" = "SUBNET-PRIVATE"
        }
      
    }
    
    
    
    resource "aws_route_table" "proute_1" {
        vpc_id = aws_vpc.Proyecto.id
    
        route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.Internet.id
        }
    
        tags = {
          "Name" = "proute_1"
        }
      
    }
    
    resource "aws_route_table_association" "passociation" {
        subnet_id = aws_subnet.Public_Subnet_1.id
        route_table_id = aws_route_table.proute_1.id  
    }
    
    
    
    resource "aws_route_table" "proute_2" {
        vpc_id = aws_vpc.Proyecto.id
    
        route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.Internet.id
        }
    
        tags = {
          "Name" = "proute_2"
        }  
    }
    
    resource "aws_route_table_association" "passociation_2" {
        subnet_id = aws_subnet.Public_Subnet_2.id
        route_table_id = aws_route_table.proute_2.id  
    }
    
    
    
    
    
    resource "aws_eip" "Nat_GW" {
        vpc = true
    
        tags = {
            Name = "Nat_GW"
        }  
    }
    
    resource "aws_nat_gateway" "NAT" {
        allocation_id = aws_eip.Nat_GW.id
        subnet_id = aws_subnet.Public_Subnet_1.id
    
        tags = {
          "Name" = "NAT"
        }
    }
    
    
    
    resource "aws_route_table" "prroute_1" {
          vpc_id = aws_vpc.Proyecto.id
    
          route {
              cidr_block = "0.0.0.0/0"
              nat_gateway_id = aws_nat_gateway.NAT.id
          }
    
          tags = {
            "Name" = "ROUTES-PRIVATE"
          }
    }
    
    
    resource "aws_route_table_association" "pvassociation" {
        subnet_id = aws_subnet.Private_Subnet_1.id
        route_table_id = aws_route_table.prroute_1.id  
    }
    
    resource "aws_route_table" "prroute_2" {
        vpc_id = aws_vpc.Proyecto.id
    
        route {
          cidr_block = "0.0.0.0/0"
          nat_gateway_id = aws_nat_gateway.NAT.id
        }
        
        tags = {
          "Name" = "ROUTES-PRIVATE-B"
        }  
    }
    
    resource "aws_route_table_association" "pvassociation_2" {
        subnet_id = aws_subnet.Private_Subnet_2.id
        route_table_id = aws_route_table.prroute_1.id  
    }
    
    
    
    resource "aws_security_group" "WP" {
        name = "Allow_Traffic"
        description = "Allow_Traffic"
        vpc_id = aws_vpc.Proyecto.id
    
        ingress {
            description = "HTTP"
            from_port = 80
            to_port = 80
            cidr_blocks = ["0.0.0.0/0"]
            protocol = "tcp"
        }
    
        ingress {
            description = "SSH"
            from_port = 22
            to_port = 22
            cidr_blocks = ["0.0.0.0/0"]
            protocol = "tcp"
        }
    
        ingress {
          from_port = 8
          to_port = 0
          protocol = "icmp"
          cidr_blocks = ["0.0.0.0/0"]
         
        }
    
        egress {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    
        tags = {
          "Name" = "WP"
        }
    }
    
    
    
    resource "aws_network_interface" "Bastion" {
        subnet_id = aws_subnet.Public_Subnet_1.id
        private_ips = ["10.0.1.10"]
        security_groups = [aws_security_group.WP.id]  
    }
    
    
    resource "aws_network_interface" "WP_1" {
        subnet_id = aws_subnet.Private_Subnet_1.id
        private_ips = ["10.0.3.10"]
        security_groups = [aws_security_group.WP.id]   
    }
    
    resource "aws_network_interface" "WP_2" {
        subnet_id = aws_subnet.Private_Subnet_2.id
        private_ips = ["10.0.4.10"]
        security_groups = [aws_security_group.WP.id]   
    }
    
    
    
    
    
    resource "aws_eip" "elastic" {
        vpc = true
        network_interface = aws_network_interface.Bastion.id
        associate_with_private_ip = "10.0.1.10"
        depends_on = [
          aws_internet_gateway.Internet
        ]  
    }
    
    
    
    
   
    
    
    resource "aws_instance" "BASTION" {
        ami = "ami-0c02fb55956c7d316"
        instance_type = "t2.micro"
        availability_zone = "us-east-1a"
        key_name = "tf"
    
        network_interface {
          device_index = 0
          network_interface_id = aws_network_interface.Bastion.id
        }
    
        tags = {
          "Name" = "BASTION"
        }
         
    }
    
    
    resource "aws_instance" "WP_1" {
        ami = "ami-052a50faa2f4d8840"
        instance_type = "t2.micro"
        availability_zone = "us-east-1a"
        
    
        network_interface {
          device_index = 0
          network_interface_id = aws_network_interface.WP_1.id
        }
    
         user_data = <<-EOF
                #!/bin/bash            
                sudo systemctl enable httpd
                sudo systemctl enable mariadb
                sudo systemctl start mariadb
                sudo systemctl start httpd
                EOF
    
        tags = {
          "Name" = "WP_1"
        }     
    }
    
    resource "aws_instance" "WP_2" {
        ami = "ami-052a50faa2f4d8840"
        instance_type = "t2.micro"
        availability_zone = "us-east-1b"
       
    
        network_interface {
          device_index = 0
          network_interface_id = aws_network_interface.WP_2.id
        }
    
        user_data = <<-EOF
                #!/bin/bash            
                sudo systemctl enable httpd
                sudo systemctl start httpd
                EOF
    
    
        tags = {
          "Name" = "WP_2"
        }
         
    }
    
    
    resource "aws_security_group" "Sg_LB" {
        name = "SG_LB"
        vpc_id = aws_vpc.Proyecto.id
    
        ingress {
            description = "HTTP"
            from_port = 80
            to_port = 80
            cidr_blocks = ["0.0.0.0/0"]
            protocol = "tcp"
        }
    
        egress {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    
        tags = {
          "Name" = "Sg_LB"
        }
    }
    
    
    
    
    
    resource "aws_lb" "LB" {
      name = "LB"
      internal = false
      ip_address_type = "ipv4"
      load_balancer_type = "application"
      subnets = [aws_subnet.Public_Subnet_1.id, aws_subnet.Public_Subnet_2.id]
    
      security_groups = [aws_security_group.Sg_LB.id]
    
      tags = {
        "Name" = "LB"
      }
      
    }
    
    
    resource "aws_lb_target_group" "TG_LB" {
      name = "Target1"
      port = 80
      protocol = "HTTP"
      vpc_id = aws_vpc.Proyecto.id
      
      # stickiness {
      #   type = "lb_cookie"
      # }
    
      health_check {
        path = "/"
        protocol = "HTTP"
        interval = 10    
      }  
    }
    
    resource "aws_lb_listener" "Listerner_WP" {
      load_balancer_arn = aws_lb.LB.arn
      port = "80" 
      protocol = "HTTP"
    
      default_action {
        target_group_arn = aws_lb_target_group.TG_LB.arn
        type = "forward"
      }  
    }
    
    resource "aws_lb_target_group" "TG_C" {
      name = "Target2"
      port = 80
      protocol = "HTTP"
      vpc_id = aws_vpc.Proyecto.id  
    }
    
    
    
    
    resource "aws_lb_target_group_attachment" "ATTACH-TARGET-GROUP-A" {
      count = 2
      target_group_arn = aws_lb_target_group.TG_LB.arn
      target_id = aws_instance.WP_2.id
    
    } 
    resource "aws_lb_target_group_attachment" "ATTACH-TARGET-GROUP-B" {
      count = 2
      target_group_arn = aws_lb_target_group.TG_LB.arn
      target_id = aws_instance.WP_1.id  
    }
