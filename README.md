# nats_cluster

# Setting terraform profile 
## set aws profile with aws credentials under ~/.aws/credentials 
  make sure to add 
 [terraform_aws_profile]
  aws_access_key_id =  AWS_ACCESS_KEY_ID
  aws_secret_access_key =  AWS_SECRET_KEY
 
# Optional set SSH key for ssh connectivity to mahines  
## under variable.tf  modify  
ssh-keygen -t rsa -b 4096
cat ~/.ssh/id_rsa.pub

# Running terraform to provision the resources 
terraform init 

terraform plan  

terraform apply --auto-approve   


# on nats_ec2_1 the swarm master can issue the following commands
sudo docker node ls
sudo docker service ls
sudo docker service nats-cluster-node-1 ps
sudo docker service ps nats-cluster-node-1 
sudo docker service ps nats-cluster-node-2 

# scaling the server 
sudo docker service scale  nats-cluster-node-2=2 

# How to publish the port 
sudo docker service update --publish-add 4222 nats-cluster-node-1


# Excuting test script for nata operation 
sudo yum install 
python your_script.py nats://nats-server-node-1:4222 nats://nats-server-node-2:4222

