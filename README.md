# README - Proyecto Terraform

## Descripción

Este documento proporciona una guía detallada para actualizar las variables de entrada, el proveedor, los valores locales y las fuentes de datos en un proyecto de Terraform. Terraform es una herramienta de infraestructura como código (IaC) que permite definir, provisionar y gestionar la infraestructura a través de archivos de configuración.

## Estructura del Proyecto

El proyecto está organizado de la siguiente manera:

```
.
├── terraform
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── userdata
│   │   ├── staging-efs.sh
│   │   └── staging-wordpress.sh
│   └── variables.tf
└── terraform.zip
```

### Descripción de los Archivos

- **`main.tf`**: Este archivo contiene la configuración principal de los recursos que se van a desplegar en AWS. Define la VPC, subnets, grupos de seguridad, instancias EC2, y cualquier otro recurso necesario.

- **`outputs.tf`**: Define las salidas del proyecto de Terraform. Las salidas son valores que se pueden utilizar para obtener información sobre los recursos desplegados, como las direcciones IP de las instancias, IDs de los recursos, etc.

- **`providers.tf`**: Contiene la configuración del proveedor de Terraform. Especifica detalles sobre el proveedor de servicios en la nube que se va a utilizar (en este caso, AWS), incluyendo la región y las credenciales.

- **`userdata`**: Carpeta que contiene scripts de inicialización para las instancias EC2.
  - **`staging-efs.sh`**: Script que se ejecuta en el arranque de las instancias EC2 para configurar EFS (Elastic File System) en el entorno de staging.
  - **`staging-wordpress.sh`**: Script que se ejecuta en el arranque de las instancias EC2 para instalar y configurar WordPress en el entorno de staging.

- **`variables.tf`**: Define las variables de entrada que pueden ser utilizadas para parametrizar la configuración de Terraform. Estas variables permiten una configuración flexible y reutilizable del código.

- **`terraform.zip`**: Archivo comprimido que contiene todos los archivos necesarios para ejecutar el proyecto de Terraform. Este archivo puede ser distribuido y utilizado para desplegar la infraestructura en diferentes entornos.

## Pasos Detallados

### 1. Actualizar Variables de Entrada

Las variables de entrada permiten parametrizar los valores utilizados en el despliegue, facilitando su reutilización y mantenimiento.

1. **Abrir `variables.tf`**:
   ```bash
   nano terraform/variables.tf
   ```

2. **Actualizar el contenido**:
   Añadir o modificar las siguientes variables según sea necesario para tu entorno:

   ```hcl
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
   ```

   **Explicación**:
   - `az_num`: Número de Zonas de Disponibilidad (Availability Zones) a utilizar.
   - `namespace`: Prefijo para los nombres de los recursos, útil para identificar los recursos creados por este proyecto.
   - `vpc_cidr_block`: Bloque CIDR para la red VPC.

### 2. Configurar el Proveedor

El proveedor de AWS permite a Terraform interactuar con los servicios de AWS, como la creación de instancias EC2, VPCs, etc.

1. **Abrir `providers.tf`**:
   ```bash
   nano terraform/providers.tf
   ```

2. **Actualizar el contenido**:
   Añadir la configuración del proveedor de AWS:

   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = ">= 5.0"
       }
     }
   }
   
   provider "aws" {
     region = "us-east-1" # Cambia a tu región preferida
     default_tags {
       tags = {
         Management = "Terraform"
       }
     }
   }
   ```

   **Explicación**:
   - `required_providers`: Define que el proveedor `aws` es necesario y especifica la fuente y la versión.
   - `provider "aws"`: Configura el proveedor de AWS, incluyendo la región y las etiquetas predeterminadas.

### 3. Configurar Valores Locales y Fuentes de Datos

Los valores locales y las fuentes de datos ayudan a reutilizar configuraciones y obtener información del entorno AWS.

1. **Abrir `main.tf`**:
   ```bash
   nano terraform/main.tf
   ```

2. **Actualizar el contenido**:
   Añadir la configuración de valores locales y fuentes de datos:

   ```hcl
   locals {
     vpc = {
       azs        = slice(data.aws_availability_zones.available.names, 0, var.az_num)
       cidr_block = var.vpc_cidr_block
     }
     
     rds = {
       engine         = "mysql"
       engine_version = "8.0.35"
       instance_class = "db.t3.micro"
       db_name        = "mydb"
       username       = "dbuser123"
     }
     
     vm = {
       instance_type = "m5.large"
       instance_requirements = {
         memory_mib = {
           min = 8192
         }
         vcpu_count = {
           min = 2
         }
         instance_generations = ["current"]
       }
     }
     
     demo = {
       admin = {
         username = "wpadmin"
         password = "wppassword"
         email    = "admin@demo.com"
       }
     }
   }
   
   data "aws_region" "current" {}
   
   data "aws_availability_zones" "available" {
     state = "available"
   }
   
   data "aws_ami" "linux" {
     owners      = ["amazon"]
     most_recent = true
     name_regex  = "^al2023-ami-2023\\..*"
     filter {
       name   = "architecture"
       values = ["x86_64"]
     }
   }
   
   data "aws_iam_policy" "administrator" {
     name = "AdministratorAccess"
   }
   
   data "aws_iam_policy_document" "assume_role" {
     statement {
       effect = "Allow"
       principals {
         type        = "Service"
         identifiers = ["ec2.amazonaws.com"]
       }
       actions = ["sts:AssumeRole"]
     }
   }
   ```

   **Explicación**:
   - `locals`: Define valores reutilizables en el archivo de configuración.
     - `vpc`: Configuración de la VPC, incluyendo Zonas de Disponibilidad y bloque CIDR.
     - `rds`: Configuración de la base de datos RDS.
     - `vm`: Configuración de la máquina virtual.
     - `demo`: Credenciales para un usuario de demostración.
   - `data`: Fuentes de datos que obtienen información del entorno AWS, como la región actual, zonas de disponibilidad, AMI de Linux, y políticas de IAM.

### 4. Crear Recursos de Red

1. **Actualizar `main.tf`**:
   Añadir la configuración de recursos de red:

   ```hcl
   resource "aws_vpc" "default" {
     cidr_block           = local.vpc.cidr_block
     enable_dns_hostnames = true
     enable_dns_support   = true
     tags = {
       Name = "${var.namespace}-vpc"
     }
   }

   resource "aws_subnet" "public" {
     for_each = { for index, az_name in local.vpc.azs : index => az_name }
     vpc_id                  = aws_vpc.default.id
     cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, each.key)
     availability_zone       = each.value
     map_public_ip_on_launch = true
     tags = {
       Name = "${var.namespace}-subnet-public-${each.key}"
     }
   }
   
   # Otros recursos de red como subnets privadas, internet gateway, route tables, NAT gateway, etc.
   ```

   **Explicación**:
   - `aws_vpc`: Crea una nueva VPC con el bloque CIDR especificado y habilita los nombres de host DNS.
   - `aws_subnet`: Crea subredes públicas en cada Zona de Disponibilidad especificada.

### 5. Validar y Aplicar la Configuración

1. **Validar la configuración**:
   Ejecutar el siguiente comando para validar la sintaxis de los archivos de Terraform.
   ```bash
   terraform validate
   ```

2. **Planificar el despliegue**:
   Crear un plan de ejecución para visualizar los cambios que se aplicarán.
   ```bash
   terraform plan
   ```

3. **Aplicar el despliegue**:
   Ejecutar el siguiente comando para aplicar la configuración y desplegar los recursos.
   ```bash
   terraform apply
   ```

### 6. Revisar el Despliegue

1. **Navegar a la consola de AWS**:
   Ir a la consola de AWS y buscar VPC.
2. **Verificar componentes**:
   Verificar que los recursos de VPC, subnets, route tables, internet gateways, y NAT gateways se hayan creado correctamente.

### 7. Crear Recursos de Seguridad

1. **Actualizar `main.tf`**:
   Añadir la configuración de recursos de seguridad:

   ```hcl
   resource "aws_security_group" "nfs" {
     name_prefix = "${var.namespace}-nfs-"
     vpc_id      = aws_vpc.default.id
     ingress {
       description = "Allow any NFS traffic from private subnets"
       cidr_blocks = concat(values(aws_subnet.private)[*].cidr_block, values(aws_subnet.private_ingress)[*].cidr_block)
       from_port   = 2049
       to_port     = 2049
       protocol    = "tcp"
     }
     egress {
       description      = "Allow all outbound traffic"
       cidr_blocks      = ["0.0.0.0/0"]
       ipv6_cidr_blocks = ["::/0"]
       from_port        = 0
       to_port          = 0
       protocol         = "-1"
     }
   }

   # Otros recursos de seguridad como security groups para aplicaciones, bases de datos, etc.
   ```

   **Explicación**:
   - `aws_security_group`: Define un grupo de seguridad que permite tráfico NFS desde subredes privadas y tráfico de salida hacia cualquier destino.

2. **Validar y aplicar configuración**:
   Repetir los pasos de validación y aplicación de configuración.

### 8. Crear Endpoints de VPC

1. **Actualizar `main.tf`**:
   Añadir la configuración de endpoints de VPC:

   ```hcl
   resource "aws_vpc_endpoint" "interface" {
     for_each = toset(["ssm", "ssmmessages", "ec2messages", "secretsmanager"])
     vpc_id              = aws_vpc.default.id
     service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
     vpc_endpoint_type   = "Interface"
     private_dns_enabled = true
     subnet_ids         = values(aws_subnet.private_ingress)[*].id
     security_group_ids = [aws_security_group.any.id]
     tags = {
       Name = "${var.namespace}-endpoint-${each.key}"
     }
   }

   resource "aws_vpc_endpoint" "gateway" {
     for_each = toset(["s3"])
     vpc_id       = aws_vpc.default.id
     service_name = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
     tags = {
       Name = "${var.namespace}-endpoint-${each.key}"
     }
   }
   ```

   **Explicación**:
   - `aws_vpc_endpoint`: Crea endpoints de VPC, tanto de tipo `Interface` para servicios como SSM y Secrets Manager, como de tipo `Gateway` para S3.

2. **Validar y aplicar configuración**:
   Repetir los pasos de validación y aplicación de configuración.

## Conclusión

Siguiendo estos pasos detallados, podrás configurar y desplegar una infraestructura básica en AWS utilizando Terraform, asegurando que todas las variables, proveedores, valores locales y fuentes de datos estén correctamente definidos y aplicados. Este enfoque modular facilita la gestión y escalabilidad de tu infraestructura en la nube.

¡Buena suerte con tu despliegue!
