output "primary_vpc" {
  value       = aws_vpc.vpc.id
  description = "ID of Primary VPC."
}

output "public_subnets" {
  value       = aws_subnet.public.*.id
  description = "IDs of public subnets. You must access the IDs by index. The number of subnets is equal to the variable 'number_of_az'."
}

output "private_subnets" {
  value       = aws_subnet.private.*.id
  description = "IDs of private subnets. You must access the IDs by index. The number of subnets is equal to the variable 'number_of_az'."
}

output "ec2_ssm_instance_profile" {
  value       = aws_iam_instance_profile.ec2_ssm.name
  description = "Basic IAM Role for SSM access to ec2."
}
