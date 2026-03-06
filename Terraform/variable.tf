variable "ami_value" {
  description = "ami for instance"
}

variable "type"{
    description = "Instance type of ec2 instance"
}

variable "key_file" {
  description = "Key pair for the instance"
}

variable "cidr_block_vpc" {
  description = "cidr block for vpc"
}

variable "cidr_block_subnet" {
  description = "cidr block for subnet"
}