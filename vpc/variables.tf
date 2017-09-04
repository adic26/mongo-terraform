variable "region" {
 description = "The region of AWS."
 default     = "eu-west-1"
}

variable "owner" {
  description = "Resource owner name for tagging"
}

variable "tag_name" {
  description = "The AWS tag name."
}