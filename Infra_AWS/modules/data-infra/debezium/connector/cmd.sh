#!/bin/bash

echo "Injecting config"
curl -X POST http://localhost:8083/connectors \
     -H "Content-Type: application/json" \
     -d @pg-connector.json

echo "Checking status"
curl http://localhost:8083/connectors/pg-auth-catalog-orders/status
