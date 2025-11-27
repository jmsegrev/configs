---
name: maestro-tests
description: This skill provides guidance for writing Maestro mobile UI tests. Use when creating YAML flow files for iOS, Android, or web UI testing, including tap/swipe interactions, assertions, scrolling, nested flows, and JavaScript integration. Triggers on requests like "write a Maestro test", "create a flow for login", or "automate the checkout".
---

# Maestro Tests

## Overview

Maestro is an open-source framework for mobile and web UI testing using declarative YAML flows. This skill provides guidance for writing effective, maintainable Maestro tests.

## Flow File Structure

Every Maestro flow is a YAML file with configuration above `---` and commands below:

```yaml
appId: com.example.app   # Required: package name (Android) or bundle id (iOS)
name: Optional Flow Name # Optional: custom name for reports
tags:
  - smoke
  - login
env:
  USERNAME: user@example.com
  PASSWORD: secret123
onFlowStart:             # Commands to run before flow starts
  - runScript: setup.js
onFlowComplete:          # Commands to run after flow ends (success or failure)
  - runScript: teardown.js
---
- launchApp
- tapOn: "Login"
- inputText: ${USERNAME}
```

## Essential Commands

### Navigation & Interaction

```yaml
- launchApp                    # Launch the app under test
- launchApp:
    clearState: true           # Clear app data before launch
    clearKeychain: true        # Clear iOS keychain
- tapOn: "Button Text"         # Tap by text
- tapOn:
    id: "button_id"            # Tap by accessibility id
- tapOn:
    point: 50%,50%             # Tap by relative position
- longPressOn: "Element"       # Long press on element
- doubleTapOn: "Element"       # Double tap
- back                         # Press back button
- hideKeyboard                 # Dismiss keyboard
- waitForAnimationToEnd        # Wait for animations to complete
- waitForAnimationToEnd:
    timeout: 5000              # Custom timeout in ms
```

### Text Input

```yaml
- inputText: "Hello World"     # Enter text
- eraseText: 5                 # Erase 5 characters
- inputRandomEmail             # Generate random email
- inputRandomPersonName        # Generate random name
- inputRandomNumber:
    length: 6                  # Generate 6-digit number
- inputRandomText:
    length: 10                 # Generate random text
- copyTextFrom:
    id: "text_field"           # Copy text from element
- pasteText                    # Paste copied text
```

### Assertions

```yaml
- assertVisible: "Welcome"     # Assert text is visible
- assertVisible:
    id: "element_id"
    enabled: true              # Also check enabled state
- assertNotVisible: "Error"    # Assert not visible
- assertTrue: ${VAR == "value"} # JavaScript condition
```

### Scrolling

```yaml
- scroll                       # Scroll down
- scroll:
    direction: UP              # UP|DOWN|LEFT|RIGHT
- scrollUntilVisible:
    element: "Target Text"
    direction: DOWN
    timeout: 20000             # ms to search
    speed: 40                  # 0-100, higher = faster
```

### Swipe

```yaml
- swipe:
    direction: LEFT            # LEFT|RIGHT|UP|DOWN
    duration: 400              # ms
- swipe:
    start: 90%,50%
    end: 10%,50%               # Custom swipe path
```

## Selectors

Use selectors to identify UI elements:

```yaml
- tapOn:
    text: "Button"             # Match by text (regex supported)
    id: "view_id"              # Match by accessibility id
    index: 0                   # 0-based index when multiple match
    width: 100                 # Match by element width
    height: 50                 # Match by element height
    tolerance: 10              # Tolerance for width/height matching
    enabled: true              # Filter by enabled state
    checked: true              # Filter by checked state
    focused: true              # Filter by focus state
    selected: true             # Filter by selected state
```

### Relative Selectors

```yaml
- tapOn:
    text: "Edit"
    below: "Profile"           # Element below "Profile"
    above: "Footer"            # Element above "Footer"
    leftOf: "Icon"             # Element left of "Icon"
    rightOf: "Username"        # Element right of "Username"
    childOf:
      id: "container"          # Child of container
    containsChild: "Label"     # Has direct child with text
    containsDescendants:       # Has all these descendants
      - id: "title"
      - text: "Description"
```

### Element Traits

Select elements by high-level characteristics:

```yaml
- tapOn:
    traits: text               # Element containing text
- tapOn:
    traits: long-text          # Element with 200+ characters
- tapOn:
    traits: square             # Square element (width/height within 3%)
```

### Regular Expressions

All text fields support regex:

```yaml
- assertVisible: ".*welcome.*" # Partial match
- tapOn: "Price: \\$[0-9]+"    # Match pattern
- assertVisible: "[0-9]{6}"    # 6-digit OTP
```

## Nested Flows & Reusability

Create reusable flows with `runFlow`:

```yaml
# login.yaml
appId: com.example.app
env:
  USERNAME: ${USERNAME || "default@test.com"}
  PASSWORD: ${PASSWORD || "test123"}
---
- tapOn: "Username"
- inputText: ${USERNAME}
- tapOn: "Password"
- inputText: ${PASSWORD}
- tapOn: "Sign In"
```

```yaml
# main_test.yaml
appId: com.example.app
---
- launchApp:
    clearState: true
- runFlow: login.yaml          # Run subflow
- runFlow:
    file: checkout.yaml
    env:
      ITEM: "Product A"        # Pass parameters
```

## Conditions

Run commands conditionally:

```yaml
- runFlow:
    when:
      visible: "Skip Tutorial"
    commands:
      - tapOn: "Skip Tutorial"

- runFlow:
    when:
      notVisible: "Welcome"    # Run when element is NOT visible
    file: show_welcome.yaml

- runFlow:
    when:
      platform: iOS            # iOS|Android|Web
    file: ios_specific.yaml

- runFlow:
    when:
      true: ${ENV_VAR == "prod"}
    file: prod_setup.yaml
```

Multiple conditions are applied as AND logic.

## Loops & Retries

```yaml
- repeat:
    times: 3
    commands:
      - tapOn: "Next"
      - scroll

- retry:
    maxRetries: 3
    commands:
      - tapOn: "Submit"
      - assertVisible: "Success"
```

## JavaScript Integration

Use JavaScript for dynamic logic:

```yaml
- runScript: generate_data.js
- inputText: ${output.username}
```

```javascript
// generate_data.js
const timestamp = new Date().getTime();
output.username = `user_${timestamp}`;
output.email = `test_${timestamp}@example.com`;
```

HTTP requests in JavaScript:

```javascript
const response = http.get("https://api.example.com/user");
const data = json(response.body);
output.userId = data.id;
```

## Best Practices

1. **Prefer text/id over coordinates** - Tests are more resilient to layout changes
2. **Use relative selectors** - "Edit button below Profile" is clearer than index
3. **Create reusable subflows** - Extract common sequences (login, setup)
4. **Use labels for clarity**:
   ```yaml
   - tapOn:
       id: "submit_btn"
       label: Submit the registration form
   ```
5. **Handle optional elements**:
   ```yaml
   - assertVisible:
       text: "Promotion Banner"
       optional: true          # Won't fail if not visible
   ```
6. **Set environment defaults**:
   ```yaml
   env:
     API_URL: ${API_URL || "https://staging.api.com"}
   ```
7. **Organize flows by feature**:
   ```
   flows/
   ├── auth/
   │   ├── login.yaml
   │   └── signup.yaml
   ├── checkout/
   │   └── purchase.yaml
   └── common/
       └── setup.yaml
   ```

## Running Tests

```bash
# Run single flow
maestro test flow.yaml

# Run with parameters
maestro test -e USERNAME=test@mail.com flow.yaml

# Run folder (test suite)
maestro test flows/

# Continuous mode (re-runs on file change)
maestro test --continuous flow.yaml

# Run in cloud
maestro cloud app.apk flows/
```

## References

Consult `references/commands.md` for a complete command reference with all parameters and options.
