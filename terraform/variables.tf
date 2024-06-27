variable "az_num" {
  description = "Número de Zonas de Disponibilidad a utilizar"
  type        = number
  default     = 2
}

variable "namespace" {
  description = "Prefijo para los nombres de los recursos"
  type        = string
  default     = "terraform-workshop"
}

variable "vpc_cidr_block" {
  description = "Bloque CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}
