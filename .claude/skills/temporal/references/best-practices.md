# Temporal Best Practices and Performance Guide

## Testing Strategies

### Testing Approach Hierarchy

Temporal recommends writing the majority of tests as **integration tests** because they provide the best balance of coverage and maintenance:

1. **End-to-End Tests**: Full Temporal Server + Worker + Client
2. **Integration Tests**: Workers with test server, mocked Activities, or both
3. **Unit Tests**: Individual functions with mocked dependencies

### Time-Skipping Test Framework

The test server supports **automatic time skipping**, making long-running Workflow tests complete in seconds:

```typescript
import { TestWorkflowEnvironment } from '@temporalio/testing';
import { Worker } from '@temporalio/worker';

let testEnv: TestWorkflowEnvironment;

beforeAll(async () => {
  testEnv = await TestWorkflowEnvironment.createTimeSkipping();
});

afterAll(async () => {
  await testEnv?.teardown();
});

test('workflow with 1 day sleep completes quickly', async () => {
  const worker = await Worker.create({
    connection: testEnv.nativeConnection,
    taskQueue: 'test',
    workflowsPath: require.resolve('./workflows'),
  });

  // Sleeps are automatically fast-forwarded!
  await worker.runUntil(
    testEnv.client.workflow.execute(sleeperWorkflow, {
      workflowId: uuid(),
      taskQueue: 'test',
    }),
  );
});
```

**Automatic Time Skipping:**
- Timers and sleeps are fast-forwarded
- Only pauses when Activities are running
- Use `.execute()` or `.result()` to enable

**Manual Time Skipping:**
```typescript
test('manual time advancement', async () => {
  const handle = await testEnv.client.workflow.start(sleeperWorkflow, {
    workflowId: uuid(),
    taskQueue: 'test',
  });

  worker.run(); // Don't await - let it run

  // Manually advance time
  await testEnv.sleep('25 hours');

  const days = await handle.query(daysQuery);
  expect(days).toBe(1);

  await testEnv.sleep('25 hours');
  expect(await handle.query(daysQuery)).toBe(2);
});
```

### Testing Activities in Isolation

Use `MockActivityEnvironment` to test Activities without a Worker:

```typescript
import { MockActivityEnvironment } from '@temporalio/testing';
import { activityInfo, heartbeat } from '@temporalio/activity';

test('activity with context', async () => {
  const env = new MockActivityEnvironment({ attempt: 2 });

  async function activityFoo(a: number, b: number): Promise<number> {
    return a + b + activityInfo().attempt;
  }

  const result = await env.run(activityFoo, 5, 35);
  expect(result).toBe(42); // 5 + 35 + 2
});

test('activity with heartbeat', async () => {
  const env = new MockActivityEnvironment();

  env.on('heartbeat', (details) => {
    expect(details).toBe(6);
  });

  async function activityFoo(): Promise<void> {
    heartbeat(6);
  }

  await env.run(activityFoo);
});

test('activity cancellation', async () => {
  const env = new MockActivityEnvironment();

  async function activityFoo(): Promise<void> {
    heartbeat(6);
    await sleep(100); // Cancellation-aware sleep
  }

  env.on('heartbeat', (d) => {
    expect(d).toBe(6);
    env.cancel(); // Cancel after heartbeat
  });

  await expect(env.run(activityFoo)).rejects.toThrow(CancelledFailure);
});
```

### Mocking Activities in Workflow Tests

```typescript
import type * as activities from './activities';

const mockActivities: Partial<typeof activities> = {
  makeHTTPRequest: async () => '99',
  sendEmail: async () => { /* mock */ },
};

const worker = await Worker.create({
  connection: testEnv.nativeConnection,
  activities: mockActivities,
  taskQueue: 'test',
  workflowsPath: require.resolve('./workflows'),
});
```

### Workflow Replay Testing

Test Workflow changes for determinism by replaying Event Histories:

```typescript
import { Worker } from '@temporalio/worker';
import fs from 'fs/promises';

// Test single history from file
test('replay workflow history', async () => {
  const history = JSON.parse(await fs.readFile('./history.json', 'utf8'));

  await Worker.runReplayHistory(
    {
      workflowsPath: require.resolve('./workflows'),
    },
    history,
  );
});

// Test multiple histories from server
test('replay production workflows', async () => {
  const executions = client.workflow.list({
    query: 'TaskQueue=foo and StartTime > "2024-01-01"',
  });

  const results = Worker.runReplayHistories(
    { workflowsPath: require.resolve('./workflows') },
    executions.intoHistories(),
  );

  for await (const result of results) {
    if (result.error) {
      console.error('Replay failed:', result);
    }
  }
});
```

**CI/CD Recommendation:**
1. Download Event Histories of recent Workflows
2. Run replay tests as part of CI
3. Fail build if non-determinism detected
4. Ensures safe deployment of Workflow changes

## Worker Performance Tuning

### Understanding Worker Slots

**Worker Task Slots** represent capacity to execute concurrent Tasks:
- Workflow Task Slots: For Workflow executions
- Activity Task Slots: For Activity executions
- Local Activity Slots: For Local Activity executions
- Nexus Task Slots: For Nexus operations

**Key Metrics:**
- `worker_task_slots_available`: Available slots
- `worker_task_slots_used`: Occupied slots
- `workflow_task_schedule_to_start_latency`: Queue wait time
- `activity_schedule_to_start_latency`: Queue wait time

### Configuration Options

#### 1. Executor Slots (Traditional)

```typescript
const worker = await Worker.create({
  taskQueue: 'my-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,
  maxConcurrentWorkflowTaskExecutionSize: 100,
  maxConcurrentActivityExecutionSize: 200,
});
```

**When to increase:**
- Worker hosts are underutilized (low CPU/memory)
- `worker_task_slots_available` shows depleted slots frequently
- High `schedule_to_start_latency`

#### 2. Worker Tuners (Modern, Recommended)

Worker tuners dynamically manage slots based on resources:

```typescript
import { Worker, PollerBehavior } from '@temporalio/worker';

const worker = await Worker.create({
  connection,
  taskQueue: 'my-task-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,

  // Autoscaling pollers (recommended)
  workflowTaskPollerBehavior: PollerBehavior.autoscaling(),
  activityTaskPollerBehavior: PollerBehavior.autoscaling(),
  nexusTaskPollerBehavior: PollerBehavior.autoscaling(),

  // Resource-based slot suppliers
  tuner: {
    activityTaskSlotSupplier: {
      type: 'resource-based',
      tunerOptions: {
        targetMemoryUsage: 0.8,
        targetCpuUsage: 0.9,
      },
    },
    workflowTaskSlotSupplier: {
      type: 'fixed-size',
      numSlots: 100,
    },
    localActivityTaskSlotSupplier: {
      type: 'resource-based',
      tunerOptions: {
        targetMemoryUsage: 0.8,
        targetCpuUsage: 0.9,
      },
    },
  },
});
```

**Slot Supplier Types:**

| Type | Best For | Characteristics |
|------|----------|----------------|
| **Fixed-Size** | Predictable workloads, Workflow Tasks | Simple, low overhead, predictable |
| **Resource-Based** | Variable workloads, Activities | Auto-adjusts, prevents OOM, higher overhead |
| **Custom** | Specialized requirements | Full control, complex implementation |

**Choosing Slot Suppliers:**
- **Workflow Tasks**: Use fixed-size (low resource consumption)
- **Activities**: Use resource-based if:
  - Unpredictable resource usage per Task
  - Need OOM protection
  - Fluctuating workloads with blocking I/O
- **Low latency**: Avoid resource-based (adds overhead)

### Poller Autoscaling

**Always use autoscaling pollers** (recommended for all use cases):

```typescript
const worker = await Worker.create({
  // ... other options
  workflowTaskPollerBehavior: PollerBehavior.autoscaling(),
  activityTaskPollerBehavior: PollerBehavior.autoscaling(),
  nexusTaskPollerBehavior: PollerBehavior.autoscaling(),
});
```

**Why?**
- Automatically adjusts poller count based on demand
- Improves throughput and schedule-to-start latency
- Prevents over-polling (wasted resources)
- Will become default in future SDK versions

**Manual configuration NOT recommended** unless you have specific constraints:
```typescript
// ⚠️ Manual configuration (not recommended)
maxConcurrentWorkflowTaskPollers: 5,
maxConcurrentActivityTaskPollers: 10,
```

### Workflow Cache Tuning

```typescript
import { Worker } from '@temporalio/worker';

const worker = await Worker.create({
  // ... other options
  // These are shared across all Workers on the host
  stickyWorkflowCacheSize: 100, // Max cached Workflow Executions
  maxCachedWorkflows: 100, // Same as above (synonym)
});
```

**When to adjust:**
- Monitor `sticky_cache_size` metric
- If cache limit hit and host has free RAM → increase
- If memory pressure and cache underutilized → decrease

**Cache Eviction Impact:**
- Evicted Workflows must replay from Event History
- Replay increases latency and Worker load
- Balance cache size with available memory

### Performance Monitoring

**Key Metrics to Track:**

1. **Slot Availability**: Are Workers at capacity?
   ```
   worker_task_slots_available{worker_type=WorkflowWorker}
   worker_task_slots_used{worker_type=ActivityWorker}
   ```

2. **Schedule-to-Start Latency**: Are Tasks waiting too long?
   ```
   workflow_task_schedule_to_start_latency
   activity_schedule_to_start_latency
   ```

3. **Poll Success Rate**: Are there too many Workers?
   ```
   Poll Success Rate = (poll_success + poll_success_sync) / (poll_success + poll_success_sync + poll_timeouts)
   ```
   - Target: > 90% (steady load), > 95% (high volume/low latency)
   - Low success + low latency + low utilization → **too many Workers**

4. **Cache Metrics**: Is cache sized appropriately?
   ```
   sticky_cache_size
   workflow_active_thread_count
   ```

### Scaling Decision Matrix

| Observation | Action |
|-------------|--------|
| High schedule-to-start latency + underutilized hosts | Increase executor slots or use resource-based tuners |
| Low poll success rate + low latency + low utilization | Reduce Worker count |
| Cache frequently full + available RAM | Increase cache size |
| High memory usage + underutilized cache | Decrease cache size |
| Rate limiting observed | Check `maxTaskQueueActivitiesPerSecond` or `maxWorkerActivitiesPerSecond` |

## General Best Practices

### 1. Workflow Design

**Keep Workflows Deterministic:**
```typescript
// ❌ Bad: Non-deterministic
export async function workflow() {
  const random = Math.random(); // Non-deterministic!
  const now = Date.now(); // Non-deterministic!
  await fetch('https://api.example.com'); // Side effect!
}

// ✅ Good: Deterministic
export async function workflow() {
  // Use Workflow APIs
  const now = wf.Date.now();
  await wf.sleep('1 hour');

  // Side effects in Activities
  const data = await fetchDataActivity();
}
```

**Limit Event History Size:**
- Use Continue-As-New for long-running Workflows
- Check `workflowInfo().continueAsNewSuggested`
- Keep payloads small (< 2MB per parameter)
- Don't store large objects in Workflow state

**Use Meaningful IDs:**
```typescript
// ❌ Bad: Random ID
workflowId: uuid()

// ✅ Good: Business-meaningful ID
workflowId: `order-${orderId}`
workflowId: `user-signup-${userId}-${timestamp}`
```

### 2. Activity Design

**Make Activities Idempotent:**
```typescript
// ✅ Idempotent: Safe to retry
export async function createOrder(orderId: string) {
  const existing = await db.orders.findOne({ orderId });
  if (existing) return existing;

  return await db.orders.create({ orderId, /* ... */ });
}
```

**Use Appropriate Timeouts:**
```typescript
// Quick operations
const { getUser } = proxyActivities<typeof acts>({
  startToCloseTimeout: '5 seconds',
});

// Long operations with heartbeat
const { processFile } = proxyActivities<typeof acts>({
  startToCloseTimeout: '10 minutes',
  heartbeatTimeout: '30 seconds',
});
```

**Keep Activities Focused:**
- One Activity = One responsibility
- Easier to test, retry, and reuse
- Better failure isolation

### 3. Error Handling

**Distinguish Retryable vs Non-Retryable:**
```typescript
import { ApplicationFailure } from '@temporalio/common';

export async function chargeCard(amount: number) {
  try {
    await paymentGateway.charge(amount);
  } catch (error) {
    if (error.code === 'INSUFFICIENT_FUNDS') {
      throw ApplicationFailure.nonRetryable('Insufficient funds');
    }
    // Other errors will be retried
    throw error;
  }
}
```

**Use Workflow Failure Patterns:**
```typescript
export async function workflow() {
  try {
    await riskyActivity();
  } catch (err) {
    // Log and handle
    if (err instanceof ActivityFailure) {
      await compensatingActivity();
    }
    throw err; // Fail Workflow
  }
}
```

### 4. Message Passing

**Wait for Handlers Before Completion:**
```typescript
export async function workflow() {
  // Set up async handlers
  wf.setHandler(myUpdate, async () => {
    await longRunningActivity();
  });

  // ... workflow logic ...

  // ✅ Wait for handlers to complete
  await wf.condition(wf.allHandlersFinished);
  return result;
}
```

**Use Locks for Shared State in Async Handlers:**
```typescript
import { Mutex } from 'async-mutex';

const lock = new Mutex();
let sharedState = 0;

wf.setHandler(mySignal, async () => {
  await lock.runExclusive(async () => {
    // Safe concurrent access
    const data = await myActivity();
    sharedState = data.value;
  });
});
```

### 5. Production Deployment

**Bundle Workflows Ahead of Time:**
```typescript
// build-workflow-bundle.ts
import { bundleWorkflowCode } from '@temporalio/worker';
import { writeFile } from 'fs/promises';

const { code } = await bundleWorkflowCode({
  workflowsPath: require.resolve('./workflows'),
});

await writeFile('./workflow-bundle.js', code);
```

```typescript
// worker.ts (production)
const worker = await Worker.create({
  workflowBundle: {
    codePath: require.resolve('./workflow-bundle.js'),
  },
  activities,
  taskQueue: 'production',
});
```

**Graceful Shutdown:**
```typescript
const worker = await Worker.create({
  // ... options ...
  shutdownGraceTime: '5 minutes', // Time to finish in-flight tasks
  shutdownForceTime: '10 minutes', // Hard timeout
});

// Shutdown on SIGTERM
process.on('SIGTERM', async () => {
  await worker.shutdown();
});
```

### 6. Monitoring and Observability

**Essential Metrics:**
- Schedule-to-start latency (queue wait time)
- Worker task slots (capacity)
- Poll success rate (over/under provisioning)
- Workflow execution time
- Activity retry counts
- Cache hit/miss rates

**Logging Best Practices:**
```typescript
// In Workflows
wf.log.info('Processing order', { orderId, userId });

// In Activities
import { Context } from '@temporalio/activity';
Context.current().log.info('Calling external API', { endpoint });
```

### 7. Security

**Use mTLS for Temporal Cloud:**
```typescript
import { Client, Connection } from '@temporalio/client';
import fs from 'fs-extra';

const cert = await fs.readFile('./your.pem');
const key = await fs.readFile('./your.key');

const connection = await Connection.connect({
  address: 'your-namespace.tmprl.cloud:7233',
  tls: {
    clientCertPair: { crt: cert, key },
  },
});

const client = new Client({
  connection,
  namespace: 'your-namespace',
});
```

**Data Encryption:**
- Use custom Data Converters for sensitive data
- Implement payload encryption/decryption
- Never log sensitive information

## Testing Checklist

- [ ] Unit tests for Activity logic
- [ ] Integration tests with mocked Activities
- [ ] Time-skipping tests for long-running Workflows
- [ ] Replay tests for Workflow determinism
- [ ] Cancellation and timeout scenarios
- [ ] Error handling and retry behavior
- [ ] Signal/Query/Update handler tests
- [ ] Continue-As-New behavior

## Performance Checklist

- [ ] Use poller autoscaling
- [ ] Configure appropriate slot suppliers
- [ ] Set realistic Activity timeouts
- [ ] Monitor schedule-to-start latency
- [ ] Track poll success rate
- [ ] Size Workflow cache appropriately
- [ ] Bundle Workflows for production
- [ ] Configure graceful shutdown
