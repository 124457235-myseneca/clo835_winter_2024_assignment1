terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
}
resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"
}



resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}



######################### Security Groups #######################
resource "aws_security_group" "aws_sg" {
  name = "security group for the ec2 instance"

  ingress {
    description = "SSH from the anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "8081 from the internet"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "8082 from the internet"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "8083 from the internet"
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "aws_lb_sg" {
  name = "security group for the alb"

  ingress {
    description = "HTTP from the anywhere"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
#####################Key Pari #######################

resource "aws_key_pair" "assignment1" {
  key_name   = "clo835app"
  public_key = file("clo835app.pub")
}
#################Instance #######################

resource "aws_instance" "aws_ins_web" {

  ami                         = "ami-0277155c3f0ab2930"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.aws_sg.id]
  associate_public_ip_address = true
  key_name                    = "clo835app"
  subnet_id                   = aws_default_subnet.default_az1.id
  user_data                   = file("config.sh")
  tags = {
    Name = "WebApp"
  }

}


################## Load Balancer #####################

resource "aws_lb" "webapp-alb" {
  name               = "webapp-alb"
  internal           = false
  security_groups    = [aws_security_group.aws_lb_sg.id]
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
  subnets            = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  tags = {
    Name = "my-webapp-alb"
  }
}


resource "aws_lb_target_group" "lb-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "webapp-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_default_vpc.default.id
}

resource "aws_lb_listener" "webapp_lb_listener" {

  load_balancer_arn = aws_lb.webapp-alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-target-group.arn
  }
}


resource "aws_lb_target_group_attachment" "alb-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.lb-target-group.arn
  target_id        = aws_instance.aws_ins_web.id
  port             = 8081
}

resource "aws_lb_target_group_attachment" "alb-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.lb-target-group.arn
  target_id        = aws_instance.aws_ins_web.id
  port             = 8082
}

resource "aws_lb_target_group_attachment" "alb-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.lb-target-group.arn
  target_id        = aws_instance.aws_ins_web.id
  port             = 8083
}

#################### ECR ###########################

resource "aws_ecr_repository" "ecr_assignment1" {

  name                 = "ecr_assignment1"
  image_tag_mutability = "MUTABLE"
  encryption_configuration {
    encryption_type = "AES256"
  }
  image_scanning_configuration {
    scan_on_push = true
  }
}