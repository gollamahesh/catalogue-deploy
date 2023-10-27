module "catalogue_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.devops_ami.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  subnet_id = element(split(",",data.aws_ssm_parameter.private_subnet_ids.value),0)
#   user_data = file("catalogue.sh")
  tags = merge( 
    {
        Name = "catalogue-dev-ami"
    },
    var.tags)
} 

#null resource to connect to the catalogue instance
resource "null_resource" "cluster" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = module.catalogue_instance.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    type = "ssh"
    user = "centos"
    password = "DevOps321"
    host = module.catalogue_instance.private_ip
  }

  # copy file

  provisioner "file" {
    source = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
    
  }

  provisioner "remote-exec" {
    # Bootstrap sc ript called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/catalogue.sh",
      "sudo sh /tmp/catalogue.sh ${var.app_version}"
    ] 
  }
}

#stop instance to take ami
resource "aws_ec2_instance_state" "catalogue_instance" {
  instance_id = module.catalogue_instance.id
  state = "stopped"
}

#taking an ami
resource "aws_ami_from_instance" "catalogue_ami" {
  name = "${var.tags.Component}-${local.current_time}"
  source_instance_id = module.catalogue_instance.id
}

# terminating the resource
resource "null_resource" "terminating" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    ami_id = aws_ami_from_instance.catalogue_ami.id
  }
  
  provisioner "local-exec" {
    command = "aws ec2 terminate-instance --instance-ids ${module.catalogue_instance.id}"
  }
}


# catalogue target group
resource "aws_lb_target_group" "catalogue" {
  name     = "${var.project_name}-${var.tags.Component}-${var.Environment}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  deregistration_delay = 60
  health_check {
    enabled = true
    healthy_threshold = 2 # consider as healthy if 2 health checks are success
    interval = 15
    matcher = "200-299"
    path = "/health"
    port = 8080
    protocol = "HTTP"
    timeout = 5
    unhealthy_threshold = 3 # consider as un-healthy if 3 un-health checks are failure
  }
}

# catalogue launch template
resource "aws_launch_template" "catalogue" {
  name = "${var.project_name}-${var.tags.Component}-${var.Environment}"

  # here ami id is different
  image_id = aws_ami_from_instance.catalogue_ami.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t2.micro"

  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "catalogue"
    }
  }
  # We dont need it here because we already configured completely
  # user_data = filebase64("${path.module}/catalogue.sh")
}

# 3. creating autoscaling 

resource "aws_autoscaling_group" "catalogue" {
  name                      = "${var.project_name}-${var.tags.Component}-${var.Environment}"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  target_group_arns = [aws_lb_target_group.catalogue.arn]
  launch_template {
    id = aws_launch_template.catalogue.id
    version = "$Latest"
  }

  vpc_zone_identifier       = split(",",data.aws_ssm_parameter.private_subnet_ids.value)


  tag {
    key                 = "Name"
    value               = "catalogue"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 4. creating autoscaling policy

resource "aws_autoscaling_policy" "catalogue" {
  # ... other configuration ...
  autoscaling_group_name = aws_autoscaling_group.catalogue.name
  name                   = "cpu"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}

# 5. creatinf auto scaling listener rule

resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }

  condition {
    host_header {
      # for dev instances, it should be app-dev and for prod it should be app-prod
      values = ["${var.tag.Component}.app-${var.Environment}.${var.domain_name}"]
    }
  }
}
