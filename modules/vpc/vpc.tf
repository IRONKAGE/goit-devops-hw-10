# ==========================================
# 1. БАЗОВА МЕРЕЖА (Спільна для Dev і Prod)
# ==========================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.vpc_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1" # Тег для публічних Load Balancers
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                              = "${var.vpc_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1" # Тег для внутрішніх Load Balancers
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.vpc_name}-igw" }
}

# ==========================================
# 2. НАТ МАРШРУТИЗАЦІЯ (Тільки для PROD)
# Забезпечує базовий вихід в інтернет для приватних підмереж
# ==========================================
resource "aws_eip" "nat" {
  count  = var.environment == "prod" ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count         = var.environment == "prod" ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  tags = { Name = "${var.vpc_name}-nat" }
}

# ==========================================
# 3. VPC ENDPOINTS (Тільки для PROD)
# Економія грошей на трафіку ECR та S3
# ==========================================

# Отримуємо поточний регіон автоматично
data "aws_region" "current" {}

resource "aws_security_group" "vpc_endpoints" {
  count       = var.environment == "prod" ? 1 : 0
  name        = "${var.vpc_name}-vpce-sg"
  description = "Security group for VPC Endpoints (ECR, S3)"
  vpc_id      = aws_vpc.main.id

  # Дозволяємо підключення тільки з нашої ж VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.environment == "prod" ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private[*].id

  # Використовуємо індекс [0], бо Security Group створюється через count
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.environment == "prod" ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.environment == "prod" ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # Слід перевірити, чи є створені ресурс(и) aws_route_table.private
  route_table_ids   = aws_route_table.private[*].id
}

# ==========================================
# 4. ТАБЛИЦІ МАРШРУТИЗАЦІЇ (ROUTE TABLES)
# ==========================================

# --- ПУБЛІЧНА ТАБЛИЦЯ ---
# Направляє весь зовнішній трафік (0.0.0.0/0) в Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.vpc_name}-public-rt" }
}

# Прив'язуємо всі публічні підмережі до публічної таблиці
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- ПРИВАТНІ ТАБЛИЦІ ---
# Створюємо по одній таблиці на кожну приватну підмережу
resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  # Якщо Prod - йдемо через NAT.
  # Якщо Dev - маршруту назовні немає.
  dynamic "route" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[0].id
    }
  }

  tags = { Name = "${var.vpc_name}-private-rt-${count.index + 1}" }
}

# Прив'язуємо приватні підмережі до відповідних приватних таблиць
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
