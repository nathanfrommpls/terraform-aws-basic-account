variable "sshkeypair" {
  default     = "id_rsa"
  type        = string
  description = "Name of SSH keypar used for systems."
}

variable "ec2_type" {
  default     = "t2.nano"
  type        = string
  description = "EC2 Type that should be used for the web servers."
}

variable "region" {
  default     = "us-east-1"
  type        = string
  description = "AWS Region that infrastructure will deploy to."
}

variable "number_of_az" {
  default     = "2"
  type        = string
  description = "The number of AZs you'd like to deploy to."
}

variable "tags" {
  type        = map(any)
  description = "Map of tags to be applied to all infrastructure that accepts tags."
}
