variable "adminuser" {
  type =  string
}

variable "adminpass" {
  type =  string
}

variable "location" {
  type =  string
  default = "eastus2"
}

variable "tags" {
  type = map(string)
  description = "Resources tags"
}