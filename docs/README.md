# API Documentation

## Agent Provisioner API

The agent provisioner API is a Lambda function exposed through API Gateway for managing agent lifecycles.

### API Endpoint

```
https://<api-gateway-id>.execute-api.sa-east-1.amazonaws.com/<environment>/provisioner
```

### Lifecycle Operations

#### Create Instance

Creates a new agent instance with specified configuration:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "lifecycle": "create",
    "INSTANCE_TYPE": "c5.4xlarge",
    "ENVIRONMENT": "prod1",
    "eliza_config": {
      "meta": {
        "customerId": "ABC123XYZ42"
      },
      "env": {
        "SERVER_PORT": "3000",
        "CACHE_STORE": "database"
      }
    }
  }' \
  https://<api-gateway-id>.execute-api.sa-east-1.amazonaws.com/prod1/provisioner
```

#### Update Instance

Updates an existing agent instance:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "lifecycle": "update",
    "meta": {
      "customerId": "ABC123XYZ42"
    },
    "eliza_config": {
      "env": {
        "SERVER_PORT": "3001"
      }
    }
  }' \
  https://<api-gateway-id>.execute-api.sa-east-1.amazonaws.com/prod1/provisioner
```

#### Destroy Instance

Terminates an agent instance:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "lifecycle": "destroy",
    "meta": {
      "customerId": "ABC123XYZ42"
    }
  }' \
  https://<api-gateway-id>.execute-api.sa-east-1.amazonaws.com/prod1/provisioner
```

### Helper Scripts

Convenience scripts are available in the [`../bin`](../bin/) directory:

```bash
# Launch new instance
./bin/launch-eliza-instance.sh prod1 ABC123XYZ42

# Update existing instance
./bin/update-eliza-instance.sh prod1 ABC123XYZ42

# Destroy instance
./bin/destroy-eliza-instance.sh prod1 ABC123XYZ42

# List backups
./bin/list-backups.sh
```

## Accessing Launched Agents

Once an agent instance completes its initialization:

1. The agent becomes available through the Nginx proxy
2. Access URL format: `https://<environment>-nginx.icekernelcloud01.com/<customerId>/agents`

### Example

For customer ID `ABC123XYZ42` in production:

```
https://prod1-nginx.icekernelcloud01.com/ABC123XYZ42/agents
```

## API Gateway Routes

The API Gateway configuration includes:
- `/provisioner` - Main provisioning endpoint
- Authentication via Lambda authorizer
- Environment-specific deployments (prod1, test1)
