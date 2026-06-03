
# EFS 

resource "aws_efs_file_system" "efs" {
  tags = {
    Name = "wp-efs"
  }
}

resource "aws_efs_mount_target" "mt" {
  for_each          = aws_subnet.private
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = each.value.id
  security_groups = [aws_security_group.efs.id]
}
