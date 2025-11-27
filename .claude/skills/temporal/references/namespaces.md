# Temporal Namespaces - Comprehensive Guide

## Overview

A Namespace is a fundamental isolation unit within the Temporal Platform that provides:

- **Security boundaries**: Separate access controls and authentication
- **Workflow management**: Isolated Workflow Executions and Event Histories
- **Unique identifiers**: Workflow IDs are unique within a Namespace
- **Resource isolation**: Separate rate limits and quotas
- **gRPC endpoints**: Dedicated connection endpoints (in Temporal Cloud)

Think of a Namespace as a logical database or schema that contains all your Workflows, Activities, Task Queues, and Event Histories for a particular application, environment, or tenant.

## Namespace Fundamentals

### What is a Namespace?

A Namespace serves as:

1. **Isolation Boundary**: Workflows in different Namespaces cannot directly communicate (except via Nexus)
2. **Security Perimeter**: Access control is enforced at the Namespace level
3. **Resource Container**: Rate limits, retention policies, and quotas are per-Namespace
4. **Deployment Unit**: In Temporal Cloud, each Namespace is a managed service endpoint

### Key Properties

- **Workflow ID Uniqueness**: Workflow IDs must be unique within a Namespace
- **Task Queue Scoping**: Task Queue names are scoped to a Namespace
- **Retention Period**: Closed Workflow retention is configured per Namespace
- **Rate Limits**: Each Namespace has its own rate limits (Actions Per Second in Cloud)
- **Default Namespace**: If not specified, the `"default"` Namespace is used

## TypeScript SDK Configuration

### Client Configuration

Configure the Namespace when creating a Client:

```typescript
import { Client } from '@temporalio/client';

// Connect to default namespace (if not specified, uses "default")
const client = new Client();

// Connect to specific namespace
const client = new Client({
  namespace: 'production-workflows',
});

// Connect with connection options
const client = new Client({
  namespace: 'production-workflows',
  connection: {
    address: 'temporal.example.com:7233',
  },
});
```

### Worker Configuration

Configure the Namespace when creating a Worker:

```typescript
import { Worker } from '@temporalio/worker';
import * as activities from './activities';

const worker = await Worker.create({
  namespace: 'production-workflows',
  taskQueue: 'my-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,
});

await worker.run();
```

**Important**: Client and Worker must use the same Namespace to communicate.

### Default Namespace Behavior

If the `namespace` option is omitted:

```typescript
// Both use "default" namespace
const client = new Client();
const worker = await Worker.create({
  taskQueue: 'my-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,
});
```

## Temporal Cloud Namespaces

### Namespace Naming Conventions

In Temporal Cloud, Namespace names must follow strict conventions:

**Namespace Name** (customer-supplied):
- 2-39 characters
- Start with a letter
- End with a letter or number
- Contain only lowercase letters, numbers, and hyphens (-)
- No consecutive hyphens
- Example: `accounting-production`

**Namespace ID** (fully qualified):
- Format: `<namespace-name>.<account-id>`
- Example: `accounting-production.f45a2`
- This is what you use in your code

**Account ID**:
- Assigned by Temporal Technologies
- 5+ alphanumeric characters
- Example: `f45a2`

### gRPC Endpoints

Temporal Cloud provides different endpoint types based on authentication method:

#### mTLS Authentication (Namespace-specific endpoint)

```typescript
import { Client } from '@temporalio/client';
import fs from 'fs/promises';

const client = new Client({
  namespace: 'accounting-production.f45a2',
  connection: {
    address: 'accounting-production.f45a2.tmprl.cloud:7233',
    tls: {
      clientCertPair: {
        crt: await fs.readFile('./certs/client.pem'),
        key: await fs.readFile('./certs/client-key.pem'),
      },
    },
  },
});
```

**Endpoint format**: `<namespace-id>.tmprl.cloud:7233`

#### API Key Authentication (Regional endpoint)

```typescript
import { Client } from '@temporalio/client';

const client = new Client({
  namespace: 'accounting-production.f45a2',
  connection: {
    address: 'us-west-2.aws.api.temporal.io:7233',
    tls: true,
    apiKey: process.env.TEMPORAL_API_KEY,
  },
});
```

**Endpoint format**: `<region>.<cloud-provider>.api.temporal.io:7233`

Regions include:
- `us-west-2.aws` (AWS US West 2)
- `us-east-1.aws` (AWS US East 1)
- `eu-west-1.aws` (AWS EU West 1)
- `ap-southeast-1.aws` (AWS Asia Pacific Southeast 1)
- `us-west1.gcp` (GCP US West 1)
- And more...

#### High Availability Namespaces

For HA-enabled Namespaces, always use the Namespace endpoint regardless of authentication method:

```typescript
const client = new Client({
  namespace: 'production.f45a2',
  connection: {
    address: 'production.f45a2.tmprl.cloud:7233',
    tls: true,
    apiKey: process.env.TEMPORAL_API_KEY,
  },
});
```

This allows automatic failover without changing endpoints.

### Authentication Methods

#### mTLS (Mutual TLS)

Requires client certificates:

```typescript
import { Client } from '@temporalio/client';
import { Worker } from '@temporalio/worker';
import fs from 'fs/promises';

const connectionOptions = {
  address: 'production.f45a2.tmprl.cloud:7233',
  tls: {
    clientCertPair: {
      crt: await fs.readFile('./certs/client.pem'),
      key: await fs.readFile('./certs/client-key.pem'),
    },
  },
};

// Use same connection config for Client and Worker
const client = new Client({
  namespace: 'production.f45a2',
  connection: connectionOptions,
});

const worker = await Worker.create({
  namespace: 'production.f45a2',
  connection: connectionOptions,
  taskQueue: 'my-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,
});
```

#### API Keys

Requires API key (simpler setup):

```typescript
const client = new Client({
  namespace: 'production.f45a2',
  connection: {
    address: 'us-west-2.aws.api.temporal.io:7233',
    tls: true,
    apiKey: process.env.TEMPORAL_API_KEY,
  },
});

const worker = await Worker.create({
  namespace: 'production.f45a2',
  connection: {
    address: 'us-west-2.aws.api.temporal.io:7233',
    tls: true,
    apiKey: process.env.TEMPORAL_API_KEY,
  },
  taskQueue: 'my-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,
});
```

**Best Practice**: Store API keys in environment variables or secrets management systems.

## Namespace Organization Best Practices

### Strategy 1: Namespace per Environment

Separate development, staging, and production:

```typescript
// Development
const devClient = new Client({ namespace: 'myapp-dev' });

// Staging
const stagingClient = new Client({ namespace: 'myapp-staging' });

// Production
const prodClient = new Client({ namespace: 'myapp-production' });
```

**Naming Convention**: `<use-case>_<environment>`

Examples:
- `order-processing_dev`
- `order-processing_staging`
- `order-processing_production`

### Strategy 2: Namespace per Service and Environment

For microservices architectures:

```typescript
// Order service - production
const orderClient = new Client({ namespace: 'order-service_production' });

// Inventory service - production
const inventoryClient = new Client({ namespace: 'inventory-service_production' });

// Payment service - production
const paymentClient = new Client({ namespace: 'payment-service_production' });
```

**Naming Convention**: `<use-case>_<service>_<environment>`

Examples:
- `ecommerce_order_production`
- `ecommerce_inventory_production`
- `ecommerce_payment_production`

### Strategy 3: Namespace per Domain and Environment

When multiple services need to communicate:

```typescript
// All e-commerce workflows in one namespace
const client = new Client({ namespace: 'ecommerce_production' });
```

**Considerations**:
- Workflow IDs must be unique across all services
- Prefix Workflow IDs with service name: `order-service_wf-123`
- Task Queue names must be unique
- Good for services using Signals or Child Workflows to communicate

**Naming Convention**: `<use-case>_<domain>_<environment>`

### Strategy 4: Multi-Tenant Architecture

Separate namespace per tenant:

```typescript
async function getClientForTenant(tenantId: string): Promise<Client> {
  return new Client({
    namespace: `tenant-${tenantId}`,
  });
}

// Usage
const acmeClient = await getClientForTenant('acme-corp');
const globexClient = await getClientForTenant('globex-inc');
```

**Pros**:
- Complete isolation between tenants
- Independent rate limits
- Separate retention policies
- Easy to delete tenant data

**Cons**:
- More Namespaces to manage
- Temporal Cloud has Namespace limits (default 10, auto-scales to 100)

## Multi-Namespace Patterns

### Pattern: Cross-Namespace Communication with Nexus

Workflows in different Namespaces can communicate using Temporal Nexus:

```typescript
// In namespace: order-service_production
import { startNexusOperation } from '@temporalio/workflow';

export async function orderWorkflow(orderId: string): Promise<void> {
  // Call into inventory-service namespace via Nexus
  const result = await startNexusOperation({
    service: 'inventory-service',
    operation: 'reserveInventory',
    args: [{ orderId, items: [...] }],
  });

  // Continue processing...
}
```

### Pattern: Environment-Specific Namespace Selection

```typescript
import { Client } from '@temporalio/client';

function getNamespace(): string {
  const env = process.env.NODE_ENV || 'development';

  switch (env) {
    case 'production':
      return 'myapp-production';
    case 'staging':
      return 'myapp-staging';
    default:
      return 'myapp-dev';
  }
}

const client = new Client({
  namespace: getNamespace(),
});
```

### Pattern: Shared Connection Configuration

```typescript
import { Client } from '@temporalio/client';
import { Worker, NativeConnection } from '@temporalio/worker';
import fs from 'fs/promises';

async function createConnection() {
  return await NativeConnection.connect({
    address: 'production.f45a2.tmprl.cloud:7233',
    tls: {
      clientCertPair: {
        crt: await fs.readFile('./certs/client.pem'),
        key: await fs.readFile('./certs/client-key.pem'),
      },
    },
  });
}

// Reuse connection across multiple namespaces
const connection = await createConnection();

const prodClient = new Client({
  namespace: 'myapp-production.f45a2',
  connection,
});

const stagingClient = new Client({
  namespace: 'myapp-staging.f45a2',
  connection,
});
```

## Rate Limits and Constraints

### Temporal Cloud Limits

**Namespace Count**:
- Default limit: 10 Namespaces per account
- Auto-scales to 100 based on usage
- Request increases via support ticket

**Actions Per Second (APS)**:
- Default: 400 APS per Namespace
- Automatically adjusts based on recent usage (7-day window)
- Never falls below default value
- Throttling occurs when limit is exceeded

**Service Level Agreement**:
- Standard SLA: 99.9% uptime per Namespace
- High Availability: 99.99% uptime (opt-in)

### Self-Hosted Temporal Server

Self-hosted installations can configure:

- Unlimited Namespaces (within resource constraints)
- Custom rate limits per Namespace
- Custom retention periods
- Custom archival configuration

## Common Patterns and Examples

### Example: Production Setup with Separate Namespaces

```typescript
// config/temporal.ts
import { Client } from '@temporalio/client';
import { Worker, NativeConnection } from '@temporalio/worker';
import fs from 'fs/promises';

interface NamespaceConfig {
  namespace: string;
  taskQueue: string;
}

const configs: Record<string, NamespaceConfig> = {
  orders: {
    namespace: 'orders_production.f45a2',
    taskQueue: 'orders-queue',
  },
  inventory: {
    namespace: 'inventory_production.f45a2',
    taskQueue: 'inventory-queue',
  },
  payments: {
    namespace: 'payments_production.f45a2',
    taskQueue: 'payments-queue',
  },
};

async function createCloudConnection() {
  return await NativeConnection.connect({
    address: 'us-west-2.aws.api.temporal.io:7233',
    tls: true,
    apiKey: process.env.TEMPORAL_API_KEY,
  });
}

export async function createClientForService(
  service: keyof typeof configs
): Promise<Client> {
  const config = configs[service];
  const connection = await createCloudConnection();

  return new Client({
    namespace: config.namespace,
    connection,
  });
}

export async function createWorkerForService(
  service: keyof typeof configs,
  activities: object
): Promise<Worker> {
  const config = configs[service];
  const connection = await createCloudConnection();

  return await Worker.create({
    namespace: config.namespace,
    connection,
    taskQueue: config.taskQueue,
    workflowsPath: require.resolve(`./workflows/${service}`),
    activities,
  });
}

// Usage in application
// app/orders/index.ts
import { createClientForService, createWorkerForService } from '../config/temporal';
import * as activities from './activities';

const client = await createClientForService('orders');
const worker = await createWorkerForService('orders', activities);

await worker.run();
```

### Example: Multi-Tenant with Dynamic Namespace Selection

```typescript
import { Client } from '@temporalio/client';

class TenantWorkflowService {
  private clients: Map<string, Client> = new Map();

  async getOrCreateClient(tenantId: string): Promise<Client> {
    if (this.clients.has(tenantId)) {
      return this.clients.get(tenantId)!;
    }

    const namespace = `tenant-${tenantId}`;
    const client = new Client({
      namespace,
      connection: {
        address: 'us-west-2.aws.api.temporal.io:7233',
        tls: true,
        apiKey: process.env.TEMPORAL_API_KEY,
      },
    });

    this.clients.set(tenantId, client);
    return client;
  }

  async startWorkflowForTenant(
    tenantId: string,
    workflowType: string,
    args: any[]
  ) {
    const client = await this.getOrCreateClient(tenantId);

    return await client.workflow.start(workflowType, {
      workflowId: `${tenantId}-${Date.now()}`,
      taskQueue: `tenant-${tenantId}-queue`,
      args,
    });
  }
}

// Usage
const service = new TenantWorkflowService();
await service.startWorkflowForTenant('acme-corp', 'orderWorkflow', [orderId]);
```

## Troubleshooting

### Issue: "Namespace not found" error

**Symptom**: `NamespaceNotFoundError` when starting Workflows or creating Workers

**Solutions**:
1. Verify namespace exists in Temporal Cloud UI or via `tctl namespace list`
2. Check spelling and casing (Cloud namespaces are case-sensitive)
3. Ensure using full Namespace ID format: `<name>.<account-id>`
4. For self-hosted, register namespace: `tctl namespace register --namespace myapp`

### Issue: Client and Worker on different Namespaces

**Symptom**: Worker doesn't pick up tasks, Workflows stuck in "Running" state

**Solution**: Ensure both Client and Worker use the same Namespace:

```typescript
const NAMESPACE = 'production-workflows';

const client = new Client({ namespace: NAMESPACE });
const worker = await Worker.create({
  namespace: NAMESPACE,  // Must match client
  taskQueue: 'my-queue',
  // ...
});
```

### Issue: Authentication failures to Temporal Cloud

**Symptom**: `PermissionDenied` or connection errors

**Solutions**:
1. **For mTLS**: Verify certificate files exist and are valid
2. **For API Keys**: Check API key is set correctly in environment variables
3. Verify endpoint matches authentication method:
   - mTLS: `<namespace>.tmprl.cloud:7233`
   - API Key: `<region>.<provider>.api.temporal.io:7233`
4. Ensure TLS is enabled: `tls: true` or `tls: { ... }`

### Issue: Rate limiting / throttling

**Symptom**: `ResourceExhausted` errors, high latency

**Solutions**:
1. Check current APS usage in Temporal Cloud UI
2. Optimize Workflow execution (reduce Signal/Query frequency)
3. Distribute load across multiple Namespaces
4. Request APS increase via support ticket
5. Implement backoff/retry logic in application

### Issue: Workflow ID conflicts across services

**Symptom**: `WorkflowExecutionAlreadyStarted` errors

**Solution**: Prefix Workflow IDs with service name when sharing a Namespace:

```typescript
// In order-service
await client.workflow.start(orderWorkflow, {
  workflowId: `order-service:${orderId}`,
  // ...
});

// In inventory-service
await client.workflow.start(inventoryWorkflow, {
  workflowId: `inventory-service:${inventoryId}`,
  // ...
});
```

## Best Practices Summary

1. **Use Separate Namespaces for Environments**: Always separate dev, staging, and production
2. **Choose Appropriate Naming Convention**: Be consistent across your organization
3. **Consider Blast Radius**: Isolate critical applications in separate Namespaces
4. **Monitor Rate Limits**: Watch APS usage and plan for scale
5. **Secure Credentials**: Store API keys and certificates securely (secrets management)
6. **Use Namespace-specific Endpoints for HA**: Enables automatic failover
7. **Plan for Multi-Tenancy Early**: Design Namespace strategy before scaling
8. **Document Namespace Organization**: Maintain clear documentation of which apps use which Namespaces
9. **Use Nexus for Cross-Namespace Communication**: Don't try to share state across Namespaces
10. **Test Connection Configuration**: Verify Client and Worker can connect before deploying

## Additional Resources

- **Temporal Cloud Namespace Documentation**: https://docs.temporal.io/cloud/namespaces
- **TypeScript SDK Client Reference**: https://typescript.temporal.io/api/classes/client.Client
- **TypeScript SDK Worker Reference**: https://typescript.temporal.io/api/classes/worker.Worker
- **Temporal Nexus Documentation**: https://docs.temporal.io/cloud/nexus
