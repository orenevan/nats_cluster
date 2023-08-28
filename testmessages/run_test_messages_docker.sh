#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <nats://nats_server_1:port> <nats://nats_server_2:port>"
    exit 1
fi

# Build the Docker image
docker build -t test-messages:latest .

# Run the Docker container with arguments
docker run  --rm test-messages:latest "$1" "$2"


#--------------------- In case you want to deploy on Docker Swarm -----------------------------------
# pushing to docker hub 
#docker login -u USER -p PASSWORD 
#docker build -t orenevan/test_messages:latest .
#docker push orenevan/test_messages:latest
#docker service create --network nats-cluster-example --name test-messages orenevan/test_messages:latest nats://nats-cluster-node-1:4222 nats://nats-cluster-node-2:4222
#--------------------------------------------------------------------