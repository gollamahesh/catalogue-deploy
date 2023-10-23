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

variable "env" {
  default = "dev"
}

variable "app_version" {
  default = "1.0.0"
  
}