import argparse
import asyncio
from nats.aio.client import Client as NATS

async def subscribe_handler(msg):
    print(f"Received message: {msg.data.decode()}")

async def main():
    parser = argparse.ArgumentParser(description="NATS Server Validation Script")
    parser.add_argument("node1", help="NATS server node 1 address (e.g., nats://nats-server-node-1:4222)")
    parser.add_argument("node2", help="NATS server node 2 address (e.g., nats://nats-server-node-2:4222)")
    args = parser.parse_args()

    nc_node1 = NATS()
    nc_node2 = NATS()

    try:
        await nc_node1.connect(args.node1)
        print(f"Connected to Node 1: {args.node1}")

        await nc_node2.connect(args.node2)
        print(f"Connected to Node 2: {args.node2}")

        subject = "test.subject"

        await nc_node1.subscribe(subject, cb=subscribe_handler)
        print(f"Subscribed to subject on Node 1")

        await nc_node1.publish(subject, b"Hello from Node 1!")
        print(f"Published message to subject on Node 1")

        await nc_node2.publish(subject, b"Hello from Node 2!")
        print(f"Published message to subject on Node 2")

        await asyncio.sleep(1)

    except Exception as e:
        print(f"Error: {e}")
    finally:
        await nc_node1.close()
        await nc_node2.close()
        print("Connections closed")

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
