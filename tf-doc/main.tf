data "aws_ssm_parameter" "github_token" {
  name = "/baby/phonebook/token"
  with_decryption = true
}

data "aws_ssm_parameter" "db_name" {
  name = "/baby/phonebook/dbname"
}

data "aws_ssm_parameter" "username" {
  name = "/baby/phonebook/username"
}

data "aws_ssm_parameter" "password" {
  name = "/baby/phonebook/password"
}

resource "local_file" "env_file" {
  content = <<-EOF
    MYSQL_ROOT_PASSWORD="${data.aws_ssm_parameter.password.value}"
    MYSQL_DATABASE="${data.aws_ssm_parameter.db_name.value}"
    MYSQL_USER="${data.aws_ssm_parameter.username.value}"
    MYSQL_PASSWORD="${data.aws_ssm_parameter.password.value}"
    MYSQL_DATABASE_HOST="database"
  EOF
  filename = "${path.module}/.env"
}



resource "github_repository" "myrepo" {
  name = "dockerization-phonebook-on-python-flask-mysql"
  visibility = "private"
  description = "Dockerization of Phonebook WebApp (Python Flask) with MySQL managed by Terraform"
  auto_init = true
}

resource "github_branch_default" "default"{
  repository = github_repository.myrepo.name
  branch     = "main"
}


resource "github_repository_file" "app-files" {
  repository          = github_repository.myrepo.name
  branch              = "main"
  commit_message      = "Managed by Terraform"
  overwrite_on_create = true

  for_each = toset(var.files)
  file =  each.value
  content = file("${path.module}/../${each.value}")
  
}



resource "aws_security_group" "docker-sec-gr" {
  name = "${var.tag}-sec-grp"
  tags = {
    Name = var.tag
  }

  dynamic "ingress" {
    for_each = var.docker-instance-ports
    iterator = port
    content {
      from_port = port.value
      to_port = port.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port =0
    protocol = "-1"
    to_port =0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "tf-docker-ec2" {
    ami           = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = [ aws_security_group.docker-sec-gr.id ]
    
    depends_on = [ github_repository.myrepo, github_repository_file.app-files ]

    iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
    
    tags = {
      Name = var.instance_tag  #"AdemU.'s Web Server of Phonebook"
    }

    user_data = templatefile("${abspath(path.module)}/userdata.sh", {git-token = local.github_token, git-user-name = var.git-user-name, env_file_content = local_file.env_file.content})
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.tag}-SSM-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "${var.tag}-SSM-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "${var.tag}-ec2-ssm-phonebook-instance-profile"
  role = aws_iam_role.ec2_role.name
}


