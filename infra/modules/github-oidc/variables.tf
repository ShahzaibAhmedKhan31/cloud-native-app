variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "github_org_or_user" {
  description = "Your GitHub Username or Organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub Repository name"
  type        = string
  default     = "cloud-native-app"
}