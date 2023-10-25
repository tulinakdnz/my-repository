//variable "aws_secret_key" {}
//variable "aws_access_key" {}
variable "region" {}
variable "mykey" {}
variable "tags" {}
variable "myami" {
  description = "in order of; amazon linux 2023, redhat enterprise linux 9, ubuntu 22.04"
}
variable "control-node-type" {}
variable "worker-node-type" {}
variable "num" {}
variable "mysecgr" {}