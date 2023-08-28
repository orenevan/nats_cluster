
// optional https://www.cyberciti.biz/faq/how-to-install-docker-on-amazon-linux-2/
# Add group membership for the default ec2-user so you can run all docker commands without using the sudo command:
# sudo usermod -a -G docker ec2-user
# id ec2-user
# # Reload a Linux user's group assignments to docker w/o logout
# newgrp docker


terraform {
  required_version = ">= 0.11.0"
}

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.profile}"
}


resource "aws_key_pair" "terraform_ec2_key" {
  key_name = "ec2_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAyVZiCdWUMzln0Uf4fGBUcLDBy3YoIEbSOfr7bJUPaeOXvpvzvny49Jo+m8FMvffVf7V8dfjkMuQ6781fEtqvx9Mfs0kSPiYJxBuGoNQr4S4Vx4K+AIPPQ/3Tf3n16Sog/AAw2GQW/SrSTFBL7JF4IqNXdiEUkkegA2gkwGANXwVChFuuKtc38+PaFweHHZpRz/GZHAVQFEBBSdq4O5wu066d5/EUf0sEqcDSXGxIGnRWQFC+HwVjiTRdzMHoQb67bMIBPMI3LN7IoVOXk/7xTGGCC7SArk8OZ+GgH9BsT7E4VmmJlf9AEIZN4vZHW3jhkI9HWabUWMlpLua5bkSd1d2y+1GRVkQnPiborRMPbNCq7XBfSom1TO03NYtHpaay1xdHLTp1LcLiVDczR2m/FkOMCXiOhC8CUqAsEaP9GzQFV/UB41JM3voo/iJjss8HWCmDwdZYnb3dsS416WJSmJ46fCOQOicfouwGDbQirlnE5EzXplvhKTmq0ekMX/28bboRRcM7p2wFgmY/BrQv+yWYf+qnejgMd+7barj0K+g/bjJ4g6Neu4Agx08pq1VwtfmLtNmEjlPzFVoVnMVtDyJKCyZIObyCVJB+UY40lFiMi1MB4hJEcloRj3kuQm+8k5uI5zgDH3uaf+ipxvdaPsPivZ3KofhUAePAfU/oew== orenevan@orens-mbp"
  
}


resource "aws_security_group" "nats_sg" {
  name_prefix = "nats-sg-"
  description = "Allow nats inbound traffic" 
//  vpc_id = aws_vpc.nats_vpc.id

  # Allow NATS ports (4222, 6222, 8222) from specific IPs
   ingress {
    from_port = 4222
    to_port   = 4222
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]      
  }
   ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]      
  }

  # docker swarm port 
  ingress {
    from_port = 2377
    to_port   = 2377
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]      
  }

  # etcd server port 
  ingress {
    from_port = 2379
    to_port   = 2379
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]      
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_instance" "nats_ec2_1" {
  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.aws_region}a"
  key_name = aws_key_pair.terraform_ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.nats_sg.id]
 
  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              sudo yum update -y
              sudo yum install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker
              # set the docker swarm 
              sudo docker swarm init
              TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
              INSTANCE_ID=`curl http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $TOKEN"`
              LOCAL_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4 -H "X-aws-ec2-metadata-token: $TOKEN"`
              SWARM_JOIN_TOKEN=`sudo docker swarm join-token --quiet worker`
              SWARM_JOIN_COMMAND="docker swarm join --token $SWARM_JOIN_TOKEN $LOCAL_IP:2377" 
              
              # to remove
              #aws ec2 create-tags --resources $INSTANCE_ID --tags Key="swarm_join_command",Value="$SWARM_JOIN_COMMAND" >>/tmp/info.txt              
              
              ETCD_VER=v3.4.26
              # choose either URL
              GOOGLE_URL=https://storage.googleapis.com/etcd
              GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
              DOWNLOAD_URL=$GOOGLE_URL
              rm -f /tmp/etcd-$\{ETCD_VER\}-linux-amd64.tar.gz
              rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
              curl -L $DOWNLOAD_URL/$ETCD_VER/etcd-$ETCD_VER-linux-amd64.tar.gz -o /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
              tar xzvf /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
              # rm -rf /tmp/etcd-$\{ETCD_VER\}-linux-amd64.tar.gz    
              # register the service at etcd server     
              /tmp/etcd-download-test/etcdctl --endpoints=http://${aws_instance.etcd_server.private_ip}:2379 put swarm_join_command "sudo $SWARM_JOIN_COMMAND"                  
             
              sudo docker network create --driver overlay nats-cluster-example
              sudo docker service create --network nats-cluster-example --name nats-cluster-node-1 nats:1.0.0 -cluster nats://0.0.0.0:6222 -DV
              docker service create --network nats-cluster-example --name nats-cluster-node-2 nats:1.0.0 -cluster nats://0.0.0.0:6222 -routes nats://nats-cluster-node-1:6222 -DV

              # exposing the ports for external access -- should be tested executed manually  ---
              sudo docker service update --publish-add 1000:4222 nats-cluster-node-1
              sudo docker service update --publish-add 2000:4222 nats-cluster-node-1

              EOF
  
  tags = {
    Name = "nats_ec2_1"
  }

  depends_on = [
    aws_instance.etcd_server
  ]


}


resource "aws_instance" "nats_ec2_2" {
  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.aws_region}a"
  key_name = aws_key_pair.terraform_ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.nats_sg.id]
 
  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              sudo yum update -y
              sudo yum install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker

              ETCD_VER=v3.4.26
              # choose either URL
              GOOGLE_URL=https://storage.googleapis.com/etcd
              GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
              DOWNLOAD_URL=$GOOGLE_URL
              rm -f /tmp/etcd-$\{ETCD_VER\}-linux-amd64.tar.gz
              rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
              curl -L $DOWNLOAD_URL/$ETCD_VER/etcd-$ETCD_VER-linux-amd64.tar.gz -o /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
              tar xzvf /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
             
              # join docker swarm 
              `/tmp/etcd-download-test/etcdctl --endpoints=http://${aws_instance.etcd_server.private_ip}:2379 get swarm_join_command | tail -1`                  
              
              EOF


  depends_on = [
    aws_instance.nats_ec2_1 
  ]
  tags = {
    Name = "nats_ec2_2"
  }


}


# resource "aws_instance" "nats_ec2_3" {
#   ami           = "${var.ami_id}"
#   instance_type = "${var.instance_type}"
#   availability_zone = "${var.aws_region}a"
#   key_name = aws_key_pair.terraform_ec2_key.key_name
#   vpc_security_group_ids = [aws_security_group.nats_sg.id]

#   user_data = <<-EOF
#               #!/bin/bash
#               # Install Docker
#               sudo yum update -y
#               sudo yum install docker -y
#               sudo systemctl start docker
#               sudo systemctl enable docker
#               # Run NATS Docker container
#               sudo docker run -d --name nats-server \
#                   -p 4222:4222 -p 6222:6222 -p 8222:8222 \
#                   nats:latest  -p 6222 -cluster nats://localhost:6248 -routes nats://${aws_instance.nats_ec2_1.private_ip}:4248 --cluster_name test-cluster              
#               EOF


#   depends_on = [
#     aws_instance.nats_ec2_1 
#   ]
#   tags = {
#     Name = "nats_ec2_2"
#   }


# }


resource "aws_instance" "etcd_server" {
  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.aws_region}a"
  key_name = aws_key_pair.terraform_ec2_key.key_name
  //security_groups = [aws_security_group.nats_sg]
  vpc_security_group_ids = [aws_security_group.nats_sg.id]
 
  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              sudo yum update -y
              sudo yum install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker

              # Run Etcd container
              sudo docker run -d --rm --name Etcd-server \
              --publish 2379:2379 \
              --publish 2380:2380 \
              --env ALLOW_NONE_AUTHENTICATION=yes \
              --env ETCD_ADVERTISE_CLIENT_URLS=http://etcd-server:2379 \
              --env ETCD_ENABLE_V2=true \
              bitnami/etcd:latest 
              EOF
   tags = {
    Name = "etcd_server"
  }            

  }




# sudo yum install python3-pip
#pip install nats-py



# [ec2-user@ip-172-31-1-50 ~]$ sudo docker network create --driver overlay nats-cluster-example
# rm0kd5xfkkh10i4xo8yy0kkvi
# [ec2-user@ip-172-31-1-50 ~]$ sudo docker service create --network nats-cluster-example --name nats-cluster-node-1 nats:1.0.0 -cluster nats://0.0.0.0:6222 -DV
