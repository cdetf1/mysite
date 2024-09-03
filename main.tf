
#Application Load Balancer

resource "aws_lb" "lab-alb" {
    name     = "lab-alb"
    internal = false # alb 외부에 생성 = 외부 인터넷과 연결가능해야함
    load_balancer_type = "application"
    subnets = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]
    security_groups = [aws_security_group.lab-alb-sg.id]
    tags = {
        Name = "lab-alb"
    }
}

# Target-group

resource "aws_lb_target_group" "lab-tg" {
  name     = "lab-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab-vpc.id

  health_check {
    enabled = true
    healthy_threshold = 2 # 건강상태 확인을 위해 최소 성공 횟수 2회
    interval = 5
    matcher  = 200
    path     = "/health-check" # health-check 경로
    port     = "traffic-port" # health-check 체크에 사용할 포트를 alb가 타겟 그룹에 전하는 트래픽 포트와 동일한 값으로 설정
    protocol = "HTTP"
    timeout  = 2
    unhealthy_threshold = 2 # 비정상 상태 파단 -> 연속 실패횟수 2회
  }

   tags = {
    Name = "lab-tg"
  }
}



# ALB listener
resource "aws_lb_listener" "lab-listener" {
    load_balancer_arn = aws_lb.lab-alb.arn
  # ↑ 리스너가 연결될 로드 밸런서의 ARN(Amazon Resource Name)을 앞서 만든 ALB로 지정해주기
    port = 80
    protocol = "HTTP"

    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab-tg.arn
  }

    # default_action {
    #   type = "fixed-response"
      
    # fixed_response {
      
    #   # 리스너 규칙과 일치하지 않는 요청에 대해 기본 응답으로 404페이지를 보내도록 구성
    #   content_type = "text/plain"
    #   message_body = "404: page not found"
    #   status_code = 404 
      
    #   }
    # }

     tags = {
    Name = "lab-listener"
  }
}

# ALB - security group
resource "aws_security_group" "lab-alb-sg" {
    name = "lab-alb-sg"
    description = "allow all traffic to 80 port"
    vpc_id = aws_vpc.lab-vpc.id # vpc 선언 안해주면, 디폴트로 되는듯 -> 오류발생

    #인바운드 http 트래픽 허용
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
   #모든 아웃바운드 트래픽 허용
   egress {
    from_port = 0
    to_port = 0
    protocol = "-1" # -1 은 모든 프로토콜을 허용한단 의미
    cidr_blocks = ["0.0.0.0/0"]
   }

    tags = {
    Name = "lab-sg-alb"
  }
}



# ami id를 통해 my-ami 가져오기
data "aws_ami" "lab-template" {
  most_recent = true
  owners = ["self"] # 소유자가 자신인 AMI를 필터링

  filter {
    name   = "image-id" 
    values = ["ami-07ce36d4d160d8597"] # lab-terraform-ami
  }

   tags = {
    Name = "lab-ami"
  }
}

# parameter store 사용하기 위한 절차
# 1.IAM 역할(Role) 생성

resource "aws_iam_role" "lab_ec2_role" {
  name = "lab-ec2_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      },
      # 06/23 추가
      {
        Effect = "Allow",
        Principal = {
          Service = "ssm.amazonaws.com" 
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# # 2.IAM 정책(Policy) 생성
# resource "aws_iam_policy" "lab_ssm_policy" {
#   name        = "lab_ssm_readonly_policy"
#   description = "Read-only access to SSM Parameter Store"
#   policy      = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "ssm:GetParameter",
#           "ssm:GetParameters",
#           "ssm:GetParametersByPath"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# IAM 정책(Policy) 생성 (SSM Full Access) 6/23추가
resource "aws_iam_policy" "lab_ssm_policy" {
  name        = "lab_ssm_full_access_policy"
  description = "Full access to AWS Systems Manager"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "ssm:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "ec2messages:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "logs:CreateLogGroup",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
      # 필요한 다른 권한들 추가
    ]
  })
}

# 3. 역할에 정책 부착
resource "aws_iam_role_policy_attachment" "lab_attach_ssm_policy" {
  role       = aws_iam_role.lab_ec2_role.name
  policy_arn = aws_iam_policy.lab_ssm_policy.arn
}

# 4. IAM 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "lab_ec2_profile" {
  name = "lab_ec2_instance_profile"
  role = aws_iam_role.lab_ec2_role.name
}

# Launch Template
resource "aws_launch_template" "lab-template" {
  name = "lab-template"  
  image_id = data.aws_ami.lab-template.id  # 위에서 만든 ami 데이터 소스 참조
  instance_type = "t2.micro"
  key_name = aws_key_pair.hk_keypair.key_name

  network_interfaces {
    associate_public_ip_address = false # 프라이빗 서브넷에 autoscaling-group 배치함. public ip 생성안함
    security_groups = [aws_security_group.lab-appserver-sg.id]
  }
  
  # 5. parameter store 사용 위해 추가되는 부분
  iam_instance_profile {
    name = aws_iam_instance_profile.lab_ec2_profile.name
  }  


  # 리소스 교체 시 원래는 삭제->생성을 하게된다.
  # 아래 설정을 통해, 교체 리소스를 먼저 생성하고, 기존 리소스를 오류 없이 삭제할 수 있음.
  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
	  tags = {
      Name = "lab-template"
   }
 }
}


# Auto Scaling Group
resource "aws_autoscaling_group" "lab-asg" {
  name = "lab-asg"
  min_size = 1
  max_size = 2
  desired_capacity = 1
  health_check_grace_period = 60 # health-check 시간 60초
  health_check_type         = "EC2"
  vpc_zone_identifier = [aws_subnet.app-subnet-a.id, aws_subnet.app-subnet-b.id]
  launch_template {
   id = aws_launch_template.lab-template.id
   version = "$Latest" 
   }
  
  tag {
    key = "Name"
    value = "lab-asg-server"
    propagate_at_launch = true 
   }
 }

# Auto-scaling Group + ALB 연결
resource "aws_autoscaling_attachment" "lab-asg-alb" { # 오토 스케일링 그룹 생성
  autoscaling_group_name = aws_autoscaling_group.lab-asg.id # ALB와 연결할 오토스케일링 그룹의 이름 지정
  lb_target_group_arn = aws_lb_target_group.lab-tg.arn # 로드 밸런서 대상 그룹의 ARN 지정
    
}



# RDS SG
resource "aws_security_group" "lab-rds-sg" {
  name = "lab-rds-sg"
  description = "allow access to RDS"
  vpc_id = aws_vpc.lab-vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/16",]
    # ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

}


# RDS DB subnet - group

resource "aws_db_subnet_group" "lab-db-subnet-group"{
  name = "lab-db-subnet-group"
  subnet_ids = [aws_subnet.db-subnet-a.id, aws_subnet.db-subnet-b.id]
}
 

resource "aws_db_instance" "lab-rds" {
  allocated_storage    = 20
  db_name              = "lab_rds"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "11111111"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.lab-db-subnet-group.id
  vpc_security_group_ids = [aws_security_group.lab-rds-sg.id]
  skip_final_snapshot  = true # RDS 인스턴스를 삭제할 때 최종 백업용 스냅샷을 스킵할까요? -> yes
  multi_az             = true # 다중az 사용하려면 db인스턴스가 db.t3.micro 이상이어야함
  publicly_accessible  = false # 외부 접근 x ,ec2가 rds에 접근할 수 있게 해준다.

  tags = {
    Name = "lab-rds"
  }
}
 