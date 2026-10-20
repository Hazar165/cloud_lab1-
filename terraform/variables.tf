variable "location" {
  description = "Регіон Azure"
  type        = string
  default     = "francecentral"
}

variable "db_password" {
  description = "Пароль адміністратора PostgreSQL. Щонайменше 8 символів, великі й малі літери та цифра."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && length(regexall("[/@\" ]", var.db_password)) == 0
    error_message = "db_password має містити щонайменше 8 символів і не може містити /, @, пробіл або лапки."
  }
}

variable "github_repo" {
  description = "Репозиторій GitHub у форматі owner/name, якому дозволено деплой"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repo))
    error_message = "github_repo має бути у форматі owner/name."
  }
}

variable "alert_email" {
  description = "Email для сповіщень Azure Monitor"
  type        = string
}

variable "api_username" {
  description = "Користувач, який отримує JWT"
  type        = string
  default     = "lab1"
}

variable "api_password" {
  description = "Пароль користувача API"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.api_password) >= 8
    error_message = "api_password має містити щонайменше 8 символів."
  }
}

variable "jwt_secret" {
  description = "Секрет підпису JWT. Не комітити."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jwt_secret) >= 16
    error_message = "jwt_secret має містити щонайменше 16 символів."
  }
}
