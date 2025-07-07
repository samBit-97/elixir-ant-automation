variable "name" {}
variable "allocated_storage" { default = 20 }
variable "instance_class" { default = "db.t3.micro" }
variable "db_name" {
  description = "Database name"
  type        = string
}
variable "db_username" {}
variable "db_password" {}
variable "subnet_ids" { type = list(string) }
variable "vpc_security_group_ids" { type = list(string) }
variable "publicly_accessible" { type = bool }
variable "tags" { type = map(string) }
