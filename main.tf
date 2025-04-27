provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "sunaga"
  }
}

resource "aws_subnet" "example_subnet" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "sunaga"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0026c67be1fe89c76"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.example_subnet.id

  tags = {
    Name = "sunaga-example"
  }
}
