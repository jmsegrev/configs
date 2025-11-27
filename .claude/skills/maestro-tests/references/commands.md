# Maestro Commands Reference

Complete reference for all Maestro commands with full parameter options.

## App Lifecycle

### launchApp
Launch the app under test.

```yaml
- launchApp                           # Simple launch
- launchApp: com.other.app            # Launch different app
- launchApp:
    appId: "com.example.app"          # App identifier
    clearState: true                  # Clear app data (default: false)
    clearKeychain: true               # Clear iOS keychain (default: false)
    stopApp: true                     # Stop before launch (default: true)
    permissions:
      all: allow                      # allow|deny|unset for all
      notifications: deny             # Specific permission
      android.permission.CAMERA: allow
    arguments:                        # Launch arguments
      debug: true
      apiUrl: "https://staging.api.com"
```

### stopApp
Stop the running app.

```yaml
- stopApp                             # Stop current app
- stopApp: com.other.app              # Stop specific app
```

### killApp
Force kill the app process.

```yaml
- killApp                             # Kill current app
- killApp: com.other.app              # Kill specific app
```

### clearState
Clear app data without relaunching.

```yaml
- clearState                          # Clear current app
- clearState: com.other.app           # Clear specific app
```

### clearKeychain
Clear the entire iOS keychain.

```yaml
- clearKeychain
```

## Tap Commands

### tapOn
Tap on an element.

```yaml
- tapOn: "Button Text"                # By text
- tapOn:
    text: "Submit"                    # Text selector (regex)
    id: "submit_btn"                  # Accessibility id (regex)
    index: 0                          # 0-based index
    point: 50%,50%                    # Relative position
    width: 100                        # Element width
    height: 50                        # Element height
    tolerance: 10                     # Width/height tolerance
    enabled: true                     # Filter by enabled
    checked: true                     # Filter by checked
    focused: true                     # Filter by focused
    selected: true                    # Filter by selected
    below: "Header"                   # Relative: below element
    above: "Footer"                   # Relative: above element
    leftOf: "Icon"                    # Relative: left of element
    rightOf: "Label"                  # Relative: right of element
    containsChild: "Text"             # Has direct child with text
    childOf:
      id: "parent_container"          # Is child of element
    containsDescendants:              # Has all these descendants
      - id: "title"
      - text: "Description"
    traits: text                      # Element traits: text|long-text|square
    repeat: 3                         # Repeat tap N times
    delay: 500                        # Delay between repeats (ms)
    retryTapIfNoChange: true          # Retry if UI doesn't change
    waitToSettleTimeoutMs: 500        # Max wait for UI to settle
    label: "Tap submit button"        # Custom label for reports
    optional: false                   # Continue on failure
```

### doubleTapOn
Double tap on an element. Same selectors as tapOn.

```yaml
- doubleTapOn: "Element"
- doubleTapOn:
    id: "element_id"
```

### longPressOn
Long press on an element. Same selectors as tapOn.

```yaml
- longPressOn: "Element"
- longPressOn:
    id: "element_id"
    duration: 1000                    # Press duration (ms)
```

## Text Input

### inputText
Enter text into the focused field.

```yaml
- inputText: "Hello World"
- inputText:
    text: "Hello"
    label: "Enter username"
```

### eraseText
Erase characters from focused field.

```yaml
- eraseText: 10                       # Erase 10 characters
- eraseText:
    charactersToErase: 5
```

### Random Input Commands

```yaml
- inputRandomEmail                    # Random email address
- inputRandomPersonName               # Random full name
- inputRandomNumber                   # Random 8-digit number
- inputRandomNumber:
    length: 6                         # Custom length
- inputRandomText                     # Random 8-char text
- inputRandomText:
    length: 20                        # Custom length
- inputRandomCityName                 # Random city name
- inputRandomCountryName              # Random country name
- inputRandomColorName                # Random color name
```

### copyTextFrom
Copy text from an element.

```yaml
- copyTextFrom: "Label"               # Copy by text
- copyTextFrom:
    id: "text_field"
    index: 0
# Access copied text: ${maestro.copiedText}
```

### pasteText
Paste the copied text.

```yaml
- pasteText
```

### hideKeyboard
Dismiss the on-screen keyboard.

```yaml
- hideKeyboard
```

### pressKey
Press a specific key.

```yaml
- pressKey: Enter                     # Enter key
- pressKey: Backspace                 # Backspace
- pressKey: Home                      # Home button
- pressKey: Lock                      # Lock screen
- pressKey: Volume Up                 # Volume up
- pressKey: Volume Down               # Volume down
```

## Assertions

### assertVisible
Assert an element is visible on screen.

```yaml
- assertVisible: "Welcome"            # By text
- assertVisible:
    text: "Submit"                    # Text (regex)
    id: "submit_btn"                  # Accessibility id
    enabled: true                     # Check enabled state
    checked: true                     # Check checked state
    focused: true                     # Check focus state
    selected: true                    # Check selected state
    label: "Verify submit is visible"
    optional: false
```

### assertNotVisible
Assert an element is NOT visible.

```yaml
- assertNotVisible: "Error"
- assertNotVisible:
    id: "error_banner"
```

### assertTrue
Assert a JavaScript expression evaluates to true.

```yaml
- assertTrue: ${VALUE > 0}
- assertTrue: ${USERNAME == "admin"}
- assertTrue:
    condition: ${output.count > 5}
    label: "Verify count is greater than 5"
```

### assertWithAI (requires AI config)
Use AI to verify screen state.

```yaml
- assertWithAI: "The login form is displayed"
- assertWithAI:
    assertion: "Shopping cart shows 3 items"
    optional: true                    # Default: true
```

### assertNoDefectsWithAI (requires AI config)
Use AI to check for visual defects.

```yaml
- assertNoDefectsWithAI
- assertNoDefectsWithAI:
    optional: true
```

## Scrolling

### scroll
Scroll the screen.

```yaml
- scroll                              # Scroll down (default)
- scroll:
    direction: UP                     # UP|DOWN|LEFT|RIGHT
    duration: 500                     # Scroll duration (ms)
```

### scrollUntilVisible
Scroll until an element becomes visible.

```yaml
- scrollUntilVisible:
    element: "Target Text"            # Element to find
    direction: DOWN                   # UP|DOWN|LEFT|RIGHT (default: DOWN)
    timeout: 20000                    # Max time in ms (default: 20000)
    speed: 40                         # 0-100, higher = faster (default: 40)
    visibilityPercentage: 100         # 0-100 element visibility (default: 100)
    centerElement: false              # Try to center element (default: false)
- scrollUntilVisible:
    element:
      id: ".*item_id.*"               # Find by id (regex)
    direction: DOWN
```

## Swipe

### swipe
Swipe in a direction or along a path.

```yaml
- swipe:
    direction: LEFT                   # LEFT|RIGHT|UP|DOWN
    duration: 400                     # Swipe duration (ms)
- swipe:
    start: 90%,50%                    # Start point (relative)
    end: 10%,50%                      # End point (relative)
    duration: 500
- swipe:
    start: 500,300                    # Start point (pixels)
    end: 100,300                      # End point (pixels)
```

## Navigation

### back
Press the back button.

```yaml
- back
```

### openLink
Open a URL or deep link.

```yaml
- openLink: "https://example.com"
- openLink: "myapp://product/123"     # Deep link
```

## Flow Control

### runFlow
Run commands from another flow file or inline.

```yaml
- runFlow: login.yaml                 # Run subflow
- runFlow:
    file: setup.yaml
    env:
      USERNAME: "admin"               # Pass parameters
      DEBUG: true
- runFlow:
    when:
      visible: "Skip"                 # Conditional execution
    file: skip_onboarding.yaml
- runFlow:
    when:
      platform: iOS                   # iOS|Android|Web
    commands:
      - tapOn: "iOS specific"
- runFlow:
    when:
      notVisible: "Welcome"
      true: ${DEBUG_MODE == "true"}
    commands:
      - tapOn: "Debug Menu"
```

### repeat
Repeat commands multiple times.

```yaml
- repeat:
    times: 5
    commands:
      - tapOn: "Next"
      - scroll
- repeat:
    while:
      visible: "Load More"            # Repeat while visible
    commands:
      - tapOn: "Load More"
      - scroll
```

### retry
Retry commands on failure.

```yaml
- retry:
    maxRetries: 3
    commands:
      - tapOn: "Submit"
      - assertVisible: "Success"
```

## Wait Commands

### extendedWaitUntil
Wait for a condition with extended timeout.

```yaml
- extendedWaitUntil:
    visible: "Data Loaded"            # Wait until visible
    timeout: 30000                    # Timeout in ms
- extendedWaitUntil:
    notVisible: "Loading..."          # Wait until not visible
    timeout: 10000
```

### waitForAnimationToEnd
Wait for animations to complete.

```yaml
- waitForAnimationToEnd
- waitForAnimationToEnd:
    timeout: 5000                     # Max wait time
```

## JavaScript

### runScript
Run a JavaScript file.

```yaml
- runScript: setup.js
- runScript:
    file: generate_data.js
    when:
      visible: "Form"
# Access outputs: ${output.variableName}
```

### evalScript
Evaluate inline JavaScript.

```yaml
- evalScript: ${output.count = 0}
- evalScript: |
    const now = new Date();
    output.timestamp = now.toISOString();
```

## Device Control

### setLocation
Set the device's GPS location.

```yaml
- setLocation:
    latitude: 37.7749
    longitude: -122.4194
```

### travel
Simulate traveling between locations.

```yaml
- travel:
    points:
      - 37.7749,-122.4194
      - 37.8044,-122.2712
    speed: 50                         # Speed in m/s
```

### setAirplaneMode
Set airplane mode state.

```yaml
- setAirplaneMode: true               # Enable
- setAirplaneMode: false              # Disable
```

### toggleAirplaneMode
Toggle airplane mode.

```yaml
- toggleAirplaneMode
```

### setOrientation
Set device orientation.

```yaml
- setOrientation: PORTRAIT            # PORTRAIT|LANDSCAPE
```

## Media

### addMedia
Add media files to the device gallery.

```yaml
- addMedia:
    - path/to/image.png
    - path/to/video.mp4
```

### takeScreenshot
Capture a screenshot.

```yaml
- takeScreenshot: screenshot_name     # Saves to output directory
```

### startRecording
Start video recording.

```yaml
- startRecording: test_recording
```

### stopRecording
Stop video recording.

```yaml
- stopRecording
```

## AI Commands (require AI configuration)

### extractTextWithAI
Extract text from screen using AI.

```yaml
- extractTextWithAI: "What is the total price shown?"
# Result in: ${ai.extractedText}
```

## Common Arguments

All commands support these optional arguments:

```yaml
- anyCommand:
    label: "Descriptive step name"    # Custom label for reports
    optional: true                    # Continue flow on failure (default: false)
```

## Built-in Variables

```yaml
${maestro.copiedText}                 # Last copied text
${maestro.platform}                   # "android"|"ios"|"web"
${MAESTRO_FILENAME}                   # Current flow filename
${output.variableName}                # JavaScript output variables
```

## Flow Configuration

Configuration options in the YAML header (above `---`):

```yaml
appId: com.example.app                # Required: app identifier
name: "Custom Flow Name"              # Optional: custom name for reports
tags:                                 # Optional: tags for filtering
  - smoke
  - regression
env:                                  # Optional: environment variables
  USERNAME: "test@example.com"
  API_URL: ${API_URL || "https://staging.api.com"}
onFlowStart:                          # Optional: run before flow starts
  - runScript: setup.js
  - runFlow: prepare.yaml
onFlowComplete:                       # Optional: run after flow ends (success or failure)
  - runScript: teardown.js
  - takeScreenshot: final_state
jsEngine: graaljs                     # Optional: rhino (default) or graaljs
androidWebViewHierarchy: devtools     # Optional: enable Chrome DevTools for webviews
---
```

### Hook Behavior

| Scenario | Behavior |
|----------|----------|
| onFlowStart fails | Flow marked failed, main body skipped |
| onFlowStart fails | onFlowComplete still runs |
| onFlowComplete fails | Flow marked failed |
