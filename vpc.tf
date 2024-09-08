# Create a VPC
resource "aws_vpc" "lab-vpc" {
  cidr_block = "10.0.0.0/16"
  # instance_tenancy = "default"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "lab-vpc"
  }
 
}

# Create web-public, app, db subnet

resource "aws_subnet" "public-subnet-a" {
  vpc_id = aws_vpc.lab-vpc.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "public-subnet-a"
  }
  
}



resource "aws_subnet" "app-subnet-a" {
  vpc_id = aws_vpc.lab-vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "app-subnet-a"
  }
  
}

resource "aws_subnet" "app-subnet-b" {
  vpc_id = aws_vpc.lab-vpc.id
  cidr_block = "10.0.20.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "app-subnet-b"
  }
  
}

resource "aws_subnet" "db-subnet-a" {
  vpc_id = aws_vpc.lab-vpc.id
  cidr_block = "10.0.3.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "db-subnet-a"
  }
  
}


resource "aws_subnet" "db-subnet-b" {
  vpc_id = aws_vpc.lab-vpc.id
  cidr_block = "10.0.30.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "db-subnet-b"
  }
  
}

#########################################
# Create IGW

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab-vpc.id

  tags = {
    Name = "igw"
  }
}

# Create Route Table for web-public-subnet

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.lab-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

   tags = {
    Name = "public-rt"
  }
}

# associate RT-web-public
# Route table은 여러 서브넷에서 동시에 사용할 수 있다. rt에 연결해주는 작업이 Association 이다.

resource "aws_route_table_association" "rt-association-web-public-a" {
  subnet_id      = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.public-rt.id
}

# resource "aws_route_table_association" "rt-association-web-public-b" {
#   subnet_id      = aws_subnet.public-subnet-b.id
#   route_table_id = aws_route_table.public-rt.id
# }


# # Create Route Table for public-subnet-b
# resource "aws_route_table" "public-rt-b" {
#   vpc_id = aws_vpc.lab-vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.IGW.id
#   }

#    tags = {
#     Name = "public-rt-b"
#   }
# }

# Create EIP

resource "aws_eip" "lab-eip" {
  domain = "vpc"
}

# Create NAT Gateway -> 오류난 버전

# resource "aws_nat_gateway" "lab-nat-gw" {
#   allocation_id = aws_eip.lab-eip.id
#   subnet_id     = "lab-public-subnet.id"
# }

# Create NAT Gateway -> 챗지피티가 바꿔준 버전
resource "aws_nat_gateway" "lab-nat-gw" {
  allocation_id = aws_eip.lab-eip.id
  subnet_id     = aws_subnet.public-subnet-a.id

  tags = {
    Name = "lab-nat-gw"
  }
}

# Create Route Table for private(app)
resource "aws_route_table" "lab-app-rt" {
  vpc_id = aws_vpc.lab-vpc.id

  #  route {
  #   cidr_block = "0.0.0.0/0"
  #   nat_gateway_id = aws_nat_gateway.lab-nat-gw.id
  # }

   tags = {
    Name = "lab-app-rt-a"
  }
}



# associate app-rt - nat gateway
resource "aws_route" "lab-nat-gw-app" {
  route_table_id              = aws_route_table.lab-app-rt.id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.lab-nat-gw.id
}

# associate app-rt - app-subnet-a(private)
resource "aws_route_table_association" "rt-association-app-a" {
  subnet_id      = aws_subnet.app-subnet-a.id
  route_table_id = aws_route_table.lab-app-rt.id
}

# associate app-rt - app-subnet-b(private)
resource "aws_route_table_association" "rt-association-app-b" {
  subnet_id      = aws_subnet.app-subnet-b.id
  route_table_id = aws_route_table.lab-app-rt.id
}


# Create Route Table for private(db)

resource "aws_route_table" "lab-db-rt" {
  vpc_id = aws_vpc.lab-vpc.id
  
  #IGW나 NAT-GW 연결해줄때 여기에 적어도 되고,  association으로 연결시켜줘도 된다.
  #  route {
  #   cidr_block = "0.0.0.0/0"
  #   nat_gateway_id = aws_nat_gateway.lab-nat-gw.id
  # }
 
   tags = {
    Name = "lab-db-rt"
  }
}


# resource "aws_route_table" "lab-db-rt-b" {
#   vpc_id = aws_vpc.lab-vpc.id
  
#   #IGW나 NAT-GW 연결해줄때 여기에 적어도 되고,  association으로 연결시켜줘도 된다.
#   #  route {
#   #   cidr_block = "0.0.0.0/0"
#   #   nat_gateway_id = aws_nat_gateway.lab-nat-gw.id
#   # }
  
#    tags = {
#     Name = "lab-db-rt-b"
#   }
# }

# db서버에도 nat-gateway필요한가?? -> 일단 잘 모르겠음
# associate db-rt - nat gateway
resource "aws_route" "lab-nat-gw-db" {
  route_table_id              = aws_route_table.lab-db-rt.id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.lab-nat-gw.id
}
# associate DB-rt - db-subnet-a(private)
resource "aws_route_table_association" "lab-db-rt-a" {
  subnet_id      = aws_subnet.db-subnet-a.id
  route_table_id = aws_route_table.lab-db-rt.id
}

# associate DB-rt - db-subnet-b(private)
resource "aws_route_table_association" "lab-db-rt-b" {
  subnet_id      = aws_subnet.db-subnet-b.id
  route_table_id = aws_route_table.lab-db-rt.id
}






# resource "aws_route" "lab-nat-gw" {
#   route_table_id              = aws_route_table.lab-db-rt.id
#   destination_cidr_block      = "0.0.0.0/0"
#   nat_gateway_id              = aws_nat_gateway.lab-nat-gw.id
# }