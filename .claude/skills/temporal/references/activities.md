# Temporal Activity Development Guide

## Overview

Activities are functions that execute business logic with side effects, such as calling APIs, querying databases, or processing files. Unlike Workflows, Activities run in a normal execution environment and can make network calls, use non-deterministic operations, and access external resources.

## Creating Basic Activities

### Activity Definition

Activities are simple async functions:

```typescript
export async function greet(name: string): Promise<string> {
  return `👋 Hello, ${name}`;
}
```

**Key Characteristics:**
- Activities execute in the standard Node.js environment (not sandboxed)
- Activities cannot be in the same file as Workflows
- Activities must be separately registered with Workers
- Activities may be retried repeatedly - design them to be **idempotent**
- Activities can be long-running (hours, days, or more)

### Activity Parameters

- **No explicit limit** on parameter count, but practical limits exist:
  - Single argument limited to 2MB
  - Total gRPC message size limited to 4MB
- **Recommendation**: Use a single object parameter for flexibility

```typescript
interface CreateUserInput {
  email: string;
  name: string;
  preferences?: UserPreferences;
}

export async function createUser(input: CreateUserInput): Promise<User> {
  // Activity implementation
  const user = await database.users.create(input);
  return user;
}
```

### Activity Return Values

- Must be serializable
- Subject to payload size limits (2MB default, 4MB hard limit)
- All return values are recorded in Event History
- Return type is always `Promise<T>`

```typescript
export async function processPayment(amount: number): Promise<PaymentResult> {
  const result = await paymentService.charge(amount);
  return {
    transactionId: result.id,
    status: result.status,
  };
}
```

### Customizing Activity Type (Name)

Customize the Activity name when registering with the Worker:

```typescript
import { Worker } from '@temporalio/worker';
import { greet } from './activities';

const worker = await Worker.create({
  workflowsPath: require.resolve('./workflows'),
  taskQueue: 'my-queue',
  activities: {
    activityFoo: greet,  // Activity Type is "activityFoo"
  },
});
```

## Calling Activities from Workflows

Activities are never called directly from Workflows. Instead, use `proxyActivities`:

```typescript
import { proxyActivities } from '@temporalio/workflow';
// ✅ Import Activity TYPES only, not implementations
import type * as activities from './activities';

const { greet, processPayment } = proxyActivities<typeof activities>({
  startToCloseTimeout: '1 minute',
});

export async function myWorkflow(name: string): Promise<string> {
  const greeting = await greet(name);
  await processPayment(100);
  return greeting;
}
```

**Important:**
- Import Activity **types only** (`import type`)
- Never import Activity implementations into Workflow code
- `proxyActivities()` returns a proxy object with type-safe Activity stubs
- Activities are scheduled as Tasks, not executed directly

### Activity Timeouts

At minimum, set either `startToCloseTimeout` or `scheduleToCloseTimeout`:

```typescript
const activities = proxyActivities<typeof acts>({
  startToCloseTimeout: '30 seconds',
  // or scheduleToCloseTimeout: '5 minutes',
});
```

**Timeout Types:**
- **Schedule-To-Start**: Time from scheduling to Worker pickup
- **Start-To-Close**: Time from start to completion
- **Schedule-To-Close**: Total time from scheduling to completion
- **Heartbeat**: Maximum time between heartbeats

## Activity Design Patterns

### 1. Dependency Injection (Sharing Resources)

Use closures to inject dependencies like database connections:

```typescript
// activities.ts
export interface DB {
  get(key: string): Promise<string>;
}

export const createActivities = (db: DB) => ({
  async greet(msg: string): Promise<string> {
    const name = await db.get('name');
    return `${msg}: ${name}`;
  },

  async greet_es(mensaje: string): Promise<string> {
    const name = await db.get('name');
    return `${mensaje}: ${name}`;
  },
});
```

```typescript
// worker.ts
import { createActivities } from './activities';

const db = {
  async get(_key: string) {
    return 'Temporal';
  },
};

const worker = await Worker.create({
  taskQueue: 'my-queue',
  workflowsPath: require.resolve('./workflows'),
  activities: createActivities(db),
});
```

```typescript
// workflow.ts
import type { createActivities } from './activities';
import { proxyActivities } from '@temporalio/workflow';

// Use ReturnType generic since createActivities is a factory
const { greet, greet_es } = proxyActivities<ReturnType<typeof createActivities>>({
  startToCloseTimeout: '30 seconds',
});
```

**Benefits:**
- Share expensive resources (DB connections, clients)
- Inject secrets from environment variables
- Easier testing with mocked dependencies

### 2. Importing Multiple Activities

Import multiple Activities with shared configuration:

```typescript
import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

export async function myWorkflow(name: string): Promise<string> {
  const { act1, act2, act3 } = proxyActivities<typeof activities>({
    startToCloseTimeout: '1 minute',
  });

  await act1();
  await Promise.all([act2(), act3()]);
  return 'done';
}
```

### 3. Dynamic Activity References

Activities are referenced by string names, allowing dynamic invocation:

```typescript
import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

export async function dynamicWorkflow(activityName: string, ...args: any[]) {
  const acts = proxyActivities<typeof activities>({
    startToCloseTimeout: '1 minute',
  });

  // Dynamic reference to activities
  const result = await acts[activityName](...args);
  return result;
}
```

**Note:** Invalid Activity names lead to `NotFoundError` with message like:
```
ApplicationFailure: Activity function actC is not registered on this Worker,
available activities: ["actA", "actB"]
```

### 4. Asynchronous Activity Completion

For long-running operations handled by external systems:

```typescript
import { CompleteAsyncError, activityInfo } from '@temporalio/activity';
import { AsyncCompletionClient } from '@temporalio/client';

export async function doSomethingAsync(): Promise<string> {
  const taskToken = activityInfo().taskToken;

  // Pass token to external system
  setTimeout(() => doSomeWork(taskToken), 1000);

  // Signal that completion will happen externally
  throw new CompleteAsyncError();
}

// This could run in a different process/machine
async function doSomeWork(taskToken: Uint8Array): Promise<void> {
  const client = new AsyncCompletionClient();

  // ... perform work ...

  // Complete the Activity
  await client.complete(taskToken, "Job is done");
}
```

**Use Cases:**
- Human-in-the-loop workflows (approval systems)
- External system callbacks
- Long-running batch jobs
- Decoupled processing pipelines

### 5. Activity Heartbeating

For long-running Activities, send heartbeats to indicate progress:

```typescript
import { heartbeat, activityInfo } from '@temporalio/activity';

export async function processLargeFile(filePath: string): Promise<void> {
  const lines = await readFileLines(filePath);
  const total = lines.length;

  for (let i = 0; i < total; i++) {
    await processLine(lines[i]);

    // Send heartbeat with progress
    heartbeat({ processed: i + 1, total });
  }
}
```

**Benefits:**
- Worker can detect if Activity is stuck
- Enables faster retry on Worker crashes
- Provides progress information
- Supports Activity resumption with last heartbeat details

### 6. Activity Cancellation

Handle cancellation gracefully:

```typescript
import { CancelledFailure, isCancellation } from '@temporalio/activity';
import { Context } from '@temporalio/activity';

export async function cancellableActivity(): Promise<string> {
  try {
    // Check if cancelled
    if (Context.current().cancellationSignal.aborted) {
      throw new CancelledFailure('Activity was cancelled');
    }

    await someOperation();

    // Listen for cancellation
    Context.current().cancellationSignal.addEventListener('abort', () => {
      // Cleanup logic
      console.log('Cancellation requested');
    });

    return 'completed';
  } catch (err) {
    if (isCancellation(err)) {
      // Handle cancellation-specific cleanup
      await cleanup();
    }
    throw err;
  }
}
```

## Local Activities

Local Activities are optimized for very short operations (< 1 second):

```typescript
import * as workflow from '@temporalio/workflow';

const { getEnvVar } = workflow.proxyLocalActivities({
  startToCloseTimeout: '2 seconds',
});

export async function yourWorkflow(): Promise<void> {
  const someSetting = await getEnvVar('SOME_SETTING');
  // ...
}
```

**Characteristics:**
- Execute in same Worker process as Workflow
- No queueing delay
- Limited retry capability
- Best for: reading env vars, quick calculations, local cache access
- Must be registered with Worker like regular Activities

**When to Use:**
- Operations < 1 second
- No network calls required
- Low importance operations (limited retries)
- Need minimal latency

**When NOT to Use:**
- Operations > 1 second
- Network calls or external dependencies
- Need robust retry mechanisms

## Activity Retry Strategies

Activities can be retried automatically:

```typescript
const activities = proxyActivities<typeof acts>({
  startToCloseTimeout: '30 seconds',
  retry: {
    initialInterval: '1s',
    maximumInterval: '60s',
    backoffCoefficient: 2,
    maximumAttempts: 5,
  },
});
```

**Retry Parameters:**
- `initialInterval`: First retry delay
- `maximumInterval`: Maximum retry delay
- `backoffCoefficient`: Multiplier for exponential backoff
- `maximumAttempts`: Max retry count (0 = infinite)

## Activity Best Practices

### 1. Idempotency

Design Activities to be safely retried:

```typescript
export async function createUser(input: CreateUserInput): Promise<User> {
  // ✅ Check if user already exists (idempotent)
  const existing = await db.users.findByEmail(input.email);
  if (existing) {
    return existing;
  }

  // Create only if doesn't exist
  return await db.users.create(input);
}
```

**Why?** Activities may be retried due to:
- Timeouts
- Worker crashes
- Transient errors
- Workflow replays

### 2. Error Handling

Distinguish between retryable and non-retryable errors:

```typescript
import { ApplicationFailure } from '@temporalio/common';

export async function chargeCard(amount: number): Promise<void> {
  try {
    await paymentGateway.charge(amount);
  } catch (error) {
    if (error.code === 'INSUFFICIENT_FUNDS') {
      // ❌ Non-retryable - throw ApplicationFailure
      throw ApplicationFailure.nonRetryable(
        'Insufficient funds',
        'InsufficientFunds'
      );
    }

    // ✅ Retryable - rethrow for automatic retry
    throw error;
  }
}
```

### 3. Keep Activities Focused

One Activity should do one thing:

```typescript
// ❌ Bad: Multiple responsibilities
export async function processOrder(orderId: string) {
  await validateOrder(orderId);
  await chargePayment(orderId);
  await updateInventory(orderId);
  await sendConfirmationEmail(orderId);
}

// ✅ Good: Separate Activities
export async function validateOrder(orderId: string) { /* ... */ }
export async function chargePayment(orderId: string) { /* ... */ }
export async function updateInventory(orderId: string) { /* ... */ }
export async function sendConfirmationEmail(orderId: string) { /* ... */ }
```

**Benefits:**
- Easier to test
- Better retry granularity
- Clear failure boundaries
- Reusable across Workflows

### 4. Appropriate Timeouts

Set realistic timeouts based on Activity characteristics:

```typescript
// Quick API call
const { getUserProfile } = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 seconds',
});

// File processing
const { processFile } = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 minutes',
  heartbeatTimeout: '30 seconds',
});

// External callback
const { waitForApproval } = proxyActivities<typeof activities>({
  scheduleToCloseTimeout: '7 days',
  heartbeatTimeout: '1 day',
});
```

### 5. Payload Size Management

Keep Activity inputs and outputs small:

```typescript
// ❌ Bad: Large payload in Event History
export async function processData(data: LargeDataset): Promise<LargeResult> {
  return analyze(data); // MB of data in history!
}

// ✅ Good: Pass references
export async function processData(dataUrl: string): Promise<ResultUrl> {
  const data = await fetchFromStorage(dataUrl);
  const result = await analyze(data);
  const resultUrl = await saveToStorage(result);
  return { resultUrl };
}
```

### 6. Testing Activities

Activities can be tested in isolation:

```typescript
import { MockActivityEnvironment } from '@temporalio/testing';

test('greet activity', async () => {
  const env = new MockActivityEnvironment();

  const result = await env.run(greet, 'World');

  expect(result).toBe('Hello, World');
});

test('activity with heartbeat', async () => {
  const env = new MockActivityEnvironment();

  env.on('heartbeat', (details) => {
    expect(details.progress).toBeGreaterThan(0);
  });

  await env.run(processLargeFile, 'test.txt');
});
```

## Common Patterns Summary

| Pattern | Use Case | Key Benefit |
|---------|----------|-------------|
| Dependency Injection | Shared resources (DB, API clients) | Resource efficiency, testability |
| Async Completion | External callbacks, human approvals | Decouple execution from completion |
| Heartbeating | Long-running operations | Progress tracking, faster failure detection |
| Local Activities | Quick local operations | Minimal latency |
| Idempotent Design | All Activities | Safe retry behavior |
| Focused Activities | Single responsibility | Clarity, reusability |

## Registration and Execution Flow

1. **Define** Activity functions in separate file
2. **Register** Activities with Worker
3. **Import types** in Workflow (not implementations)
4. **Create proxy** with `proxyActivities()`
5. **Call** Activity through proxy
6. **Schedule** Activity Task in Temporal
7. **Execute** Activity when Worker picks up Task
8. **Record** result in Event History
9. **Resume** Workflow with result
