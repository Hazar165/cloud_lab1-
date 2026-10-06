variable "aws_region" {
  description = "Регіон AWS, у якому створюється інфраструктура"
  type        = string
  default     = "eu-north-1"
}

variable "db_password" {
  description = "Пароль майстер-користувача RDS PostgreSQL. Не використовуйте символи /, @, пробіл і лапки."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && length(regexall("[/@\" ]", var.db_password)) == 0
    error_message = "db_password має містити щонайменше 8 символів і не може містити /, @, пробіл або лапки."
  }
}

variable "github_repo" {
  description = "Репозиторій GitHub у форматі owner/name, якому дозволено деплой через OIDC"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repo))
    error_message = "github_repo має бути у форматі owner/name."
  }
}

variable "alert_email" {
  description = "Email для підтвердження підписки на SNS-сповіщення CloudWatch"
  type        = string
}
