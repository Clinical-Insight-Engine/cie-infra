# CIE Infrastructure

Infrastructure setup for local development using Docker Compose.

## Overview

This repository contains Docker Compose configurations for running infrastructure services locally. The current setup includes:

- **Apache Kafka** - Distributed event streaming platform
- **Apache Zookeeper** - Coordination service for Kafka
- **Automatic Topic Initialization** - Pre-configured topics for FHIR, NLP, and pipeline processing

## Prerequisites

- Docker version 20.10 or later
- Docker Compose version 2.0 or later

Verify installation:

```bash
docker --version
docker-compose --version
```

## Project Structure

```
cie-infra/
├── kafka/
│   ├── docker-compose.yml    # Kafka and Zookeeper services
│   └── create-topics.sh      # Topic initialization script
└── README.md
```

## Kafka Setup

The Kafka setup includes Kafka, Zookeeper, and an automatic topic initialization service.

### Services

**Zookeeper**
- Port: 2181
- Container: zookeeper
- Image: confluentinc/cp-zookeeper:7.5.0

**Kafka**
- External port: 9092 (for client connections from host)
- Internal port: 9093 (for inter-container communication)
- Container: kafka
- Image: confluentinc/cp-kafka:7.5.0

**Topic Initialization**
- Container: kafka-topics-init
- Automatically creates required topics on startup

### Pre-configured Topics

The following topics are automatically created when the services start:

- `fhir.patient`
- `fhir.observation`
- `fhir.diagnostic_report`
- `fhir.document_reference`
- `nlp.extracted_entities`
- `pipeline.commands`
- `pipeline.results`
- `processing.errors`

All topics are created with:
- 1 partition
- Replication factor of 1 (suitable for local development)

### Starting Services

Navigate to the kafka directory and start the services:

```bash
cd kafka
docker-compose up -d
```

This command will:
1. Start Zookeeper and wait for it to be healthy
2. Start Kafka and wait for it to be healthy
3. Run the topic initialization script to create all required topics

### Stopping Services

To stop the services:

```bash
cd kafka
docker-compose down
```

To stop and remove volumes (this will delete all Kafka data):

```bash
docker-compose down -v
```

### Service Status

View the status of running containers:

```bash
cd kafka
docker-compose ps
```

View logs for all services:

```bash
docker-compose logs -f
```

View logs for a specific service:

```bash
docker-compose logs -f kafka
docker-compose logs -f zookeeper
docker-compose logs -f kafka-topics-init
```

### Verifying Topics

To verify that all topics were created successfully:

```bash
docker exec -it kafka kafka-topics --list --bootstrap-server localhost:9092
```

Expected output should include all 8 pre-configured topics listed above.

To get detailed information about a specific topic:

```bash
docker exec -it kafka kafka-topics --describe --bootstrap-server localhost:9092 --topic fhir.patient
```

### Connecting to Kafka

**From host machine:**
- Bootstrap server: `localhost:9092`
- Zookeeper: `localhost:2181`

**From within Docker network:**
- Bootstrap server: `kafka:9093`
- Zookeeper: `zookeeper:2181`

### Kafka CLI Examples

**List all topics:**

```bash
docker exec -it kafka kafka-topics --list --bootstrap-server localhost:9092
```

**Create a custom topic:**

```bash
docker exec -it kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 1 \
  --partitions 1 \
  --topic custom-topic
```

**Produce messages:**

```bash
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic fhir.patient
```

**Consume messages:**

```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic fhir.patient \
  --from-beginning
```

## Configuration

### Kafka Configuration

The Kafka service is configured with the following settings:

- Single broker setup (suitable for local development)
- Auto topic creation enabled
- Replication factor of 1 for offsets topic
- Dual listener configuration:
  - External listener on port 9092 for host connections
  - Internal listener on port 9093 for Docker network communication
- Health checks enabled for service dependency management

### Network Configuration

All services run on a custom bridge network (`kafka-network`) to enable:
- Service discovery using container names
- Isolated network communication
- Proper dependency management between services

### Topic Initialization

The `kafka-topics-init` service:
- Waits for Kafka to be healthy before executing
- Retries connection attempts up to 60 times with 2-second intervals
- Creates all required topics with error handling
- Verifies topic creation and reports success/failure status
- Exits after completion (does not restart)

## Troubleshooting

### Port Conflicts

If you encounter port conflicts, modify the port mappings in `kafka/docker-compose.yml`:

```yaml
ports:
  - "9094:9092"  # Change external port from 9092 to 9094
  - "9095:9093"  # Change internal port from 9093 to 9095
```

Update your client applications to use the new port.

### Services Not Starting

1. Verify Docker is running:
   ```bash
   docker ps
   ```

2. Check service logs:
   ```bash
   docker-compose logs
   ```

3. Verify ports are not in use:
   ```bash
   netstat -tuln | grep -E ':(2181|9092|9093)'
   # or
   ss -tuln | grep -E ':(2181|9092|9093)'
   ```

4. Clean restart:
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

### Topics Not Created

If topics are not created automatically:

1. Check the initialization container logs:
   ```bash
   docker-compose logs kafka-topics-init
   ```

2. Verify Kafka is healthy:
   ```bash
   docker-compose ps kafka
   ```

3. Manually run the topic creation script:
   ```bash
   docker exec -it kafka-topics-init /bin/bash /create-topics.sh
   ```

4. Manually create topics using Kafka CLI (see Kafka CLI Examples section)

### Kafka Container Exits

If the Kafka container exits with an error:

1. Check Kafka logs:
   ```bash
   docker-compose logs kafka
   ```

2. Verify Zookeeper is running and healthy:
   ```bash
   docker-compose ps zookeeper
   docker-compose logs zookeeper
   ```

3. Ensure sufficient system resources (memory, disk space)

## Version Information

- Kafka: 7.5.0 (Confluent Platform)
- Zookeeper: 7.5.0 (Confluent Platform)
- Docker Compose: Compatible with version 2.0+

## License

This project is for local development purposes.
