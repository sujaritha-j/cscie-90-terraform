#Create VPC 
resource "aws_vpc" "vpc_master" {
  cidr_block = "10.0.0.0/16"

  #1 Adds the tags to the VPC - key-value pairs can be utilized for billing, ownership, automation, access control, and many other use cases
  # The below will use the workspace name-pc as the tag name
  tags = {
    Name = "${terraform.workspace}-terra-vpc"
  }

}

#Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  state = "available"
}

#Create subnet # 1 
resource "aws_subnet" "public_subnet" {
  #2 The aws_availability_zones are retrieved frpm the data source with name azs, And element function retrieves the first element from a list
  # The Availability Zones data source allows access to the list of AWS Availability Zones which can be accessed by an AWS account within the region configured in the provider.
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  #3 Setting the VPC_id and cidr black range
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "${terraform.workspace}-terra-subnet"
  }
}

#4 Creating resource for aws_route_table with the name as public_route_table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_master.id

  tags = {
    Name = "${terraform.workspace}-terra-route-table"
  }
}

#5 Creating resource for aws_route with the name as public_internet_gateway
#This resource is used to add the internet gateway to the creating VPC
resource "aws_route" "public_internet_gateway" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

#6 Creating resource for aws_route_table_association with the name as public
# The created subnet, and route table are associated with the VPC
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

#7 Creating a resource for aws_internet_gateway with the name igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_master.id

  tags = {
    Name = "${terraform.workspace}-terra-igw"
  }
}


#Create SG for allowing http from anywhere. TCP/22 inbound should be restricted to your ip or ip range for EC2 Instance Connect

resource "aws_security_group" "sg" {
  name        = "${terraform.workspace}-terra-sg"
  description = "Allow TCP/22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow http traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${terraform.workspace}-terra-securitygroup"
  }
}