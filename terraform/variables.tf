variable "project_name" {
  type = string
  default = "roboshop"
}

variable "tags" {
    default = {
        Project = "Roboshop"
        Component ="catalogue"
        Environment = "DEV"
        Terraform = "true"

    }
  
}

variable "Environment" {
  default = "dev"
}

variable "app_version" {
  default = "1.0.0"
  
}

variable "domain_name" {
  default = "maheshgolla.online"
}