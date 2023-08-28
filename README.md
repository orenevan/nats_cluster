# nats_cluster
This repo is responsible for deploying a cluster of 3 NATS servers
Using Terraform and AWS cloud EC2 instances . 

## Bonus -- Automate service discovery method 
Was achived using docker swarm capabilities See "Appendix Docker Swarm capabilities"

## Test script 
Test script that validates that the service is acting properly by trying to subscribe to a subject on one node and publish to the same subject on another node.
### Excuting test_messages docker for nats operation 
 testmessages/run_test_messages_docker.py 
### Excuting Python test script for nats operation 
  sudo yum install pip3
  pip3 install --no-cache-dir -r requirements.txt
  python3 testmessages/test_messages.py <nats://nats_server_1:port> <nats://nats_server_2:port>
  ports are exposed to 1000 and 2000 

# Setting terraform profile 

## set aws profile with aws credentials under ~/.aws/credentials 
  make sure to add 
 [terraform_aws_profile]
  aws_access_key_id =  AWS_ACCESS_KEY_ID
  aws_secret_access_key =  AWS_SECRET_KEY
 
## Optional set SSH key for ssh connectivity to mahines  

## under variables.tf paste the public key   
ssh-keygen -t rsa -b 4096
cat ~/.ssh/id_rsa.pub
## connecting with ssh 
ssh -i ~/.ssh/id_rsa ec2-user@ec2-3-86-91-195.compute-1.amazonaws.com 

# Running terraform to provision the resources 
terraform init 

terraform plan  

terraform apply --auto-approve   

# Cluster operations 

## on nats_ec2_1 the swarm master can issue the following commands
sudo docker node ls
sudo docker service ls
sudo docker service nats-cluster-node-1 ps
sudo docker service ps nats-cluster-node-1 
sudo docker service ps nats-cluster-node-2 

## scaling the server 
sudo docker service scale  nats-cluster-node-2=2 

## How to publish the port 
sudo docker service update --publish-add 4222 nats-cluster-node-1
 
# Appendix Docker Swarm capabilities 
  for full guide refer to https://docs.docker.com/engine/swarm/ 
  docker node ls
  sudo docker service ls

##  Service discovery: 
 Swarm manager nodes assign each service in the swarm a unique DNS name and load balance running containers. 
 You can query every container running in the swarm through a DNS server embedded in the swarm.

## Load balancing:
 You can expose the ports for services to an external load balancer. 
 Internally, the swarm lets you specify how to distribute service containers between nodes.
