# CIE Infrastructure

Infrastructure setup for local development using Docker Compose.

## Overview

This repository contains Docker Compose configurations for running various infrastructure services locally. Currently, it includes:

- **Kafka** - Distributed event streaming platform
- **Zookeeper** - Coordination service for Kafka

## Prerequisites

- [Docker](https://www.docker.com/get-started) (version 20.10 or later)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2.0 or later)

## Project Structure

```
cie-infra/
├── kafka/
│   └── docker-compose.yml    # Kafka and Zookeeper setup
└── README.md
```

## Kafka Setup

The Kafka setup includes both Kafka and Zookeeper services configured to work together.

### Services

- **Zookeeper**: Coordination service for Kafka
  - Port: `2181`
  - Container: `zookeeper`

- **Kafka**: Event streaming platform
  - External port: `9092` (for client connections)
  - Internal port: `9093` (for inter-broker communication)
  - Container: `kafka`

### Starting Kafka

Navigate to the kafka directory and start the services:

```bash
cd kafka
docker-compose up -d
```

This will start both Zookeeper and Kafka in detached mode. Kafka will wait for Zookeeper to be healthy before starting.

### Stopping Kafka

To stop the services:

```bash
cd kafka
docker-compose down
```

To stop and remove volumes (this will delete all Kafka data):

```bash
docker-compose down -v
```

### Checking Service Status

View the status of running containers:

```bash
cd kafka
docker-compose ps
```

View logs:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f kafka
docker-compose logs -f zookeeper
```

### Connecting to Kafka

Once the services are running, you can connect to Kafka using:

- **Bootstrap server**: `localhost:9092`
- **Zookeeper**: `localhost:2181`

### Example: Creating a Topic

You can create a topic using the Kafka CLI tools inside the container:

```bash
docker exec -it kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 1 \
  --partitions 1 \
  --topic test-topic
```

### Example: Listing Topics

```bash
docker exec -it kafka kafka-topics --list \
  --bootstrap-server localhost:9092
```

### Example: Producing Messages

```bash
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic test-topic
```

### Example: Consuming Messages

```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --from-beginning
```

## Configuration

### Kafka Configuration

The Kafka service is configured with:
- Single broker setup (suitable for local development)
- Auto topic creation enabled
- Replication factor of 1 for offsets topic
- Health checks enabled for both services

### Network

All services run on a custom bridge network (`kafka-network`) to enable service discovery and communication.

## Troubleshooting

### Port Already in Use

If you encounter port conflicts, you can modify the port mappings in `kafka/docker-compose.yml`:

```yaml
ports:
  - "9093:9092"  # Change external port from 9092 to 9093
```

### Services Not Starting

1. Check if Docker is running: `docker ps`
2. Check logs: `docker-compose logs`
3. Ensure ports are not in use by other services
4. Try removing containers and starting fresh: `docker-compose down -v && docker-compose up -d`

## License

This project is for local development purposes.

