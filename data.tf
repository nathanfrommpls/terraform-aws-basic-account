data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy" "ssm" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

data "aws_ami" "debian-linux-11" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = ["debian-11*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

