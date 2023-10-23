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
    # Bootstrap script called with private_ip of each node in the cluster
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