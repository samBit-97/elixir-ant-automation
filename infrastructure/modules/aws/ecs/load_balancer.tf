# Application Load Balancer for Go API
resource "aws_lb" "go_api" {
  name               = "${var.cluster_name}-go-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.cluster_name}-go-api-alb"
    Environment = var.environment
    Purpose     = "Load balancer for Go API"
  }
}

# Target Group for Go API
resource "aws_lb_target_group" "go_api" {
  name        = "${var.cluster_name}-go-api-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  tags = {
    Name        = "${var.cluster_name}-go-api-tg"
    Environment = var.environment
  }
}

# ALB Listener for Go API
resource "aws_lb_listener" "go_api" {
  load_balancer_arn = aws_lb.go_api.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.go_api.arn
  }

  tags = {
    Name        = "${var.cluster_name}-go-api-listener"
    Environment = var.environment
  }
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name        = "${var.cluster_name}-alb-sg"
    Environment = var.environment
  }
}

# Update Fargate security group to allow ALB traffic
resource "aws_security_group_rule" "fargate_alb_ingress" {
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.fargate.id
  description              = "Allow ALB to access Go API"
}