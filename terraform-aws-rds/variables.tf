variable "identifier" {
  description = "Unique RDS instance name in your AWS account and region."
  type        = string
  default     = "terraform-mysql"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,49}[a-z0-9]$", var.identifier)) && !strcontains(var.identifier, "--")
    error_message = "Use 2-51 lowercase letters, digits or hyphens; start with a letter, end with a letter/digit, and avoid consecutive hyphens."
  }
}

variable "database_name" {
  description = "Initial MySQL database created by RDS."
  type        = string
  default     = "appdb"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{0,63}$", var.database_name))
    error_message = "Use 1-64 alphanumeric characters, starting with a letter."
  }
}

variable "instance_class" {
  description = "RDS instance size; availability depends on region and engine version."
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Enable a standby in a second availability zone (additional cost)."
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Enable public routing for laptop access; requires allowed_client_cidrs."
  type        = bool
  default     = false
}

variable "allowed_client_cidrs" {
  description = "Additional IPv4 client ranges allowed on port 3306; use your public IP/32 for laptop access."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_client_cidrs : can(cidrnetmask(cidr)) && can(regex("/(3[0-2]|[12][0-9]|[1-9])$", cidr))])
    error_message = "Provide valid IPv4 CIDRs with prefix lengths 1-32; unrestricted /0 access is not allowed."
  }
}

variable "deletion_protection" {
  description = "Must be disabled and applied before destroying the database."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Set true only for disposable data; otherwise destruction retains a final snapshot."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Optional unique final snapshot name. Change if a snapshot from a prior deployment already exists."
  type        = string
  default     = null
}
