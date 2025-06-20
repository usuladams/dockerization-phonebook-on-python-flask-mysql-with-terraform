locals {
  github_token = data.aws_ssm_parameter.github_token.value
}

variable "files" {
  default = [
    "docker-doc/app/phonebook-app.py", 
    "docker-doc/requirements.txt", 
    "docker-doc/Dockerfile",
    #"docker-doc/.env",
    "docker-doc/docker-compose.yml", 
    "docker-doc/app/templates/index.html",
    "docker-doc/app/templates/delete.html",
    "docker-doc/app/templates/add-update.html"
  ]
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "tag" {
  type = string
  default = "Docker-Phonebook"
}

variable "instance_tag" {
  type = string
}

variable "git-user-name" {
    type = string   
}

variable "docker-instance-ports" {
  type = list(number)
  description = "docker-instance-sec-gr-inbound-rules"
  default = [22, 80, 8080]
}