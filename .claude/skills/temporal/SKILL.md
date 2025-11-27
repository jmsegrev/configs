---
name: temporal
description: This skill provides comprehensive guidance on developing Temporal applications with the TypeScript SDK, including Workflow and Activity creation, Namespace configuration and organization, reusability patterns (Child Workflows, Continue-As-New, Entity Pattern), message passing (Signals/Queries/Updates), testing strategies, Worker performance tuning, and best practices. Use this skill when creating or optimizing Temporal Workflows and Activities, configuring Namespaces and connections to Temporal Cloud, implementing durable execution patterns, testing Temporal applications, or configuring Workers for production deployment.
---

# Temporal Expert - TypeScript SDK Development

## Overview

Master Temporal application development with the TypeScript SDK. This skill provides comprehensive guidance on creating durable, scalable distributed applications using Temporal's Workflow and Activity model.

**What you'll learn:**
- Create deterministic Workflows that orchestrate complex business logic
- Design reusable Activities with proper error handling and retry strategies
- Configure and organize Namespaces for isolation and multi-tenancy
- Connect to Temporal Cloud with API keys or mTLS authentication
- Implement advanced patterns: Child Workflows, Continue-As-New, Entity Pattern
- Use Signals, Queries, and Updates for Workflow communication
- Test Workflows and Activities with time-skipping
- Tune Worker performance for production workloads
- Apply best practices for reliability and scalability

## When to Use This Skill

Invoke this skill when:

- **Creating Workflows**: Building new Temporal Workflows or refactoring existing ones
- **Creating Activities**: Designing Activities that interact with external systems
- **Implementing Reusability**: Using Child Workflows, Continue-As-New, or Entity Patterns
- **Message Passing**: Adding Signals, Queries, or Updates to Workflows
- **Testing**: Writing tests for Workflows or Activities
- **Performance Tuning**: Optimizing Worker configuration or scaling deployments
- **Debugging Issues**: Understanding determinism constraints or Event History problems
- **Production Deployment**: Preparing Temporal applications for production
- **Code Review**: Ensuring Temporal code follows best practices
- **Namespace Management**: Configuring, organizing, or connecting to Temporal Namespaces

## Core Capabilities

### 1. Workflow Development

Create deterministic Workflows that orchestrate Activities and maintain durable state.

**Key Topics:**
- Basic Workflow structure and parameters
- Deterministic constraints and sandbox behavior
- Workflow reusability patterns
- Message handlers (Signals, Queries, Updates)
- Cancellation scopes
- Starting and managing Workflows

**Reference:** See `references/workflows.md` for comprehensive Workflow development guide

**Example: Basic Workflow with Activity**
```typescript
import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const { processOrder, sendEmail } = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
});

export async function orderWorkflow(orderId: string): Promise<string> {
  // Orchestrate Activities
  const result = await processOrder(orderId);
  await sendEmail(result.customerEmail, 'Order processed');

  return `Order ${orderId} completed`;
}
```

### 2. Activity Development

Design Activities that handle side effects and interact with external systems.

**Key Topics:**
- Activity fundamentals and parameters
- Activity Context API (Context.current())
- Heartbeating and progress tracking
- Cancellation handling (signals and promises)
- Dependency injection patterns
- Async Activity completion
- Local Activities
- Activity retry strategies
- Idempotency patterns

**Reference:** See `references/activities.md` for comprehensive Activity development guide

**Example: Activity with Dependency Injection**
```typescript
// activities.ts
export interface Database {
  query(sql: string): Promise<any>;
}

export const createActivities = (db: Database) => ({
  async processOrder(orderId: string): Promise<OrderResult> {
    const order = await db.query(`SELECT * FROM orders WHERE id = ?`, [orderId]);
    // Process order logic
    return { orderId, status: 'processed' };
  },

  async sendEmail(email: string, message: string): Promise<void> {
    // Email sending logic
  },
});
```

#### Activity Context API (Context.current())

Access Activity execution context and metadata using `Context.current()`. This API provides read-only access to Activity information, heartbeating, cancellation, logging, and metrics.

**Implementation Details:**
- Uses Node's `AsyncLocalStorage` for thread-safe context propagation
- Available only within Activity execution scope
- Context object is read-only (cannot add custom properties)

**Source:** `temporal-sdk-typescript/packages/activity/src/index.ts:237-395`

**Available Properties and Methods:**

```typescript
import { Context } from '@temporalio/activity';

export async function myActivity() {
  const context = Context.current();

  // Execution metadata
  context.info.activityId          // Unique Activity ID
  context.info.activityType        // Activity function name
  context.info.attempt             // Current attempt number (starts at 1)
  context.info.workflowExecution   // Parent Workflow info
  context.info.heartbeatDetails    // Details from last heartbeat (for retries)

  // Methods
  context.heartbeat(details?)      // Send progress with optional details
  context.sleep(ms)                // Cancellation-aware sleep

  // Properties
  context.client                   // Temporal Client (same namespace)
  context.log                      // Logger instance
  context.metricMeter             // MetricMeter for custom metrics
  context.cancelled               // Promise that rejects on cancellation
  context.cancellationSignal      // AbortSignal for cancellation
  context.cancellationDetails     // Details about why cancelled
}
```

**Example: Progress Tracking with Heartbeats**
```typescript
import { Context } from '@temporalio/activity';

export async function processItems(items: string[]): Promise<void> {
  for (let i = 0; i < items.length; i++) {
    await processItem(items[i]);

    // Send progress (persisted for retries)
    Context.current().heartbeat({
      processed: i + 1,
      total: items.length
    });
  }
}
```

**Example: Cancellation-Aware Fetch**
```typescript
import fetch from 'node-fetch';
import { Context } from '@temporalio/activity';

export async function cancellableFetch(url: string): Promise<any> {
  // Pass AbortSignal for automatic cancellation
  const response = await fetch(url, {
    signal: Context.current().cancellationSignal
  });

  const contentLength = parseInt(response.headers.get('Content-Length'));
  let bytesRead = 0;
  const chunks: Buffer[] = [];

  for await (const chunk of response.body) {
    bytesRead += chunk.length;
    chunks.push(chunk);

    // Report download progress
    Context.current().heartbeat(bytesRead / contentLength);
  }

  return Buffer.concat(chunks);
}
```

**Source:** `temporal-sdk-typescript/packages/test/src/activities/cancellable-fetch.ts`

**Example: Waiting for Cancellation**
```typescript
import { Context } from '@temporalio/activity';
import { CancelledFailure } from '@temporalio/common';

export async function waitForCancellation(): Promise<void> {
  try {
    // Block until cancellation is requested
    await Context.current().cancelled;
  } catch (err) {
    if (err instanceof CancelledFailure) {
      // Cleanup logic here
    }
    throw err;
  }
}
```

**Can You Add Custom Data to Context?**

**No, the Context object is read-only.** However, you have these options:

1. **Use `heartbeat()` for progress data** (Recommended)
   ```typescript
   // ✅ This works - data persists across retries
   Context.current().heartbeat({
     customField: "data",
     progress: 50
   });
   ```

2. **Pass data through Activity parameters**
   ```typescript
   // ✅ Best for business data
   export async function myActivity(config: Config, state: State) {
     // Use parameters for data passing
   }
   ```

3. **Use Context Propagators for observability**
   - Configure OpenTelemetry or custom propagators at Worker/Client level
   - Used for distributed tracing and cross-workflow metadata
   - See TypeScript SDK observability documentation

**Best Practices:**

✅ **DO:**
- Use `heartbeat()` for progress tracking and resumable state
- Use `cancellationSignal` with external libraries (fetch, etc.)
- Use `context.info` for execution metadata and logging
- Use `context.sleep()` for cancellation-aware delays
- Keep heartbeat details small (persisted to Workflow history)

❌ **DON'T:**
- Try to mutate or extend Context (will fail)
- Use Context for passing business data (use Activity parameters)
- Store large objects in heartbeat details
- Call Context.current() outside Activity execution

**Context.Info Interface:**

```typescript
export interface Info {
  readonly taskToken: Uint8Array;
  readonly base64TaskToken: string;
  readonly activityId: string;
  readonly activityType: string;
  readonly activityNamespace: string;
  readonly attempt: number;                   // Starts at 1, increments on retry
  readonly isLocal: boolean;                  // Whether local or remote activity
  readonly workflowExecution: {
    readonly workflowId: string;
    readonly runId: string;
  };
  readonly workflowNamespace: string;
  readonly workflowType: string;
  readonly scheduledTimestampMs: number;
  readonly scheduleToCloseTimeoutMs: number;
  readonly startToCloseTimeoutMs: number;
  readonly currentAttemptScheduledTimestampMs: number;
  readonly heartbeatTimeoutMs?: number;
  readonly heartbeatDetails: any;             // Details from last heartbeat
  readonly taskQueue: string;
  readonly priority?: Priority;
  readonly retryPolicy?: RetryPolicy;
}
```

**Source:** `temporal-sdk-typescript/packages/activity/src/index.ts:128-225`

### 3. Worker Development

Create and configure Workers that execute Workflows and Activities.

**Key Topics:**
- Worker creation and configuration
- Worker lifecycle and states
- Registration requirements
- Production deployment (Docker, Kubernetes)
- Graceful shutdown
- Worker patterns (single vs. multiple workers)
- Temporal Cloud connection

**Reference:** See `references/workers.md` for comprehensive Worker guide

**Example: Production Worker with Pre-bundled Workflows**
```typescript
import { Worker } from '@temporalio/worker';
import * as activities from './activities';

const workflowOption = () =>
  process.env.NODE_ENV === 'production'
    ? { workflowBundle: { codePath: require.resolve('./workflow-bundle.js') } }
    : { workflowsPath: require.resolve('./workflows') };

async function run() {
  const worker = await Worker.create({
    ...workflowOption(),
    activities,
    taskQueue: 'production-queue',
    shutdownGraceTime: '5 minutes',
  });

  await worker.run();
}
```

### 4. Namespace Management

Configure and connect to Namespaces, which provide isolation units for Temporal applications.

**Key Topics:**
- Namespace basics and isolation boundaries
- Configuring namespace in Client and Worker
- Temporal Cloud namespace naming and endpoints
- Authentication methods (API keys and mTLS)
- Namespace organization best practices
- Multi-namespace patterns

**Reference:** See `references/namespaces.md` for comprehensive Namespace guide

**Example: Connecting to a Namespace**
```typescript
import { Client } from '@temporalio/client';
import { Worker } from '@temporalio/worker';

// Client connecting to specific namespace
const client = new Client({
  namespace: 'production-workflows',
});

// Worker polling from specific namespace
const worker = await Worker.create({
  namespace: 'production-workflows',
  taskQueue: 'my-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,
});
```

**Example: Connecting to Temporal Cloud**
```typescript
import { Client } from '@temporalio/client';
import fs from 'fs/promises';

// mTLS connection to Temporal Cloud
const client = new Client({
  namespace: 'accounting-production.f45a2',
  connection: {
    address: 'accounting-production.f45a2.tmprl.cloud:7233',
    tls: {
      clientCertPair: {
        crt: await fs.readFile('./client.pem'),
        key: await fs.readFile('./client-key.pem'),
      },
    },
  },
});

// API Key connection to Temporal Cloud (regional endpoint)
const clientWithApiKey = new Client({
  namespace: 'accounting-production.f45a2',
  connection: {
    address: 'us-west-2.aws.api.temporal.io:7233',
    tls: true,
    apiKey: process.env.TEMPORAL_API_KEY,
  },
});
```

### 5. Reusability Patterns

Implement patterns for long-running, complex, and reusable Workflows.

**Patterns Covered:**

**Child Workflows**: Decompose complex Workflows
```typescript
import { executeChild } from '@temporalio/workflow';

export async function parentWorkflow(orders: string[]): Promise<string[]> {
  const results = await Promise.all(
    orders.map(orderId => executeChild(orderWorkflow, { args: [orderId] }))
  );
  return results;
}
```

**Continue-As-New**: Reset Event History for long-running Workflows
```typescript
import * as wf from '@temporalio/workflow';

export async function longRunningWorkflow(state: State): Promise<void> {
  // Process work...

  if (wf.workflowInfo().continueAsNewSuggested) {
    await wf.continueAsNew<typeof longRunningWorkflow>(updatedState);
  }
}
```

**Entity Pattern**: Single-entity with updates and Continue-As-New
```typescript
export async function entityWorkflow(input: Input, isNew = true): Promise<void> {
  const pendingUpdates: Update[] = [];
  setHandler(updateSignal, (update) => pendingUpdates.push(update));

  for (let iteration = 1; iteration <= MAX_ITERATIONS; ++iteration) {
    await condition(() => pendingUpdates.length > 0, '1 day');
    while (pendingUpdates.length) {
      await processUpdate(pendingUpdates.shift());
    }
  }

  await continueAsNew<typeof entityWorkflow>(input, false);
}
```

**Reference:** See `references/workflows.md` section "Workflow Reusability Patterns"

### 6. Message Passing

Enable Workflow communication via Signals, Queries, and Updates.

**Message Types:**

**Queries**: Read Workflow state (synchronous, no mutations)
```typescript
export const getStatus = wf.defineQuery<Status>('getStatus');

wf.setHandler(getStatus, () => currentStatus);
```

**Signals**: Change Workflow state (asynchronous, no return value)
```typescript
export const approveSignal = wf.defineSignal<[string]>('approve');

wf.setHandler(approveSignal, (approver) => {
  approved = true;
  approvedBy = approver;
});
```

**Updates**: Change state and return value (synchronous with validation)
```typescript
export const setLanguage = wf.defineUpdate<Language, [Language]>('setLanguage');

wf.setHandler(
  setLanguage,
  (newLang) => {
    const prev = language;
    language = newLang;
    return prev;
  },
  {
    validator: (newLang) => {
      if (!(newLang in supportedLanguages)) {
        throw new Error('Unsupported language');
      }
    },
  }
);
```

**Reference:** See `references/workflows.md` section "Message Passing"

### 7. Testing Strategies

Test Workflows and Activities effectively with time-skipping and mocking.

**Testing Approaches:**

**Integration Tests with Time-Skipping** (Recommended)
```typescript
import { TestWorkflowEnvironment } from '@temporalio/testing';

let testEnv: TestWorkflowEnvironment;

beforeAll(async () => {
  testEnv = await TestWorkflowEnvironment.createTimeSkipping();
});

test('workflow with 1 day sleep', async () => {
  const worker = await Worker.create({
    connection: testEnv.nativeConnection,
    taskQueue: 'test',
    workflowsPath: require.resolve('./workflows'),
  });

  // Sleeps are automatically fast-forwarded!
  await worker.runUntil(
    testEnv.client.workflow.execute(myWorkflow, {
      workflowId: uuid(),
      taskQueue: 'test',
    })
  );
});
```

**Activity Isolation Testing**
```typescript
import { MockActivityEnvironment } from '@temporalio/testing';

test('test activity', async () => {
  const env = new MockActivityEnvironment();
  const result = await env.run(myActivity, 'input');
  expect(result).toBe('expected');
});
```

**Replay Testing for Determinism**
```typescript
test('replay workflow', async () => {
  const history = JSON.parse(await fs.readFile('./history.json'));
  await Worker.runReplayHistory(
    { workflowsPath: require.resolve('./workflows') },
    history
  );
});
```

**Reference:** See `references/best-practices.md` section "Testing Strategies"

### 8. Worker Performance Tuning

Optimize Worker configuration for production workloads.

**Key Configurations:**

**Poller Autoscaling** (Always Recommended)
```typescript
import { Worker, PollerBehavior } from '@temporalio/worker';

const worker = await Worker.create({
  taskQueue: 'my-queue',
  workflowsPath: require.resolve('./workflows'),
  activities,

  // Autoscaling pollers - RECOMMENDED
  workflowTaskPollerBehavior: PollerBehavior.autoscaling(),
  activityTaskPollerBehavior: PollerBehavior.autoscaling(),
  nexusTaskPollerBehavior: PollerBehavior.autoscaling(),
});
```

**Resource-Based Slot Suppliers**
```typescript
const worker = await Worker.create({
  // ... other options
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
  },
});
```

**Monitoring Metrics:**
- `worker_task_slots_available`: Slot capacity
- `workflow_task_schedule_to_start_latency`: Queue wait time
- Poll success rate: Over/under provisioning indicator

**Reference:** See `references/best-practices.md` section "Worker Performance Tuning"

### 9. Best Practices

Apply production-ready patterns for reliability and maintainability.

**Key Practices:**

**Workflow Design**
- Keep deterministic (no side effects, use Activities)
- Use Continue-As-New for long-running Workflows
- Wait for async handlers before completion
- Use meaningful Workflow IDs

**Activity Design**
- Make idempotent (safe to retry)
- Use appropriate timeouts
- Keep focused (single responsibility)
- Handle retryable vs non-retryable errors

**Error Handling**
- Distinguish error types
- Use `ApplicationFailure.nonRetryable()` appropriately
- Implement compensation logic

**Production Deployment**
- Bundle Workflows ahead of time
- Configure graceful shutdown
- Use mTLS for Temporal Cloud
- Monitor essential metrics

**Reference:** See `references/best-practices.md` for complete checklist

## Using the Reference Files

This skill includes six comprehensive reference documents:

### project-structure.md
**Use when:** Starting a new project or organizing existing code

**Contains:**
- Critical separation rules (Activities MUST be separate from Workflows)
- Recommended project structures (basic, medium, large/production)
- File organization patterns
- Worker registration patterns
- TypeScript configuration
- Common mistakes to avoid

**How to use:** Read FIRST when setting up a project or refactoring code organization. Understanding proper structure prevents major issues later.

### workflows.md
**Use when:** Creating or refactoring Workflows

**Contains:**
- Basic Workflow structure and parameters
- Deterministic constraints
- Child Workflows
- Continue-As-New pattern
- Entity Pattern
- Signals, Queries, and Updates
- Cancellation scopes
- Best practices

**How to use:** Read relevant sections when implementing specific Workflow patterns. The file is organized by topic for easy navigation.

### activities.md
**Use when:** Creating or refactoring Activities

**Contains:**
- Basic Activity structure
- Dependency injection pattern
- Async Activity completion
- Heartbeating and cancellation
- Local Activities
- Retry strategies
- Idempotency patterns
- Testing Activities

**How to use:** Reference when designing Activities that interact with external systems. Contains practical patterns and examples.

### workers.md
**Use when:** Creating Workers, deploying to production, or troubleshooting Worker issues

**Contains:**
- Worker lifecycle and states
- Worker configuration options
- Registration requirements (critical!)
- Docker deployment (with image recommendations)
- Graceful shutdown strategies
- Worker patterns (single vs. multiple workers)
- Temporal Cloud connection
- Common issues and solutions

**How to use:** Essential when setting up Workers or deploying to production. Read Docker section before containerizing. Use troubleshooting section when Workers aren't picking up tasks.

### namespaces.md
**Use when:** Configuring Namespaces, connecting to Temporal Cloud, or organizing multi-tenant applications

**Contains:**
- Namespace fundamentals and isolation boundaries
- Client and Worker namespace configuration
- Temporal Cloud namespace naming conventions
- gRPC endpoints and connection patterns
- Authentication methods (API keys and mTLS)
- Namespace organization best practices
- Multi-namespace patterns and use cases
- Rate limits and constraints

**How to use:** Reference when setting up connections to Temporal Cloud, organizing applications across namespaces, or implementing multi-tenant architectures. Essential for production deployments.

### best-practices.md
**Use when:** Testing, tuning performance, or preparing for production

**Contains:**
- Testing strategies (unit, integration, replay)
- Time-skipping test framework
- Worker performance tuning
- Slot suppliers and pollers
- Monitoring and metrics
- Production deployment checklist
- Security considerations

**How to use:** Consult when optimizing Worker configuration, writing tests, or deploying to production.

## Quick Start Guide

**Important:** Activities and Workflows MUST be in separate files. See `references/project-structure.md` for details.

### Step 1: Set Up Project

```bash
# Create new project
npx @temporalio/create@latest ./my-temporal-app

# Or add to existing project
npm install @temporalio/client @temporalio/worker @temporalio/workflow @temporalio/activity @temporalio/common
```

### Step 2: Create Activities (First!)

```typescript
// src/activities.ts
export async function greet(name: string): Promise<string> {
  return `Hello, ${name}`;
}
```

**Note:** Activities are in their own file and can access external systems.

### Step 3: Create a Workflow

```typescript
// src/workflows.ts
import { proxyActivities } from '@temporalio/workflow';
// ⚠️ IMPORTANT: Type-only import!
import type * as activities from './activities';

const { greet } = proxyActivities<typeof activities>({
  startToCloseTimeout: '1 minute',
});

export async function greetingWorkflow(name: string): Promise<string> {
  return await greet(name);
}
```

**Note:** Workflows use `import type` (not regular import) for Activities.

### Step 4: Create a Worker

```typescript
// src/worker.ts
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

### Step 5: Start a Workflow

```typescript
// src/client.ts
import { Client } from '@temporalio/client';
import { greetingWorkflow } from './workflows';

async function run() {
  const client = new Client();

  const result = await client.workflow.execute(greetingWorkflow, {
    workflowId: 'greeting-workflow-' + Date.now(),
    taskQueue: 'my-task-queue',
    args: ['Temporal'],
  });

  console.log(result); // "Hello, Temporal"
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

### Step 6: Run the Application

```bash
# Terminal 1: Start Temporal Server (development)
temporal server start-dev

# Terminal 2: Start Worker
npm run worker

# Terminal 3: Execute Workflow
npm run client
```

## Common Patterns

### Pattern: Saga with Compensation

```typescript
export async function bookTripWorkflow(trip: TripBooking): Promise<TripConfirmation> {
  const compensations: (() => Promise<void>)[] = [];

  try {
    const flight = await bookFlight(trip.flightDetails);
    compensations.push(() => cancelFlight(flight.id));

    const hotel = await bookHotel(trip.hotelDetails);
    compensations.push(() => cancelHotel(hotel.id));

    const car = await bookCar(trip.carDetails);
    compensations.push(() => cancelCar(car.id));

    return { flight, hotel, car };
  } catch (error) {
    // Run compensations in reverse order
    for (const compensate of compensations.reverse()) {
      await compensate();
    }
    throw error;
  }
}
```

### Pattern: Human-in-the-Loop

```typescript
import * as wf from '@temporalio/workflow';

const approvalSignal = wf.defineSignal<[boolean, string]>('approval');

export async function humanApprovalWorkflow(request: ApprovalRequest): Promise<string> {
  let approved = false;
  let approver = '';

  wf.setHandler(approvalSignal, (decision, name) => {
    approved = decision;
    approver = name;
  });

  // Send notification Activity
  await sendApprovalRequest(request);

  // Wait for approval (with timeout)
  const receivedApproval = await wf.condition(() => approved, '7 days');

  if (!receivedApproval) {
    throw new wf.ApplicationFailure('Approval timeout');
  }

  await processApprovedRequest(request);
  return `Approved by ${approver}`;
}
```

### Pattern: Periodic Job with Continue-As-New

```typescript
import * as wf from '@temporalio/workflow';

export async function periodicJobWorkflow(config: JobConfig): Promise<void> {
  for (let i = 0; i < 100; i++) {
    await runJob(config);
    await wf.sleep(config.intervalMs);

    if (wf.workflowInfo().continueAsNewSuggested) {
      await wf.continueAsNew<typeof periodicJobWorkflow>(config);
    }
  }

  await wf.continueAsNew<typeof periodicJobWorkflow>(config);
}
```

## Troubleshooting

### Issue: Non-Determinism Error

**Symptom:** `DeterminismViolationError` during replay
**Solution:** Remove non-deterministic code from Workflow:
- Use `wf.Date.now()` instead of `Date.now()`
- Move randomness to Activities
- Don't import Activity implementations into Workflows
- Use `wf.uuid()` for deterministic UUIDs

### Issue: High Schedule-to-Start Latency

**Symptom:** Tasks waiting long in queue
**Solutions:**
1. Enable poller autoscaling
2. Increase Worker executor slots
3. Add more Worker instances
4. Check for rate limiting

### Issue: Workflow Exceeding Event History Limit

**Symptom:** Warning about Event History size
**Solutions:**
1. Use Continue-As-New when `continueAsNewSuggested` is true
2. Reduce payload sizes
3. Limit number of iterations before Continue-As-New
4. Extract sub-processes into Child Workflows

## Additional Resources

- **TypeScript SDK API**: https://typescript.temporal.io
- **TypeScript Samples**: https://github.com/temporalio/samples-typescript
- **Temporal Documentation**: https://docs.temporal.io
- **Community Forum**: https://community.temporal.io

## Conclusion

Use the reference files as comprehensive guides for specific topics, and refer back to this SKILL.md for quick reference and common patterns. The three reference documents provide in-depth coverage of Workflows, Activities, and best practices that will guide you through any Temporal development task.
