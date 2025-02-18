variable "env" {
  description = "The environment we are working in"
  type        = string
}

variable "github_token" {
  description = "The GitHub token to use for authentication"
  type        = string
}

variable "github_owner" {
  description = "The GitHub owner to create repositories under"
  type        = string
}

variable "repositories" {
  description = "A map of repositories to create"
  type = map(object({
    description = string
  }))
}
