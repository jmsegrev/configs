# Temporal Workers Guide

## What is a Worker?

A **Worker** is the process that executes your Workflow and Activity code. Workers poll Task Queues for work and execute the tasks they receive.

**Key Concepts:**
- **Worker Process**: The overall process running your Worker code
- **Worker Entity**: Component within a process that listens to a specific Task Queue
- **Workflow Worker**: Executes Workflow code
- **Activity Worker**: Executes Activity code
- A single Worker Entity contains both Workflow and Activity Workers

## Creating a Basic Worker

### Development Worker

```typescript
import { Worker } from '@temporalio/worker';
import * as activities from './activities';

async function run() {
  const worker = await Worker.create({
    workflowsPath: require.resolve('./workflows'),
    activities,
    taskQueue: 'my-task-queue',
  });

  await worker.run();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

**Key Points:**
- `workflowsPath`: Path to Workflow file(s) - bundled at runtime in dev
- `activities`: Object containing Activity functions
- `taskQueue`: Name of Task Queue to poll
- `worker.run()`: Starts polling (runs until shutdown)

### Production Worker with Pre-bundled Workflows

**Step 1: Bundle Workflows at Build Time**

```typescript
// scripts/build-workflow-bundle.ts
import { bundleWorkflowCode } from '@temporalio/worker';
import { writeFile } from 'fs/promises';
import path from 'path';

async function bundle() {
  const { code } = await bundleWorkflowCode({
    workflowsPath: require.resolve('../workflows'),
  });
  const codePath = path.join(__dirname, '../../workflow-bundle.js');

  await writeFile(codePath, code);
  console.log(`Bundle written to ${codePath}`);
}

bundle().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

**Step 2: Use Bundle in Production Worker**

```typescript
// worker.ts
import { Worker } from '@temporalio/worker';
import * as activities from './activities';

const workflowOption = () =>
  process.env.NODE_ENV === 'production'
    ? {
        workflowBundle: {
          codePath: require.resolve('./workflow-bundle.js'),
        },
      }
    : { workflowsPath: require.resolve('./workflows') };

async function run() {
  const worker = await Worker.create({
    ...workflowOption(),
    activities,
    taskQueue: 'production-queue',
  });

  await worker.run();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

**Benefits of Pre-bundling:**
- Faster Worker startup time
- Catch bundling errors at build time (not runtime)
- Smaller production images
- Better for container environments

## Worker Configuration Options

### Essential Options

```typescript
const worker = await Worker.create({
  // Required
  taskQueue: 'my-task-queue',

  // Workflows (choose one)
  workflowsPath: require.resolve('./workflows'), // Dev: bundle at runtime
  workflowBundle: { codePath: './bundle.js' },   // Prod: pre-bundled

  // Activities
  activities: {
    myActivity1,
    myActivity2,
  },

  // Connection (optional - defaults to localhost:7233)
  connection: await NativeConnection.connect({
    address: 'localhost:7233',
  }),

  // Namespace (optional - defaults to 'default')
  namespace: 'my-namespace',
});
```

### Performance Options

```typescript
const worker = await Worker.create({
  taskQueue: 'my-task-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,

  // Workflow Task Execution
  maxConcurrentWorkflowTaskExecutionSize: 100, // Max concurrent Workflow Tasks

  // Activity Task Execution
  maxConcurrentActivityExecutionSize: 200, // Max concurrent Activities

  // Workflow Cache
  maxCachedWorkflows: 100, // Max cached Workflow instances

  // Polling (use autoscaling - recommended)
  workflowTaskPollerBehavior: PollerBehavior.autoscaling(),
  activityTaskPollerBehavior: PollerBehavior.autoscaling(),

  // Or use resource-based tuning
  tuner: {
    workflowTaskSlotSupplier: {
      type: 'fixed-size',
      numSlots: 100,
    },
    activityTaskSlotSupplier: {
      type: 'resource-based',
      tunerOptions: {
        targetMemoryUsage: 0.8,
        targetCpuUsage: 0.9,
      },
    },
  },
});
```

See `best-practices.md` for detailed performance tuning guidance.

### Shutdown Options

```typescript
const worker = await Worker.create({
  taskQueue: 'my-task-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,

  // Graceful shutdown
  shutdownGraceTime: '5 minutes',  // Time to finish in-flight tasks
  shutdownForceTime: '10 minutes', // Hard timeout (forced shutdown)
});
```

**Shutdown Signals:**
Workers automatically respond to: `SIGINT`, `SIGTERM`, `SIGQUIT`, `SIGUSR2`

## Worker Lifecycle and States

### Worker States

A Worker is always in one of seven states:

1. **INITIALIZED**: Created via `Worker.create()`, connected to server
2. **RUNNING**: `worker.run()` called, actively polling for tasks
3. **FAILED**: Unrecoverable error occurred
4. **STOPPING**: Shutdown signal received, stopping polling for new tasks
5. **DRAINING**: Workflow Tasks drained, waiting for Activities to complete
6. **DRAINED**: All tasks completed, ready to shut down
7. **STOPPED**: Shutdown complete, `worker.run()` resolved

### Check Worker State

```typescript
import { Worker } from '@temporalio/worker';

const worker = await Worker.create({...});

console.log(worker.getState()); // 'INITIALIZED'

const runPromise = worker.run();
console.log(worker.getState()); // 'RUNNING'

// Later...
await worker.shutdown();
console.log(worker.getState()); // 'STOPPED'
```

### Graceful Shutdown

```typescript
async function startWorker() {
  const worker = await Worker.create({
    taskQueue: 'my-queue',
    workflowsPath: require.resolve('./workflows'),
    activities,
    shutdownGraceTime: '5 minutes',
  });

  // Handle shutdown signals
  process.on('SIGINT', async () => {
    console.log('Received SIGINT, shutting down gracefully...');
    await worker.shutdown();
  });

  process.on('SIGTERM', async () => {
    console.log('Received SIGTERM, shutting down gracefully...');
    await worker.shutdown();
  });

  await worker.run();
  console.log('Worker stopped');
}
```

**Shutdown Process:**
1. Worker receives shutdown signal
2. Stops polling for new tasks (enters STOPPING state)
3. Waits for in-flight tasks to complete (up to `shutdownGraceTime`)
4. Tasks still running after grace period are abandoned (will be retried)
5. Worker enters STOPPED state

## Registration Requirements

### Critical Rule: Consistent Registration

**All Workers polling the same Task Queue MUST register identical Workflow and Activity Types.**

```typescript
// ✅ CORRECT: Worker 1
const worker1 = await Worker.create({
  taskQueue: 'orders',
  workflowsPath: require.resolve('./workflows/orders'),
  activities: { createOrder, cancelOrder },
});

// ✅ CORRECT: Worker 2 (same Task Queue, same types)
const worker2 = await Worker.create({
  taskQueue: 'orders',
  workflowsPath: require.resolve('./workflows/orders'),
  activities: { createOrder, cancelOrder },
});

// ❌ WRONG: Worker 3 (same Task Queue, different types)
const worker3 = await Worker.create({
  taskQueue: 'orders', // Same Task Queue!
  workflowsPath: require.resolve('./workflows/payments'), // Different Workflows!
  activities: { chargeCard }, // Different Activities!
});
```

**What happens if registration differs?**
- Worker polls Task for unknown Workflow/Activity Type
- Worker fails that specific Task
- Task is retried on another Worker
- If no Worker knows the type, Task is never completed

### Multiple Workers Pattern

Use different Task Queues for different Worker types:

```typescript
// Worker 1: Order processing
const orderWorker = await Worker.create({
  taskQueue: 'order-processing',
  workflowsPath: require.resolve('./workflows/orders'),
  activities: orderActivities,
});

// Worker 2: Payment processing
const paymentWorker = await Worker.create({
  taskQueue: 'payment-processing',
  workflowsPath: require.resolve('./workflows/payments'),
  activities: paymentActivities,
});

// Run both workers in the same process
await Promise.all([
  orderWorker.run(),
  paymentWorker.run(),
]);
```

## Docker Deployment

### Recommended Docker Image

Use **Node.js 18 or 20** with **glibc-based images** (NOT Alpine/musl).

**Basic Dockerfile:**

```dockerfile
FROM node:20-bullseye

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Build (including workflow bundle)
RUN npm run build

CMD ["node", "dist/worker.js"]
```

### Slim Images (Smaller Size)

```dockerfile
FROM node:20-bullseye-slim

# ⚠️ IMPORTANT: Install ca-certificates
RUN apt-get update \
    && apt-get install -y ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

CMD ["node", "dist/worker.js"]
```

**Why ca-certificates?**
- TypeScript SDK requires TLS certificates
- Missing in slim images by default
- Results in `TransportError: transport error` if missing

### Distroless Images (Most Secure)

```dockerfile
# -- BUILD STEP --
FROM node:20-bullseye AS builder

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# -- PRODUCTION IMAGE --
FROM gcr.io/distroless/nodejs20-debian11

COPY --from=builder /node_modules ./node_modules
COPY --from=builder /dist ./dist

CMD ["dist/worker.js"]
```

**Benefits:**
- Smallest image size (~50% of slim)
- Minimal attack surface
- No shell or package manager

### ⚠️ Do NOT Use Alpine

```dockerfile
# ❌ WRONG - Do not use Alpine!
FROM node:20-alpine
```

**Why not?**
- Alpine uses musl instead of glibc
- TypeScript SDK's Rust core requires glibc
- Results in errors like:
  ```
  Error: Error loading shared library ld-linux-x86-64.so.2:
  No such file or directory
  ```

### Configure Node.js Memory in Docker

```dockerfile
FROM node:20-bullseye

# ... setup ...

# Set Node.js memory to 80% of container limit
ENV NODE_OPTIONS="--max-old-space-size=1600"

CMD ["node", "dist/worker.js"]
```

Or use Kubernetes/container environment:

```yaml
# Kubernetes example
env:
  - name: NODE_OPTIONS
    value: "--max-old-space-size=1600"  # For 2GB container
resources:
  limits:
    memory: "2Gi"
```

**Why?**
- Default Node.js memory = 25% of _host_ physical memory
- In containers, this can be wrong (too little or too much)
- Set to ~80% of container memory limit
- Prevents OOM kills

## Connecting to Temporal Cloud

```typescript
import { Worker, NativeConnection } from '@temporalio/worker';
import fs from 'fs-extra';

async function run() {
  // Load certificates
  const cert = await fs.readFile('./your.pem');
  const key = await fs.readFile('./your.key');

  // Create connection with mTLS
  const connection = await NativeConnection.connect({
    address: 'your-namespace.tmprl.cloud:7233',
    tls: {
      clientCertPair: {
        crt: cert,
        key,
      },
    },
  });

  const worker = await Worker.create({
    connection,
    namespace: 'your-namespace',
    taskQueue: 'your-task-queue',
    workflowsPath: require.resolve('./workflows'),
    activities,
  });

  await worker.run();
}
```

**Required for Temporal Cloud:**
- Namespace address: `<namespace>.<accountId>.tmprl.cloud:7233`
- mTLS certificates (client cert + private key)
- Namespace name
- See Temporal Cloud docs for certificate management

## Worker Patterns

### Pattern 1: Single Worker, All Tasks

```typescript
// Simple: One Worker for everything
const worker = await Worker.create({
  taskQueue: 'default',
  workflowsPath: require.resolve('./workflows'),
  activities: { ...orderActs, ...paymentActs, ...notificationActs },
});
```

**Use when:**
- Small to medium applications
- All workflows can run on same infrastructure
- Simple deployment model

### Pattern 2: Multiple Workers, Specialized Queues

```typescript
// Separate Workers for different domains
const orderWorker = await Worker.create({
  taskQueue: 'orders',
  workflowsPath: require.resolve('./workflows/orders'),
  activities: orderActivities,
  maxConcurrentActivityExecutionSize: 50,
});

const paymentWorker = await Worker.create({
  taskQueue: 'payments',
  workflowsPath: require.resolve('./workflows/payments'),
  activities: paymentActivities,
  maxConcurrentActivityExecutionSize: 100,
});

// Run in parallel
await Promise.all([
  orderWorker.run(),
  paymentWorker.run(),
]);
```

**Use when:**
- Different scaling requirements
- Isolate failures by domain
- Different resource needs
- Independent deployment schedules

### Pattern 3: Worker Pool (Same Process)

```typescript
// Multiple Workers polling same queue (same process)
async function createWorkerPool(size: number) {
  const workers = await Promise.all(
    Array.from({ length: size }, () =>
      Worker.create({
        taskQueue: 'high-throughput',
        workflowsPath: require.resolve('./workflows'),
        activities,
      })
    )
  );

  return Promise.all(workers.map(w => w.run()));
}

// Create 5 Workers in same process
await createWorkerPool(5);
```

**Use when:**
- Need high throughput on single Task Queue
- Want to maximize CPU utilization
- Running on multi-core machines

**Note:** Usually better to scale horizontally (more Worker processes) than vertically (more Workers per process).

### Pattern 4: Worker with Health Checks

```typescript
import express from 'express';

let workerHealthy = false;

async function startWorker() {
  const worker = await Worker.create({...});

  // Set healthy when running
  const runPromise = worker.run();
  workerHealthy = true;

  // Set unhealthy on shutdown
  process.on('SIGTERM', () => {
    workerHealthy = false;
  });

  await runPromise;
}

// Health check endpoint for Kubernetes
const app = express();
app.get('/health', (req, res) => {
  if (workerHealthy) {
    res.status(200).send('OK');
  } else {
    res.status(503).send('Not Ready');
  }
});
app.listen(3000);

startWorker();
```

## Common Worker Issues

### Issue: Worker Not Picking Up Tasks

**Symptoms:**
- Workflows scheduled but not executing
- Worker running but idle

**Possible Causes:**
1. **Task Queue mismatch**: Worker and Client using different queue names
2. **Type not registered**: Worker doesn't have Workflow/Activity registered
3. **Connection issue**: Worker can't reach Temporal Server
4. **Namespace mismatch**: Worker and Client using different namespaces

**Solutions:**
```typescript
// Verify Task Queue matches
// Client:
await client.workflow.start(myWorkflow, {
  taskQueue: 'my-queue', // Must match Worker!
});

// Worker:
const worker = await Worker.create({
  taskQueue: 'my-queue', // Must match Client!
});

// Verify namespace matches
const worker = await Worker.create({
  namespace: 'my-namespace', // Must match Client!
});
```

### Issue: Worker Crashes or Restarts

**Common Causes:**
1. **Out of Memory**: Node.js exceeds container memory limit
2. **Unhandled Promise Rejections**: Async errors not caught
3. **Activity Failures**: Activity throws unexpected error

**Solutions:**

```typescript
// 1. Set memory limits properly
process.env.NODE_OPTIONS = '--max-old-space-size=1600';

// 2. Global error handlers
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  // Don't exit in production - log and continue
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1); // Critical error - should restart
});

// 3. Wrap Activities with error handling
export async function riskyActivity() {
  try {
    // Activity logic
  } catch (error) {
    console.error('Activity error:', error);
    throw error; // Let Temporal retry
  }
}
```

### Issue: Slow Worker Performance

**Symptoms:**
- High `schedule_to_start_latency`
- Tasks waiting in queue
- Low Worker CPU/memory utilization

**Solutions:**
1. **Enable poller autoscaling**:
   ```typescript
   workflowTaskPollerBehavior: PollerBehavior.autoscaling(),
   activityTaskPollerBehavior: PollerBehavior.autoscaling(),
   ```

2. **Increase executor slots**:
   ```typescript
   maxConcurrentActivityExecutionSize: 200,
   ```

3. **Add more Worker instances** (horizontal scaling)

4. **Check for rate limiting**:
   ```typescript
   // Remove if set
   maxWorkerActivitiesPerSecond: undefined,
   ```

See `best-practices.md` Worker Performance Tuning section for details.

## Worker Best Practices

1. ✅ **Pre-bundle Workflows** in production for faster startup
2. ✅ **Use graceful shutdown** with `shutdownGraceTime`
3. ✅ **Enable poller autoscaling** (don't manually configure pollers)
4. ✅ **Use resource-based tuning** for Activities with variable load
5. ✅ **Monitor Worker metrics** (slots, latency, poll success rate)
6. ✅ **Use health checks** for container orchestration
7. ✅ **Set Node.js memory** explicitly in containers
8. ✅ **Use glibc-based images** (not Alpine)
9. ✅ **Handle shutdown signals** properly
10. ✅ **Log Worker state** for debugging

## Monitoring Workers

**Key Metrics:**
- `worker_task_slots_available`: Available execution capacity
- `worker_task_slots_used`: Currently executing tasks
- `workflow_task_schedule_to_start_latency`: Queue wait time
- `activity_schedule_to_start_latency`: Activity queue wait time
- Poll success rate: Are Workers over-provisioned?

**Example Prometheus Query:**
```promql
# Slot utilization
worker_task_slots_used{worker_type="ActivityWorker"} /
worker_task_slots_available{worker_type="ActivityWorker"}

# Average schedule-to-start latency
avg(activity_schedule_to_start_latency)
```

See `best-practices.md` for complete monitoring guidance.
