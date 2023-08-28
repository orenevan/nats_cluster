# nats cluster 

This repo is responsible for deploying a cluster of 3 NATS servers
Using Terraform and AWS cloud EC2 instances . 
Prepared by Oren Evan

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [Acknowledgements](#acknowledgements)

## Introduction

Cluster of NATS servers raised using Terraform and AWS cloud EC2 instances ,
Additionaly wanted to achieve service discovery.

## Features

List the key features of the project:

- Service Discovery: Achieved using Docker Swarm functionality 
  Swarm manager nodes assign each service in the swarm a unique DNS name and load balance running containers. .
- Docker Swarm Multipile Nodes: Master(nats_ec2_1) and Node(nats_ec2_1) are created 
- AWS Use of availability zones so each swarm node is running on a different zone to achieve HA
- Etcd Server:  Used as a key database 

## Getting Started

Instructions for setting up the project locally.

### Prerequisites

- Terraform 
- AWS Credentials
  set aws profile with aws credentials under ~/.aws/credentials 
  make sure to add 
 [terraform_aws_profile]
  aws_access_key_id =  AWS_ACCESS_KEY_ID
  aws_secret_access_key =  AWS_SECRET_KEY
- Docker (Optional - only for testing ) 
- Python3 (Optional- only for testing )


### Installation

Step-by-step instructions to install and configure the project.

1. Clone the repository: `[repository https://github.com/orenevan/nats_cluster.git]`
2. Navigate to the project directory: `cd nats_cluster`
3. Install dependencies: `npm install` or `pip install -r requirements.txt`
4. terraform init 
4. terraform plan      check out that plan looks ok
5. terraform apply     
6. For testing navigate to test_messages directory 
   Test script that validates that the service is acting properly by trying to subscribe to a subject on one node and publish to the same subject on another node.
   - testmessages/run_test_messages_docker.py: Excuting test_messages docker for nats operation    
   - Excuting Python test script for nats operation 
   - 
     sudo yum install pip3
   - 
     pip3 install --no-cache-dir -r requirements.txt
   -   
     python3 testmessages/test_messages.py <nats://nats_server_1:port1> <nats://nats_server_2:port2>
   - 
     default ports are exposed port1=1000 and port2=3000


## Usage

You can get the dns name for nats_server_1 identical to nats_server_1 from 
nats_ec2_1_public_dns under Terraform Outputs:

## Configuration

### on nats_ec2_1 the swarm master can issue the following commands
- sudo docker node ls
- sudo docker service ls
- sudo docker service ps nats-cluster-node-1 
- sudo docker service ps nats-cluster-node-2 

### scaling the server 
sudo docker service scale  nats-cluster-node-2=2 

### How to update the published port 
sudo docker service update --publish-add 4222 nats-cluster-node-1

## Contributing

Guidelines for contributing to the project. Include information about how to submit pull requests, report issues, and code standards.

1. Fork the repository
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Make your changes and commit them: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Create a pull request


![Project Screenshot](/images/screenshot.png)
