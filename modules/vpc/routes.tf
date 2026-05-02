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

  tags = {
    Name = "${var.vpc_name}-private-rt-${count.index + 1}"
  }
}

# Прив'язуємо приватні підмережі до відповідних приватних таблиць
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
