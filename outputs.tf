output "nats_ec2_1_public_dns" {
  value = "${aws_instance.nats_ec2_1.public_dns}"
}

output "nats_ec2_1_public_ip" {
  value = "${aws_instance.nats_ec2_1.public_ip}"
}

output "nats_ec2_1_private_ip" {
  value = "${aws_instance.nats_ec2_1.private_ip}"
}


# output "swarm_join_command" {
#     value = aws_instance.nats_ec2_1[*].tags["swarm_join_command"]
# }

# output "swarm_join_command" {
#   value = aws_instance.nats_ec2_1.tags["swarm_join_command"]
# }
