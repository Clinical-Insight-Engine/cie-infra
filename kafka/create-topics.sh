#!/bin/bash

KAFKA_BOOTSTRAP="kafka:9093"
MAX_RETRIES=60
RETRY_INTERVAL=2

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready at $KAFKA_BOOTSTRAP..."
for i in $(seq 1 $MAX_RETRIES); do
  if kafka-broker-api-versions --bootstrap-server $KAFKA_BOOTSTRAP > /dev/null 2>&1; then
    echo "Kafka is ready!"
    break
  fi
  if [ $i -eq $MAX_RETRIES ]; then
    echo "ERROR: Kafka did not become ready after $((MAX_RETRIES * RETRY_INTERVAL)) seconds"
    exit 1
  fi
  echo "Waiting for Kafka... ($i/$MAX_RETRIES)"
  sleep $RETRY_INTERVAL
done

# Additional wait to ensure Kafka is fully operational
echo "Waiting additional 5 seconds for Kafka to stabilize..."
sleep 5

# Create topics
echo "Creating Kafka topics..."

topics=(
  "fhir.patient"
  "fhir.observation"
  "fhir.diagnostic_report"
  "fhir.document_reference"
  "nlp.extracted_entities"
  "pipeline.commands"
  "pipeline.results"
  "processing.errors"
)

created_count=0
failed_count=0

for topic in "${topics[@]}"; do
  echo "Creating topic: $topic"
  if kafka-topics --create \
    --bootstrap-server $KAFKA_BOOTSTRAP \
    --topic "$topic" \
    --partitions 1 \
    --replication-factor 1 \
    --if-not-exists 2>&1; then
    echo "  ✓ Successfully created/verified topic: $topic"
    created_count=$((created_count + 1))
  else
    echo "  ✗ Failed to create topic: $topic"
    failed_count=$((failed_count + 1))
  fi
done

echo ""
echo "Topic creation summary:"
echo "  Created/Verified: $created_count"
echo "  Failed: $failed_count"

# Verify topics were created
echo ""
echo "Verifying topics exist..."
existing_topics=$(kafka-topics --list --bootstrap-server $KAFKA_BOOTSTRAP 2>/dev/null | grep -E "^($(IFS='|'; echo "${topics[*]}"))$" || true)
topic_count=$(echo "$existing_topics" | grep -v '^$' | wc -l)

echo "Found $topic_count out of ${#topics[@]} expected topics:"
echo "$existing_topics" | while read -r topic; do
  if [ -n "$topic" ]; then
    echo "  ✓ $topic"
  fi
done

if [ $topic_count -eq ${#topics[@]} ]; then
  echo ""
  echo "✓ All topics created successfully!"
  exit 0
else
  echo ""
  echo "✗ Warning: Not all topics were created. Expected ${#topics[@]}, found $topic_count"
  exit 1
fi

