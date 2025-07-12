provider "aws" {
    region = "eu-west-2"
}

# VPC creation in ew2
resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      name = "my_vpc"
    }
}

# public subnet creation ew2a
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.10.0/24"
    availability_zone = "eu-west-2a"

    tags = {
      name = "public_subnet"
    }
}

# private subnet creation ew2a
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.20.0/24"
    availability_zone = "eu-west-2b"

    tags = {
      name = "private_subnet"
    }
}

# ec2 creation in public subnet
resource "aws_instance" "my-pub-ec2" {
    ami = "ami-0841b1152f02fa85e"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet.id
    associate_public_ip_address = true
    depends_on = [ aws_security_group.sg_pub ]
    vpc_security_group_ids = [aws_security_group.sg_pub.id]
    key_name = "nayana_july_2025"

}

# SG for ec2 in public sub
resource "aws_security_group" "sg_pub" {
    name = "sg_pub"
    vpc_id = aws_vpc.my_vpc.id
    description = "Security group for public subnet"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# IGW creation for vpc
resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
      name = "my_igw"
    }
}

# routing table for public subnet
resource "aws_route_table" "public_rtb" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }

    tags = {
      name = "public_rtb"
    }
}

# associate public_rtb to public subnet
resource "aws_route_table_association" "pbrt" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rtb.id
}

# ec2 creation in private subnet
resource "aws_instance" "my-private-ec2" {
    ami = "ami-0841b1152f02fa85e"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private_subnet.id
    associate_public_ip_address = false
    depends_on = [ aws_security_group.sg_private ]
    vpc_security_group_ids = [aws_security_group.sg_private.id]
    key_name = "nayana_july_2025"

    tags = {
      name = "my-private-ec2"
    }

}

# SG for ec2 in private sub
resource "aws_security_group" "sg_private" {
    name = "sg_private"
    vpc_id = aws_vpc.my_vpc.id
    description = "Security group for private subnet"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# create nat gw to public subnet
resource "aws_nat_gateway" "my-nat-gw" {
    allocation_id = aws_eip.my-eip.id
    subnet_id = aws_subnet.public_subnet.id
    tags = {
      name = "my-nat-gw"
    }
}

# eip for nat gw
resource "aws_eip" "my-eip" {
    domain = "vpc"
    tags = {
      name = "my-eip-pec2"
    }
}

# routing table for private subnet
resource "aws_route_table" "private_rtb" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.my-nat-gw.id
    }

    tags = {
      name = "private_rtb"
    }
}

# associate private_rtb to private subnet
resource "aws_route_table_association" "privatert" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rtb.id
}
