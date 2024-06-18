variable "resource_group_name" {

  type = string

  description = "This variable holds the value of the resource group name"

}

variable "location" {

  type        = string
  description = "This variable holds the value of the location"

  default = "West Europe"

}

variable "tags" {

  type        = any
  description = "Tags"


}

variable "vm_name" {

  type = string

}

