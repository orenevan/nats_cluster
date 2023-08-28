# Build the Docker image
docker build -t test-messages .

# Run the Docker container with arguments
docker run --rm test-messages:latest nats://nats-server-node-1:4222 nats://nats-server-node-2:4222
