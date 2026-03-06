// VPC
resource "aws_vpc" "CI-CD_VPC" {
  cidr_block = var.cidr_block
  tags = {
    Name = "CI-CD_VPC"
  }
}

// Subnet
resource "aws_subnet" "CI-CD_Subnet" {
  vpc_id = aws_vpc.CI-CD_VPC.id
  cidr_block = var.cidr_block_subnet

  tags = {
    Name = "CI-CD_Subnet"
  }
}

//IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.CI-CD_VPC.id

  tags = {
    Name = "main"
  }
}

// Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.CI-CD_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "rt"
  }
}

// Route Table Association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.CI-CD_Subnet.id
  route_table_id = aws_route_table.rt.id
}

// Security Group
resource "aws_security_group" "CI-CD_SG" {
  description = "Allow CI-CD traffic"
  vpc_id      = aws_vpc.CI-CD_VPC.id

  ingress {
    description      = "Allow jenkins"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow sonarqube"
    from_port        = 9000
    to_port          = 9000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow Argocd Port"
    from_port        = 8050
    to_port          = 8050
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow our application Port"
    from_port        = 8060
    to_port          = 8060
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow our prometheus Port"
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow our grafana Port"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CI-CD_SG"
  }
}

// EC2
resource "aws_instance" "example" {
  ami = var.ami_value
  key_name = var.key_file
  subnet_id = aws_subnet.CI-CD_Subnet.id
  vpc_security_group_ids = [aws_security_group.CI-CD_SG.id]
  instance_type = var.type
  associate_public_ip_address = true

    root_block_device {
        volume_type  = "gp3"
        volume_size  = 90        
        tags = {
        Name = "my-root-volume"
        }
    }

  tags = {
    Name = "CI-CD"
  }
}