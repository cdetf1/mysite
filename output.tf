# Django setting.py에서 Terraform 출력값을 사용하기 위한 단계
# Terraform Outputs 설정

output "rds_endpoint" {
  value = aws_db_instance.lab-rds.endpoint
}

output "rds_username" {
  value = aws_db_instance.lab-rds.username
}

output "rds_password" {
  value = aws_db_instance.lab-rds.password
  sensitive   = true
}

output "rds_db_name" {
  value = aws_db_instance.lab-rds.db_name
}
