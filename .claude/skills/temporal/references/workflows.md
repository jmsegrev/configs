# Temporal Workflow Development Guide

## Overview

Workflows are the fundamental building blocks of Temporal applications. They orchestrate Activities and other operations while maintaining durability and determinism.

## Creating Basic Workflows

### Workflow Definition

In TypeScript, Workflows are just async functions that can orchestrate Activities and maintain state:

```typescript
import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const { greet } = proxyActivities<typeof activities>({
  startToCloseTimeout: '1 minute',
});

export async function example(args: { name: string }): Promise<{ greeting: string }> {
  const greeting = await greet(args.name);
  return { greeting };
}
```

**Key Points:**
- Workflows are async functions
- Use a single object parameter for flexibility
- Import Activity **types only**, not implementations
- Activity calls are proxied through `proxyActivities()`

### Workflow Parameters and Return Values

- **Parameters**: Use object parameters for extensibility without breaking signatures
- **Return Values**: Must be serializable; return `Promise<T>` where T is serializable
- All parameters and return values are limited by payload size (2MB default, 4MB hard limit)

```typescript
interface WorkflowInput {
  userId: string;
  orderData: OrderData;
}

export async function processOrder(input: WorkflowInput): Promise<string> {
  // Workflow logic
  return `Order processed for user ${input.userId}`;
}
```

### Workflow Type

The Workflow Type (name) is the function name itself in TypeScript. There's no mechanism to customize it.

```typescript
export async function helloWorld(): Promise<string> {
  return '👋 Hello World';
}
// Workflow Type is "helloWorld"
```

## Deterministic Constraints

### The Workflow Sandbox

Workflows run in a **deterministic sandbox** with these characteristics:

- Bundled on Worker creation using Webpack
- Can import packages that don't reference Node.js or DOM APIs
- Cannot directly perform side effects or access external state
- Functions like `Math.random()`, `Date`, `setTimeout()` are replaced with deterministic versions
- `FinalizationRegistry` and `WeakRef` are removed (garbage collector is non-deterministic)

### Date Behavior Example

```typescript
import { sleep } from '@temporalio/workflow';

// ❌ This prints the EXACT same timestamp repeatedly
for (let x = 0; x < 10; ++x) {
  console.log(Date.now());
}

// ✅ This prints timestamps increasing roughly 1s each iteration
for (let x = 0; x < 10; ++x) {
  await sleep('1 second');
  console.log(Date.now());
}
```

### What Cannot Be Done in Workflows

- Cannot use Node.js or DOM APIs directly
- Cannot make network calls directly (use Activities)
- Cannot read/write files directly (use Activities)
- Cannot directly import Activity implementations
- Cannot use non-deterministic operations (random, current time, etc.)

## Workflow Reusability Patterns

### 1. Child Workflows

Child Workflows allow you to decompose complex workflows into smaller, reusable pieces.

```typescript
import { executeChild, startChild } from '@temporalio/workflow';

// Execute and wait for completion
export async function parentWorkflow(...names: string[]): Promise<string> {
  const responseArray = await Promise.all(
    names.map((name) =>
      executeChild(childWorkflow, {
        args: [name],
        // Optional: workflowId, cancellationType, parentClosePolicy
      }),
    ),
  );
  return responseArray.join('\n');
}

// Start and get handle for later interaction
export async function parentWithHandle(name: string) {
  const childHandle = await startChild(childWorkflow, {
    args: [name],
  });

  // Can signal or query the child
  await childHandle.signal('anySignal');
  const result = await childHandle.result();
  return result;
}
```

**Parent Close Policy**: Controls what happens to child when parent closes
- `TERMINATE` (default): Child is terminated
- `ABANDON`: Child continues independently
- `REQUEST_CANCEL`: Child receives cancellation request

### 2. Continue-As-New

Continue-As-New allows a Workflow to close and start a new execution with a fresh Event History, maintaining the same Workflow ID.

**When to Use:**
- Long-running workflows that might hit Event History limits
- Check `workflowInfo().continueAsNewSuggested` to know when to Continue-As-New

```typescript
import * as wf from '@temporalio/workflow';

export interface ClusterManagerInput {
  state?: ClusterManagerState;
}

export async function clusterManagerWorkflow(
  input: ClusterManagerInput = {}
): Promise<ClusterManagerStateSummary> {
  const state = input.state ?? initializeState();

  // ... workflow logic ...

  if (wf.workflowInfo().continueAsNewSuggested) {
    // ✅ Continue-As-New from main workflow function
    return await wf.continueAsNew<typeof clusterManagerWorkflow>({
      state: getCurrentState(),
    });
  }

  return summary;
}
```

**Important Constraints:**
- ❌ Do NOT call Continue-As-New from Update or Signal handlers
- ✅ Wait for all handlers to finish before Continue-As-New
- Use `await wf.condition(wf.allHandlersFinished)` to ensure handlers complete

### 3. Entity Pattern (Single-Entity Design)

The Entity Pattern represents a single long-lived entity that processes updates over time and uses Continue-As-New properly.

```typescript
import { setHandler, defineSignal, condition, continueAsNew } from '@temporalio/workflow';

interface Input {
  entityId: string;
}

interface Update {
  type: string;
  data: any;
}

const updateSignal = defineSignal<[Update]>('update');
const MAX_ITERATIONS = 1000;

export async function entityWorkflow(
  input: Input,
  isNew = true,
): Promise<void> {
  const pendingUpdates: Update[] = [];

  setHandler(updateSignal, (update) => {
    pendingUpdates.push(update);
  });

  if (isNew) {
    await setup(input);
  }

  for (let iteration = 1; iteration <= MAX_ITERATIONS; ++iteration) {
    // Wait for updates but don't block forever
    await condition(() => pendingUpdates.length > 0, '1 day');

    while (pendingUpdates.length) {
      const update = pendingUpdates.shift();
      await processUpdate(update);
    }
  }

  // Continue-As-New to reset history
  await continueAsNew<typeof entityWorkflow>(input, false);
}
```

## Message Passing (Signals, Queries, Updates)

### Queries: Read Workflow State

Queries are synchronous read operations that cannot mutate state.

```typescript
import * as wf from '@temporalio/workflow';

interface GetLanguagesInput {
  includeUnsupported: boolean;
}

export const getLanguages = wf.defineQuery<Language[], [GetLanguagesInput]>('getLanguages');

export async function greetingWorkflow(): Promise<string> {
  const greetings: Record<Language, string> = {
    [Language.ENGLISH]: 'Hello, world',
    [Language.CHINESE]: '你好，世界',
  };

  wf.setHandler(getLanguages, (input: GetLanguagesInput): Language[] => {
    // ❌ Cannot be async, cannot mutate state
    // ✅ Can read state and return values
    if (input.includeUnsupported) {
      return Object.values(Language);
    }
    return Object.keys(greetings) as Language[];
  });

  // ... workflow logic
}
```

### Signals: Asynchronous State Mutation

Signals change workflow state asynchronously without returning values.

```typescript
import * as wf from '@temporalio/workflow';

interface ApproveInput {
  name: string;
}

export const approve = wf.defineSignal<[ApproveInput]>('approve');

export async function greetingWorkflow(): Promise<string> {
  let approvedForRelease = false;
  let approverName: string | undefined;

  wf.setHandler(approve, (input) => {
    // ✅ Can mutate state
    // ❌ Cannot return value
    approvedForRelease = true;
    approverName = input.name;
  });

  // Wait for approval
  await wf.condition(() => approvedForRelease);

  return `Approved by ${approverName}`;
}
```

### Updates: Synchronous State Mutation with Return

Updates combine features of Signals and Queries: they can mutate state AND return values.

```typescript
import * as wf from '@temporalio/workflow';

export const setLanguage = wf.defineUpdate<Language, [Language]>('setLanguage');

export async function greetingWorkflow(): Promise<string> {
  const greetings: Partial<Record<Language, string>> = {
    [Language.ENGLISH]: 'Hello, world',
  };
  let language = Language.ENGLISH;

  wf.setHandler(
    setLanguage,
    (newLanguage: Language) => {
      // ✅ Can mutate state AND return value
      const previousLanguage = language;
      language = newLanguage;
      return previousLanguage;
    },
    {
      validator: (newLanguage: Language) => {
        // ✅ Optional validator to reject Updates before writing to history
        if (!(newLanguage in greetings)) {
          throw new Error(`${newLanguage} is not supported`);
        }
      },
    }
  );

  // ... workflow logic
}
```

### Async Handlers

Signal and Update handlers can be `async`, enabling Activities, Child Workflows, and Timers:

```typescript
import { Mutex } from 'async-mutex';

const lock = new Mutex();

wf.setHandler(setLanguageUsingActivity, async (newLanguage) => {
  // Use lock to prevent concurrent handler execution issues
  await lock.runExclusive(async () => {
    if (!(newLanguage in greetings)) {
      const greeting = await callGreetingService(newLanguage);
      if (!greeting) {
        throw new wf.ApplicationFailure(`${newLanguage} not supported`);
      }
      greetings[newLanguage] = greeting;
    }
  });

  const previousLanguage = language;
  language = newLanguage;
  return previousLanguage;
});
```

### Wait for Handlers to Finish

Ensure handlers complete before workflow ends:

```typescript
export async function myWorkflow(): Promise<Output> {
  // ... workflow logic with async handlers ...

  // Wait for all handlers to finish before returning
  await wf.condition(wf.allHandlersFinished);
  return workflowOutput;
}
```

## Cancellation Scopes

Workflows use cancellation scopes to manage cancellation of Activities, Timers, and Child Workflows.

```typescript
import { CancellationScope, sleep, CancelledFailure } from '@temporalio/workflow';

// Automatic cancellation
try {
  await CancellationScope.cancellable(async () => {
    const promise = sleep(1000);
    CancellationScope.current().cancel();
    await promise; // Throws CancelledFailure
  });
} catch (e) {
  if (e instanceof CancelledFailure) {
    console.log('Timer cancelled');
  }
}

// Non-cancellable cleanup
try {
  await httpPostJSON(url, data);
} catch (err) {
  if (isCancellation(err)) {
    // Cleanup must run in nonCancellable scope
    await CancellationScope.nonCancellable(() => cleanup(url));
  }
  throw err;
}

// Timeout scope
await CancellationScope.withTimeout(5000, () =>
  Promise.all(urls.map((url) => httpGetJSON(url)))
);
```

## Starting Workflows

```typescript
import { Client } from '@temporalio/client';

const client = new Client();

// Start and wait for result
const result = await client.workflow.execute(example, {
  workflowId: 'business-meaningful-id',
  taskQueue: 'your-task-queue',
  args: [{ name: 'Temporal' }],
});

// Start and get handle immediately
const handle = await client.workflow.start(example, {
  workflowId: 'business-meaningful-id',
  taskQueue: 'your-task-queue',
  args: [{ name: 'Temporal' }],
});

const result = await handle.result();
```

## Best Practices

1. **Use object parameters** for workflows to allow adding fields without breaking signatures
2. **Keep Event History small** - large histories affect Worker performance
3. **Use Continue-As-New** for long-running workflows before hitting history limits
4. **Wait for handlers** before workflow completion or Continue-As-New
5. **Use locks** when async handlers need to access shared state safely
6. **Avoid large payloads** - keep under 2MB, activities and results are in Event History
7. **Make workflows deterministic** - all side effects must go through Activities
8. **Use Child Workflows** to decompose complex workflows
9. **Test with time-skipping** to verify long-running workflow logic quickly
