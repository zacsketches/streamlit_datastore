provider "aws" {
  region = "us-east-1"  # Change to your preferred AWS region
}

data "aws_ssm_parameter" "amzn2_latest" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "sqlite_ec2" {
  ami           = data.aws_ssm_parameter.amzn2_latest.value
  instance_type = "t2.micro"
  key_name      = "my-key-pair"  # Replace with your key pair name

  tags = {
    Name = "sqlite-instance"
  }

  security_groups = [aws_security_group.allow_ssh.name]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y python3 sqlite
    
    # Format and mount the attached EBS volume
    sudo mkfs -t xfs /dev/xvdf
    sudo mkdir -p /mnt/sqlite-data
    sudo mount /dev/xvdf /mnt/sqlite-data
    sudo chown ec2-user:ec2-user /mnt/sqlite-data

    # Persist mount across reboots
    echo "/dev/xvdf /mnt/sqlite-data xfs defaults,nofail 0 2" | sudo tee -a /etc/fstab

    # Create an SQLite database and add three users
    sqlite3 /mnt/sqlite-data/my_database.db <<EOSQL
      CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT);
      INSERT INTO users (name) VALUES ('Alice');
      INSERT INTO users (name) VALUES ('Bob');
      INSERT INTO users (name) VALUES ('Charlie');
    EOSQL

    echo "SQLite Database Created and Users Inserted" > /home/ec2-user/setup.log
  EOF

  # Attach EBS volume
  root_block_device {
    volume_size = 8  # Root volume (8GB)
  }

  depends_on = [aws_ebs_volume.sqlite_ebs]
}

resource "aws_ebs_volume" "sqlite_ebs" {
  availability_zone = "us-east-1a"  # Ensure this matches your instance's AZ
  size              = 5  # 5GB EBS volume
  tags = {
    Name = "sqlite-ebs-volume"
  }
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.sqlite_ebs.id
  instance_id = aws_instance.sqlite_ec2.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change to your IP for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.sqlite_ec2.public_ip
}
