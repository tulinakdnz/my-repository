variable "tags" {
  default = ["control_node", "node_1", "node_2"]
}
variable "mykey" {
  default = "clarusway"
}
variable "user" {
  default = "clarusway"
}

variable "amznlnx2023" {
  default = "ami-03a6eaae9938c858c"
}

variable "ubuntu" {
  default = "ami-053b0d53c279acc90"
}

variable "instype" {
  default = "t2.micro"
}

# variable "aws_secret_key" {
#  default = "xxxxx"
# }

# variable "aws_access_key" {
#  default = "xxxxx"
# }