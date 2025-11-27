# Temporal Project Structure Guide

## Why Code Organization Matters

Temporal applications have **strict separation requirements** between Workflows and Activities due to their different execution environments:

- **Workflows** run in a deterministic sandbox with limited capabilities
- **Activities** run in the standard Node.js environment with full access

This fundamental difference dictates how code must be organized.

## Critical Rules

### 1. Activities Cannot Be in the Same File as Workflows

**Reason:** Activities and Workflows run in completely different execution contexts.

```typescript
// ❌ WRONG - Do not do this
// workflows.ts
export async function myWorkflow() {
  await myActivity(); // Activity in same file
}

export async function myActivity() {
  // This won't work!
}
```

```typescript
// ✅ CORRECT - Separate files
// workflows.ts
import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities'; // Type-only import!

const { myActivity } = proxyActivities<typeof activities>({
  startToCloseTimeout: '1 minute',
});

export async function myWorkflow() {
  await myActivity();
}

// activities.ts
export async function myActivity() {
  // Activity implementation
}
```

### 2. Workflows Import Activity Types Only

**Reason:** Workflow code is bundled separately and cannot contain Activity implementations.

```typescript
// ❌ WRONG - Importing actual Activity code
import * as activities from './activities';

// ✅ CORRECT - Type-only import
import type * as activities from './activities';
```

**Why `import type`?**
- Ensures no Activity implementation code enters the Workflow bundle
- TypeScript removes type imports at compile time
- Provides type safety without runtime imports
- Prevents accidentally calling Activities directly

## Recommended Project Structure

### Basic Structure

```
my-temporal-app/
├── src/
│   ├── activities.ts          # Activity definitions
│   ├── workflows.ts           # Workflow definitions
│   ├── worker.ts              # Worker process
│   └── client.ts              # Client to start workflows
├── package.json
└── tsconfig.json
```

**Explanation:**
- `activities.ts`: All Activity functions (can interact with external systems)
- `workflows.ts`: All Workflow functions (deterministic, orchestration logic)
- `worker.ts`: Worker that polls for and executes tasks
- `client.ts`: Client code that starts Workflow Executions

### Medium Project Structure

As projects grow, organize by feature or domain:

```
my-temporal-app/
├── src/
│   ├── activities/
│   │   ├── index.ts           # Re-exports all activities
│   │   ├── orders.ts          # Order-related activities
│   │   ├── payments.ts        # Payment activities
│   │   └── notifications.ts   # Notification activities
│   │
│   ├── workflows/
│   │   ├── index.ts           # Re-exports all workflows
│   │   ├── order-processing.ts
│   │   ├── payment-processing.ts
│   │   └── notification-workflows.ts
│   │
│   ├── workers/
│   │   ├── order-worker.ts    # Worker for order queue
│   │   └── payment-worker.ts  # Worker for payment queue
│   │
│   ├── clients/
│   │   ├── start-order.ts     # Start order workflows
│   │   └── start-payment.ts   # Start payment workflows
│   │
│   └── common/
│       ├── types.ts           # Shared TypeScript types
│       └── constants.ts       # Shared constants
│
├── package.json
└── tsconfig.json
```

**Explanation:**
- **activities/**: Grouped by domain, with `index.ts` re-exporting
- **workflows/**: Grouped by domain, with `index.ts` re-exporting
- **workers/**: Separate Workers for different Task Queues
- **clients/**: Client code to start different Workflow types
- **common/**: Shared types and constants (can be imported anywhere)

### Large/Production Project Structure

For large-scale applications with multiple services:

```
my-temporal-app/
├── packages/
│   ├── workflows/             # Workflow package
│   │   ├── src/
│   │   │   ├── orders/
│   │   │   │   ├── order-processing.ts
│   │   │   │   └── order-fulfillment.ts
│   │   │   ├── payments/
│   │   │   │   └── payment-processing.ts
│   │   │   └── index.ts
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── activities/            # Activities package
│   │   ├── src/
│   │   │   ├── orders/
│   │   │   │   ├── create-order.ts
│   │   │   │   └── update-inventory.ts
│   │   │   ├── payments/
│   │   │   │   ├── charge-card.ts
│   │   │   │   └── process-refund.ts
│   │   │   └── index.ts
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── workers/               # Workers package
│   │   ├── src/
│   │   │   ├── order-worker.ts
│   │   │   ├── payment-worker.ts
│   │   │   └── shared-config.ts
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── clients/               # Client package
│   │   ├── src/
│   │   │   └── temporal-client.ts
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   └── common/                # Shared types package
│       ├── src/
│       │   ├── types.ts
│       │   └── constants.ts
│       ├── package.json
│       └── tsconfig.json
│
├── package.json               # Root package.json (monorepo)
├── lerna.json                 # Lerna config (or use npm workspaces)
└── tsconfig.base.json         # Base TypeScript config
```

**Benefits:**
- **Clear boundaries**: Each package has a single responsibility
- **Independent versioning**: Can version packages separately
- **Easier testing**: Test packages in isolation
- **Better reusability**: Shared packages across services
- **Scalability**: Teams can own specific packages

## File Organization Patterns

### Pattern 1: Single File Per Domain

```typescript
// activities/orders.ts
export interface Database {
  query(sql: string): Promise<any>;
}

export const createOrderActivities = (db: Database) => ({
  async createOrder(orderData: OrderData): Promise<Order> {
    // Implementation
  },

  async updateOrder(orderId: string, updates: Partial<Order>): Promise<Order> {
    // Implementation
  },

  async cancelOrder(orderId: string): Promise<void> {
    // Implementation
  },
});
```

```typescript
// workflows/orders.ts
import { proxyActivities } from '@temporalio/workflow';
import type { createOrderActivities } from '../activities/orders';

const { createOrder, updateOrder } = proxyActivities<ReturnType<typeof createOrderActivities>>({
  startToCloseTimeout: '5 minutes',
});

export async function orderWorkflow(orderData: OrderData): Promise<Order> {
  const order = await createOrder(orderData);
  // More workflow logic
  return order;
}
```

### Pattern 2: One File Per Activity/Workflow

```
activities/
├── create-order.ts
├── update-order.ts
├── cancel-order.ts
└── index.ts (re-exports all)

workflows/
├── order-processing.ts
├── order-fulfillment.ts
├── order-cancellation.ts
└── index.ts (re-exports all)
```

**Use when:**
- Activities/Workflows are complex and large
- Want maximum separation of concerns
- Need fine-grained code ownership

### Pattern 3: Grouped by Feature

```
src/
├── orders/
│   ├── activities.ts
│   ├── workflows.ts
│   └── types.ts
├── payments/
│   ├── activities.ts
│   ├── workflows.ts
│   └── types.ts
└── shared/
    ├── activities.ts
    ├── workflows.ts
    └── types.ts
```

**Use when:**
- Features are relatively independent
- Team organized by feature
- Want to keep related code together

## Worker Registration Patterns

### Pattern 1: Single Worker, All Activities and Workflows

```typescript
// worker.ts
import { Worker } from '@temporalio/worker';
import * as activities from './activities';

const worker = await Worker.create({
  workflowsPath: require.resolve('./workflows'),
  activities,
  taskQueue: 'default-queue',
});
```

**Use when:**
- Small to medium applications
- Single deployment unit
- All workflows can run on same Workers

### Pattern 2: Multiple Workers, Specialized Task Queues

```typescript
// workers/order-worker.ts
import { Worker } from '@temporalio/worker';
import * as orderActivities from '../activities/orders';

const worker = await Worker.create({
  workflowsPath: require.resolve('../workflows/orders'),
  activities: orderActivities,
  taskQueue: 'order-processing',
});

// workers/payment-worker.ts
import { Worker } from '@temporalio/worker';
import * as paymentActivities from '../activities/payments';

const worker = await Worker.create({
  workflowsPath: require.resolve('../workflows/payments'),
  activities: paymentActivities,
  taskQueue: 'payment-processing',
});
```

**Use when:**
- Different scaling requirements
- Different resource needs (CPU, memory, external services)
- Want to isolate failures
- Different deployment schedules

### Pattern 3: Worker Factory Pattern

```typescript
// workers/worker-factory.ts
import { Worker } from '@temporalio/worker';

export interface WorkerConfig {
  taskQueue: string;
  workflowsPath: string;
  activities: Record<string, Function>;
  maxConcurrentActivityExecutionSize?: number;
}

export async function createWorker(config: WorkerConfig): Promise<Worker> {
  return Worker.create({
    workflowsPath: config.workflowsPath,
    activities: config.activities,
    taskQueue: config.taskQueue,
    maxConcurrentActivityExecutionSize: config.maxConcurrentActivityExecutionSize ?? 100,
    // Other shared configuration
  });
}

// workers/start-workers.ts
import { createWorker } from './worker-factory';
import * as orderActivities from '../activities/orders';
import * as paymentActivities from '../activities/payments';

async function startWorkers() {
  const workers = await Promise.all([
    createWorker({
      taskQueue: 'orders',
      workflowsPath: require.resolve('../workflows/orders'),
      activities: orderActivities,
    }),
    createWorker({
      taskQueue: 'payments',
      workflowsPath: require.resolve('../workflows/payments'),
      activities: paymentActivities,
    }),
  ]);

  await Promise.all(workers.map(w => w.run()));
}
```

**Use when:**
- Many Workers with similar configuration
- Need centralized Worker configuration
- Want consistent Worker setup across services

## Index File Patterns

### Re-exporting Activities

```typescript
// activities/index.ts
export * from './orders';
export * from './payments';
export * from './notifications';
```

Then in workflows:

```typescript
// workflows/order-processing.ts
import { proxyActivities } from '@temporalio/workflow';
import type * as activities from '../activities'; // All activities

const acts = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
});
```

### Selective Re-exporting

```typescript
// activities/index.ts
export {
  createOrder,
  updateOrder,
  cancelOrder,
} from './orders';

export {
  chargeCard,
  processRefund,
} from './payments';

// Don't export internal helper functions
```

## TypeScript Configuration

### Basic tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "moduleResolution": "node",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./lib",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "lib"]
}
```

### Monorepo tsconfig.base.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "moduleResolution": "node",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "composite": true,
    "incremental": true
  }
}
```

## Common Mistakes to Avoid

### ❌ Mistake 1: Importing Activity Implementations in Workflows

```typescript
// ❌ WRONG
import { createOrder } from './activities';

export async function orderWorkflow() {
  await createOrder(); // Direct call - will fail!
}
```

**Fix:** Use `proxyActivities` and type-only imports

### ❌ Mistake 2: Putting Activities and Workflows in Same File

```typescript
// ❌ WRONG - all-in-one.ts
export async function myWorkflow() {
  await myActivity();
}

export async function myActivity() {
  // Won't work - different execution environments!
}
```

**Fix:** Separate into different files

### ❌ Mistake 3: Importing Workflow Code in Activities

```typescript
// ❌ WRONG - activities.ts
import { orderWorkflow } from './workflows';

export async function processOrder() {
  // Don't import workflow code into activities!
  // Use Client to start workflows instead
}
```

**Fix:** Use Temporal Client to start workflows from activities

### ❌ Mistake 4: Circular Dependencies

```typescript
// ❌ WRONG
// workflows.ts imports from activities.ts
// activities.ts imports from workflows.ts
// Creates circular dependency!
```

**Fix:** Use shared types file for common interfaces

## Best Practices Summary

1. ✅ **Always separate Activities and Workflows into different files**
2. ✅ **Use `import type` for Activity imports in Workflows**
3. ✅ **Use index files to re-export from feature directories**
4. ✅ **Group related Activities/Workflows by domain**
5. ✅ **Use dependency injection for Activity dependencies**
6. ✅ **Keep shared types in a common directory**
7. ✅ **Use multiple Workers for different Task Queues**
8. ✅ **Register only necessary Activities with each Worker**
9. ✅ **Use meaningful file and directory names**
10. ✅ **Follow consistent naming conventions**

## Example: Complete Small Project

```
order-service/
├── src/
│   ├── activities/
│   │   ├── orders.ts          # Order activities
│   │   ├── inventory.ts       # Inventory activities
│   │   ├── notifications.ts   # Notification activities
│   │   └── index.ts           # Re-exports
│   │
│   ├── workflows/
│   │   ├── order-processing.ts
│   │   └── index.ts
│   │
│   ├── common/
│   │   └── types.ts           # Shared types
│   │
│   ├── worker.ts              # Worker entry point
│   └── client.ts              # Client entry point
│
├── package.json
└── tsconfig.json
```

This structure provides:
- Clear separation of concerns
- Easy to navigate
- Scalable as project grows
- Follows Temporal best practices
