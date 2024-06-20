resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  depends_on = [
    aws_vpc.my_vpc
  ]
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"

  depends_on = [
    aws_vpc.my_vpc
  ]

}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "This is security group"
  vpc_id      = aws_vpc.my_vpc.id

  depends_on = [
    aws_vpc.my_vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet
  ]

}

resource "aws_security_group_rule" "open80" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  #cidr_blocks       = [aws_vpc.my_vpc.cidr_block]
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.sg.id

  depends_on = [
    aws_vpc.my_vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_security_group.sg
  ]

}

resource "aws_security_group_rule" "openssh" {
  type      = "ingress"
  from_port = "22"
  to_port   = "22"
  protocol  = "tcp"
  #cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id

  depends_on = [
    aws_vpc.my_vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_security_group.sg
  ]
}

resource "aws_security_group_rule" "outbound" {
  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "-1"
  #cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id

  depends_on = [
    aws_vpc.my_vpc,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_security_group.sg
  ]
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  depends_on = [
    aws_vpc.my_vpc
  ]

}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  depends_on = [
    aws_vpc.my_vpc
  ]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  depends_on = [
    aws_vpc.my_vpc
  ]


}

resource "aws_nat_gateway" "nat-gw" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.public_subnet.id #public subnet send internet to the natgateway then this nat-gateway attached to the private route table
  depends_on = [
    aws_internet_gateway.igw
  ]


}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

  depends_on = [
    aws_vpc.my_vpc,
    aws_route_table.public_route_table,
    aws_internet_gateway.igw
  ]


}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat-gw.id ##here we got internet to the natgway so we attached this natgateway to this private route table so we get internet to access to private subnet by doing private routetable association with private subnet

  depends_on = [
    aws_vpc.my_vpc,
    aws_route_table.public_route_table,
    aws_internet_gateway.igw
  ]

}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id = aws_subnet.public_subnet.id
  #gateway_id     = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.public_route_table.id

  depends_on = [
    aws_vpc.my_vpc,
    aws_subnet.public_subnet,
    aws_route_table.public_route_table,
    aws_internet_gateway.igw
  ]


}

resource "aws_route_table_association" "private_subnet_association" {

  subnet_id = aws_subnet.private_subnet.id
  #gateway_id     = aws_nat_gateway.nat-gw.id
  route_table_id = aws_route_table.private_route_table.id

  depends_on = [
    aws_vpc.my_vpc,
    aws_subnet.public_subnet,
    aws_route_table.private_route_table,
    aws_nat_gateway.nat-gw
  ]

}

resource "aws_key_pair" "ntier" {
    key_name = "ntier"
  public_key =  file(var.public_key_path)

}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-08012c0a9ee8e21c4"
  instance_type = "t2.micro"
  key_name      = "ntier"
  #security_groups             = [aws_security_group.sg.name]
  subnet_id                   = aws_subnet.public_subnet.id #Note: if you use elasticip in script then use private_subnet here other wise use only public_subnet
  associate_public_ip_address = true

  depends_on = [
    aws_security_group.sg,
    aws_subnet.public_subnet
  ]
}


resource "aws_vpc" "my_vpc1" {
  provider   = aws.west
  cidr_block = "10.1.0.0/16"

}

resource "aws_subnet" "public_subnet1" {
  provider                = aws.west
  vpc_id                  = aws_vpc.my_vpc1.id
  cidr_block              = "10.1.0.0/24"
  map_public_ip_on_launch = true

  depends_on = [
    aws_vpc.my_vpc1
  ]
}

resource "aws_subnet" "private_subnet1" {
  provider   = aws.west
  vpc_id     = aws_vpc.my_vpc1.id
  cidr_block = "10.1.1.0/24"

  depends_on = [
    aws_vpc.my_vpc1
  ]

}

resource "aws_security_group" "sg1" {
  provider    = aws.west
  name        = "sg"
  description = "This is security group"
  vpc_id      = aws_vpc.my_vpc1.id

  depends_on = [
    aws_vpc.my_vpc1,
    aws_subnet.public_subnet1,
    aws_subnet.private_subnet1
  ]

}

resource "aws_security_group_rule" "open_80" {
  provider  = aws.west
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  #cidr_blocks       = [aws_vpc.my_vpc.cidr_block]
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.sg1.id

  depends_on = [
    aws_vpc.my_vpc1,
    aws_subnet.public_subnet1,
    aws_subnet.private_subnet1,
    aws_security_group.sg1
  ]

}

resource "aws_security_group_rule" "ssh" {
  provider  = aws.west
  type      = "ingress"
  from_port = "22"
  to_port   = "22"
  protocol  = "tcp"
  #cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg1.id

  depends_on = [
    aws_vpc.my_vpc1,
    aws_subnet.public_subnet1,
    aws_subnet.private_subnet1,
    aws_security_group.sg1
  ]
}

resource "aws_security_group_rule" "outbound1" {
  provider  = aws.west
  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "-1"
  #cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg1.id

  depends_on = [
    aws_vpc.my_vpc1,
    aws_subnet.public_subnet1,
    aws_subnet.private_subnet1,
    aws_security_group.sg1
  ]
}


resource "aws_route_table" "public_route_table1" {
  provider = aws.west
  vpc_id   = aws_vpc.my_vpc1.id

  depends_on = [
    aws_vpc.my_vpc1
  ]

}

resource "aws_route_table" "private_route_table1" {
  provider = aws.west
  vpc_id   = aws_vpc.my_vpc1.id


  depends_on = [
    aws_vpc.my_vpc1
  ]
}

resource "aws_internet_gateway" "igw1" {
  provider = aws.west
  vpc_id   = aws_vpc.my_vpc1.id

  depends_on = [
    aws_vpc.my_vpc1
  ]


}

resource "aws_nat_gateway" "nat-gw1" {
  provider          = aws.west
  connectivity_type = "private"
  subnet_id         = aws_subnet.public_subnet1.id #public subnet send internet to the natgateway then this nat-gateway attached to the private route table

  depends_on = [
    aws_internet_gateway.igw1
  ]


}

resource "aws_route" "public_route1" {
  provider               = aws.west
  route_table_id         = aws_route_table.public_route_table1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw1.id

  depends_on = [
    aws_vpc.my_vpc1,
    aws_route_table.public_route_table1,
    aws_internet_gateway.igw1
  ]


}

resource "aws_route" "private_route1" {
  provider               = aws.west
  route_table_id         = aws_route_table.private_route_table1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat-gw1.id ##here we got internet to the natgway so we attached this natgateway to this private route table so we get internet to access to private subnet by doing private routetable association with private subnet

  depends_on = [
    aws_vpc.my_vpc1,
    aws_route_table.public_route_table1,
    aws_internet_gateway.igw1
  ]

}

resource "aws_route_table_association" "public_subnet_association1" {
  provider  = aws.west
  subnet_id = aws_subnet.public_subnet1.id
  #gateway_id     = aws_internet_gateway.igw1.id
  route_table_id = aws_route_table.public_route_table1.id

  depends_on = [
    aws_vpc.my_vpc1,
    aws_subnet.public_subnet1,
    aws_route_table.public_route_table1,
    #aws_internet_gateway.igw1
  ]


}

resource "aws_route_table_association" "private_subnet_association1" {
  provider  = aws.west
  subnet_id = aws_subnet.private_subnet1.id
  #gateway_id     = aws_nat_gateway.nat-gw1.id
  route_table_id = aws_route_table.private_route_table1.id

  depends_on = [
    aws_vpc.my_vpc1,
    aws_subnet.public_subnet1,
    aws_route_table.private_route_table1,
    # aws_nat_gateway.nat-gw1
  ]

}

resource "aws_key_pair" "ntier1" {
    provider = aws.west
    key_name = "ntier"
  public_key =  file(var.public_key_path)

}
resource "aws_instance" "ec2_instance_new" {
  provider      = aws.west
  ami           = "ami-0cf2b4e024cdb6960"
  instance_type = "t2.micro"
  key_name      = "ntier"
  #security_groups             = [aws_security_group.sg1.name]
  subnet_id                   = aws_subnet.public_subnet1.id #Note: if you use elasticip in script then use private_subnet here other wise use only public_subnet
  associate_public_ip_address = true

  depends_on = [
    aws_security_group.sg1,
    aws_subnet.public_subnet1
  ]
}