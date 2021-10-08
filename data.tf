data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy" "ssm" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
