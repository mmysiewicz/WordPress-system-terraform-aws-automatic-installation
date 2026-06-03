
data "aws_ami" "wp_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Wordpress Template

resource "aws_launch_template" "wp" {
  name_prefix   = "wp-lt"
  image_id      = data.aws_ami.wp_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.wp.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable php8.2
    yum clean metadata
    yum install -y amazon-efs-utils httpd php php-mysqlnd php-gd php-xml php-mbstring wget
    systemctl enable httpd
    systemctl start httpd

    mkdir -p /var/www/html/wp-content
    
    mount -t efs ${aws_efs_file_system.efs.id}:/ /var/www/html/wp-content
    echo "${aws_efs_file_system.efs.id}:/ /var/www/html/wp-content efs defaults,_netdev 0 0" >> /etc/fstab

    if [ ! -f /var/www/html/index.php ]; then
      wget https://wordpress.org/latest.tar.gz -P /tmp
      tar -xzf /tmp/latest.tar.gz -C /tmp
      cp -r /tmp/wordpress/* /var/www/html/
      chown -R apache:apache /var/www/html/
    fi



    cat <<CONFIG > /var/www/html/wp-config.php
    <?php
    define('DB_NAME', '${aws_db_instance.rds.db_name}');
    define('DB_USER', '${aws_db_instance.rds.username}');
    define('DB_PASSWORD', '${var.db_password}');
    define('DB_HOST', '${aws_db_instance.rds.address}');
    define('DB_CHARSET', 'utf8');
    define('DB_COLLATE', '');
    \$table_prefix = 'wp_';
    define('WP_DEBUG', false);
    if ( ! defined( 'ABSOLUTE_PATH' ) ) {
        define( 'ABSOLUTE_PATH', __DIR__ . '/' );
    }
    require_once ABSOLUTE_PATH . 'wp-settings.php';
    CONFIG

    chown apache:apache /var/www/html/wp-config.php
    systemctl restart httpd
  EOF
  )
}

resource "aws_autoscaling_group" "wp" {
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = [for s in aws_subnet.private : s.id]
  target_group_arns   = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.wp.id
    version = "$Latest"
  }
}