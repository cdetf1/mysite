# RSA 알고리즘을 이용해 private 키 생성.
resource "tls_private_key" "hk_keypair" {
  algorithm = "RSA"
  rsa_bits  = 2048 # 복잡하게는 4096 -> 무슨의민지 찾아보기
}

# private 키를 가지고 keypair 파일 생성.
resource "aws_key_pair" "hk_keypair" {
  key_name   = "keypair_try"
  public_key = tls_private_key.hk_keypair.public_key_openssh
}

# 키 파일을 생성하고 로컬에 다운로드.
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.hk_keypair.key_name}.pem"
  content = tls_private_key.hk_keypair.private_key_pem
  #file_permission에 생성된 파일에 어떤 권한을 줄것인지 설정
  #ssh 경우 400(더이상 편집을 하지 않는 경우) 이나 600(편집할 가능성이 있는 경우) 사용
  file_permission = "0600" 
  
}