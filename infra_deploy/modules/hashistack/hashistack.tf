variable "name" {
}

variable "region" {
}

variable "ami" {
}

variable "server_instance_type" {
}

variable "client_instance_type" {
}

variable "key_name" {
}

variable "server_count" {
}

variable "client_count" {
}

variable "nomad_binary" {
}

variable "root_block_device_size" {
}

variable "whitelist_ip" {
}

variable "deploy_rds" {
  type = bool
  default = true
}

data "aws_availability_zones" "available" {}

variable "retry_join" {
  type = map(string)

  default = {
    provider  = "aws"
    tag_key   = "ConsulAutoJoin"
    tag_value = "auto-join"
  }
}

# data "aws_vpc" "default" {
#   default = true
# }

resource "aws_vpc" "nomadconsul" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "nomadconsul" {
  count = 3

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.nomadconsul.id
  map_public_ip_on_launch = true  
}

resource "aws_internet_gateway" "nomadconsul" {
  vpc_id = aws_vpc.nomadconsul.id
}

resource "aws_route_table" "nomadconsul" {
  vpc_id = aws_vpc.nomadconsul.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nomadconsul.id
  }
}

resource "aws_route_table_association" "demo" {
  count = 3

  subnet_id      = aws_subnet.nomadconsul.*.id[count.index]
  route_table_id = aws_route_table.nomadconsul.id
}

resource "aws_db_instance" "my_rds" {
  count = (var.deploy_rds == true ? 1 : 0)
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "nomadconsuldemo"
  username             = "admin"
  password             = "dbAcce$$123"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.my_rds[0].name
  vpc_security_group_ids = [aws_security_group.primary.id]
  skip_final_snapshot = true
}

resource "aws_db_subnet_group" "my_rds" {
  count = (var.deploy_rds == true ? 1 : 0)
  name       = "nomadconsuldemo"
  subnet_ids = [aws_subnet.nomadconsul[0].id, aws_subnet.nomadconsul[1].id]
}

data "aws_network_interface" "rds" {
  count = (var.deploy_rds == true ? 1 : 0)
  filter {
    name   = "subnet-id"
    values = [aws_subnet.nomadconsul[0].id, aws_subnet.nomadconsul[1].id]
  }
  filter {
    name   = "description"
    values = ["RDSNetworkInterface"]

  }
  depends_on = [aws_db_instance.my_rds]
}

resource "aws_security_group" "server_lb" {
  name   = "${var.name}-server-lb"
  vpc_id = aws_vpc.nomadconsul.id

  # Nomad
  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # Consul
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # App ingress
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "primary" {
  name   = var.name
  vpc_id = aws_vpc.nomadconsul.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  ingress {
    from_port   = 9002
    to_port     = 9002
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
    security_groups = [aws_security_group.server_lb.id]
  }

  ingress {
    from_port   = 8300
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip, "10.2.0.0/16"]
  }

  ingress {
    from_port   = 8300
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = [var.whitelist_ip, "10.2.0.0/16"]
  }

  # Nomad
  ingress {
    from_port       = 4646
    to_port         = 4646
    protocol        = "tcp"
    cidr_blocks     = [var.whitelist_ip]
    security_groups = [aws_security_group.server_lb.id]
  }

  # Fabio 
  ingress {
    from_port   = 9998
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # Consul
  ingress {
    from_port       = 8500
    to_port         = 8500
    protocol        = "tcp"
    cidr_blocks     = [var.whitelist_ip]
    security_groups = [aws_security_group.server_lb.id]
  }

  # HDFS NameNode UI
  ingress {
    from_port   = 50070
    to_port     = 50070
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # HDFS DataNode UI
  ingress {
    from_port   = 50075
    to_port     = 50075
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # Spark history server UI
  ingress {
    from_port   = 18080
    to_port     = 18080
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  # Jupyter
  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = [var.whitelist_ip]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "user_data_server" {
  template = file("${path.root}/user-data-server.sh")

  vars = {
    server_count = var.server_count
    region       = var.region
    retry_join = chomp(
      join(
        " ",
        formatlist("%s=%s", keys(var.retry_join), values(var.retry_join)),
      ),
    )
    nomad_binary = var.nomad_binary
  }
}

data "template_file" "user_data_client" {
  template = file("${path.root}/user-data-client.sh")

  vars = {
    region = var.region
    retry_join = chomp(
      join(
        " ",
        formatlist("%s=%s ", keys(var.retry_join), values(var.retry_join)),
      ),
    )
    nomad_binary = var.nomad_binary
  }
}

resource "aws_placement_group" "server" {
  name     = "server-group"
  strategy = "spread"
}

resource "aws_autoscaling_group" "server" {
  name = "nomad-server"
  max_size = 5
  min_size = 1
  desired_capacity = var.server_count
  force_delete = true
  placement_group = aws_placement_group.server.id
  launch_configuration = aws_launch_configuration.server.name
  vpc_zone_identifier = [aws_subnet.nomadconsul[0].id]
  target_group_arns = [aws_lb_target_group.nomadtarget.arn, aws_lb_target_group.consultarget.arn, aws_lb_target_group.apptarget.arn]
  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_configuration"]
  }
  tag {
      key = var.retry_join.tag_key
      value = var.retry_join.tag_value
      propagate_at_launch = true
    }
  lifecycle {
    create_before_destroy = true
  }
  
}

resource "aws_launch_configuration" "server" {
  name_prefix          = "server2"
  image_id      = var.ami
  instance_type = var.server_instance_type
  security_groups = [aws_security_group.primary.id]
  user_data            = data.template_file.user_data_server.rendered
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  key_name               = var.key_name
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }
  # lifecycle {
  #   create_before_destroy = true
  # }
}



resource "aws_placement_group" "client" {
  name     = "client-group"
  strategy = "spread"
}

resource "aws_autoscaling_group" "client" {
  name = "nomad-client"
  max_size = 5
  min_size = 1
  desired_capacity = var.client_count
  force_delete = true
  placement_group = aws_placement_group.client.id
  launch_configuration = aws_launch_configuration.client.name
  vpc_zone_identifier = [aws_subnet.nomadconsul[0].id, aws_subnet.nomadconsul[1].id, aws_subnet.nomadconsul[2].id]
  target_group_arns = [aws_lb_target_group.nomadtarget.arn, aws_lb_target_group.consultarget.arn, aws_lb_target_group.apptarget.arn]
  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_configuration"]
  }
  tag {
      key = var.retry_join.tag_key
      value = var.retry_join.tag_value
      propagate_at_launch = true
    }
  lifecycle {
    create_before_destroy = true
  }
  
}

resource "aws_launch_configuration" "client" {
  name_prefix          = "client"
  image_id      = var.ami
  instance_type = var.client_instance_type
  security_groups = [aws_security_group.primary.id]
  user_data            = data.template_file.user_data_client.rendered
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  key_name               = var.key_name
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }
  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }
  # lifecycle {
  #   create_before_destroy = true
  # }
}



resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = var.name
  role        = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = var.name
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "auto_discover_cluster" {
  name   = "auto-discover-cluster"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.auto_discover_cluster.json
}

data "aws_iam_policy_document" "auto_discover_cluster" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
    ]

    resources = ["*"]
  }
}

# resource "aws_elb" "server_lb" {
#   name               = "${var.name}-server-lb"
#   subnets            = [aws_subnet.nomadconsul[0].id]
#   internal           = false
#   instances          = aws_instance.server.*.id
#   listener {
#     instance_port     = 4646
#     instance_protocol = "tcp"
#     lb_port           = 4646
#     lb_protocol       = "tcp"
#   }
#   listener {
#     instance_port     = 8500
#     instance_protocol = "http"
#     lb_port           = 8500
#     lb_protocol       = "http"
#   }
#   security_groups = [aws_security_group.server_lb.id]
# }

resource "aws_lb" "alb" {
  internal = false
  security_groups = [aws_security_group.server_lb.id]
  subnets            = [aws_subnet.nomadconsul[0].id, aws_subnet.nomadconsul[1].id, aws_subnet.nomadconsul[2].id]

}

resource "aws_lb_listener" "nomadlistener" {
  load_balancer_arn = aws_lb.alb.arn
  port = "4646"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nomadtarget.arn
  }
}

resource "aws_lb_listener" "consullistener" {
  load_balancer_arn = aws_lb.alb.arn
  port = "8500"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.consultarget.arn
  }
}

resource "aws_lb_listener" "applistener" {
  load_balancer_arn = aws_lb.alb.arn
  port = "5000"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.apptarget.arn
  }
}

resource "aws_lb_target_group" "nomadtarget" {
  target_type = "instance"
  port = 4646
  protocol = "HTTP"
  vpc_id = aws_vpc.nomadconsul.id
  health_check {
    port = 4646
    protocol = "HTTP"
    path = "/v1/agent/health"
    interval = 10
  }

}

resource "aws_lb_target_group" "consultarget" {
  target_type = "instance"
  port = 8500
  protocol = "HTTP"
  vpc_id = aws_vpc.nomadconsul.id
  health_check {
    port = 8500
    protocol = "HTTP"
    path = "/v1/status/leader"
    interval = 10
  }
}

resource "aws_lb_target_group" "apptarget" {
  target_type = "instance"
  port = 5000
  protocol = "HTTP"
  vpc_id = aws_vpc.nomadconsul.id
  health_check {
    port = 5000
    protocol = "HTTP"
    path = "/"
    interval = 10
  }

}


output "server_public_ips" {
   value = ["aws_instance.server[*].public_ip"]
}

output "client_public_ips" {
   value = ["aws_instance.client[*].public_ip"]
}

output "server_lb_ip" {
  value = aws_lb.alb.dns_name
}

output "RDS_IP" {
  value = var.deploy_rds == true ? data.aws_network_interface.rds[0].private_ip : "Not Deployed"
}
