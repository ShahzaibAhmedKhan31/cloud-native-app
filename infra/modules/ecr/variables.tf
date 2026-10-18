variable "repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "max_image_count" {
  description = "Max images to keep (older will be auto-deleted)"
  type        = number
  default     = 10
}
