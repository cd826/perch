SPEC.md

# Perch — V0.1

## 1. Project Overview

### 1.1 Product Name

Perch

产品定位用一句话描述：

> **Perch — Your ambient dashboard for the second screen.**

中文内部定位：

> **Perch：让信息待在该待的地方。**

### 1.2 Product Positioning

A lightweight macOS dashboard designed primarily for use on a secondary monitor.

The application provides a low-distraction, glanceable information surface containing:

- Clock
- Todo / Reminders
- Weather

The application is not intended to replace a full productivity application.

Its primary purpose is:

> Show useful information at a glance without requiring the user to switch away from the primary workspace.

Future versions may integrate AI coding agent status, but AI agent functionality is explicitly out of scope for V0.1.


### 1.3 统一命名

```text
Product
Perch

Bundle Identifier
com.xxx.Perch

Repository
perch

App
Perch.app

Core concept
Ambient Dashboard

Primary use
Secondary Display
```

代码里也可以直接形成：

```text
PerchApp
PerchDashboard
PerchWidget
PerchWidgetGrid
PerchSettings
```

未来的 AI 模块甚至可以叫：

```text
AgentWidget
AgentBridge
AgentEvent
AgentStatus
AttentionState
```

这样整个产品的演进路线也很清楚：

```text
             Perch
               │
      ┌────────┴────────┐
      │                 │
  Information        Agents
      │                 │
 ┌────┼────┐       ┌────┼────┐
Clock Todo Weather Claude Codex ...
```

**V0.1 就先不要碰 Agent。**
先把 Perch 做成一个漂亮、稳定、真正适合放在第二块屏幕上的 Dashboard。等这个基础体验成立，再接 AI，会比较舒服。

注意：后面命名如何与上面有冲突，请以上面的命名为准。

---

# 2. Design Principles

The implementation MUST follow these principles.

### 2.1 Widget-based architecture

The Dashboard MUST NOT hard-code Clock, Todo, and Weather directly into a single monolithic view.

The application MUST use a Widget abstraction so that future widgets can be added without restructuring the Dashboard.

Conceptually:

```text
Dashboard
    │
    └── WidgetGrid
          │
          ├── ClockWidget
          │      ├── AnalogClock
          │      └── FlipClock
          │
          ├── TodoWidget
          │
          └── WeatherWidget
````

Future widgets may include:

```text
AgentWidget
CalendarWidget
GitHubWidget
SystemWidget
ServerWidget
```

These MUST be addable without changing the basic Dashboard architecture.

---

### 2.2 Glanceable information

The user should understand the current state of the dashboard within approximately 3 seconds.

Avoid:

* excessive text
* complex controls
* dense tables
* unnecessary interaction
* large amounts of secondary information

The Dashboard is primarily a display surface, not a traditional application window.

---

### 2.3 macOS native

Use:

* Swift
* SwiftUI
* AppKit only where necessary for macOS-specific window/display behavior

Do NOT use:

* Electron
* Tauri
* Flutter
* React Native
* WebView-based UI

---

# 3. Target Platform

## 3.1 Platform

macOS desktop.

## 3.2 Recommended minimum macOS version

Target:

```text
macOS 14.0+
```

If a required API forces a higher deployment target, document the reason before changing it.

---

# 4. Technology Stack

### UI

```text
SwiftUI
```

### macOS integration

```text
AppKit
```

Use AppKit only for capabilities that SwiftUI does not expose adequately.

Potential AppKit usage:

* window behavior
* screen detection
* full-screen/window placement
* application lifecycle

### System Reminders

Use:

```text
EventKit
```

for accessing macOS Reminders.

### Weather

Use:

```text
WeatherKit
```

where available.

### Location

Use:

```text
CoreLocation
```

for automatic location detection.

---

# 5. Application Structure

The project SHOULD use the following structure:

```text
AmbientDashboard/
│
├── App/
│   ├── AmbientDashboardApp.swift
│   └── AppDelegate.swift
│
├── Core/
│   ├── Models/
│   │   ├── WidgetModel.swift
│   │   ├── WidgetSize.swift
│   │   └── DashboardConfiguration.swift
│   │
│   ├── Services/
│   │   ├── ReminderService.swift
│   │   ├── WeatherService.swift
│   │   └── LocationService.swift
│   │
│   └── Storage/
│       └── ConfigurationStore.swift
│
├── Dashboard/
│   ├── DashboardView.swift
│   ├── WidgetGrid.swift
│   ├── WidgetContainer.swift
│   └── DashboardLayout.swift
│
├── Widgets/
│   │
│   ├── Clock/
│   │   ├── ClockWidget.swift
│   │   ├── ClockStyle.swift
│   │   ├── AnalogClockView.swift
│   │   └── FlipClockView.swift
│   │
│   ├── Todo/
│   │   ├── TodoWidget.swift
│   │   └── TodoViewModel.swift
│   │
│   └── Weather/
│       ├── WeatherWidget.swift
│       └── WeatherViewModel.swift
│
├── DesignSystem/
│   ├── DashboardCard.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   └── Appearance.swift
│
└── Resources/
    └── Assets.xcassets
```

The exact file structure may be adjusted during implementation if there is a clear technical reason.

---

# 6. Widget Architecture

## 6.1 Widget abstraction

All Dashboard widgets SHOULD conform to a common conceptual interface.

For example:

```swift
protocol DashboardWidget {
    var id: String { get }
    var columnSpan: Int { get }
}
```

The actual implementation may use a more SwiftUI-appropriate architecture.

The important requirement is that:

> Dashboard layout must not need to know the internal implementation of each widget.

---

## 6.2 Widget properties

Each widget SHOULD expose at least:

```text
id
columnSpan
minimumWidth
preferredHeight
```

Optional future properties:

```text
maximumWidth
supportsResize
supportsConfiguration
```

---

# 7. Dashboard Grid

## 7.1 Grid size

The default Dashboard MUST use:

```text
4 columns
```

The grid SHOULD be responsive to the available window width.

The application MUST NOT assume a fixed pixel width.

---

## 7.2 Column span

Each Widget defines how many grid columns it occupies.

Examples:

```text
Analog Clock
columnSpan = 1

Flip Clock
columnSpan = 2

Todo
columnSpan = 1

Weather
columnSpan = 1 or 2
```

---

# 8. Default Dashboard Layout

## 8.1 Analog Clock mode

When the Clock style is Analog:

```text
Clock   = 1 column
Todo    = 1 column
Weather = 2 columns
```

Layout:

```text
┌────────┬────────┬────────────────────┐
│        │        │                    │
│ Clock  │  Todo  │      Weather       │
│        │        │                    │
│   1    │   1    │         2          │
│        │        │                    │
└────────┴────────┴────────────────────┘
```

This is the default initial layout.

---

## 8.2 Flip Clock mode

When the Clock style is Flip Clock:

```text
Clock   = 2 columns
Todo    = 1 column
Weather = 1 column
```

Layout:

```text
┌────────────────────┬────────┬────────┐
│                    │        │        │
│                    │  Todo  │Weather │
│    Flip Clock      │        │        │
│                    │   1    │   1    │
│         2          │        │        │
│                    │        │        │
└────────────────────┴────────┴────────┘
```

Switching Clock style MUST automatically update the Dashboard layout.

The user MUST NOT be required to manually resize or reposition the other widgets.

---

# 9. Clock Widget

## 9.1 Supported styles

V0.1 MUST support:

```text
Analog
Flip Clock
```

The selected style MUST be persisted.

---

# 10. Analog Clock

## 10.1 Display

The Analog Clock MUST display:

* hour hand
* minute hand
* second hand
* 12 hour markers

Example:

```text
       12
    11    1
  10        2
 9     ●      3
  8          4
    7      5
       6
```

---

## 10.2 Time accuracy

The clock MUST use the system's current local time.

The displayed time MUST update continuously.

The second hand SHOULD move smoothly rather than jumping once per second.

---

## 10.3 Visual requirements

The Analog Clock SHOULD:

* use a clean minimal design
* remain readable at different window sizes
* maintain a circular shape
* scale proportionally with the available widget size

---

# 11. Flip Clock

## 11.1 Display

The Flip Clock MUST display:

```text
HH:MM
```

Example:

```text
┌──────┐ ┌──────┐
│  11  │ │  48  │
└──────┘ └──────┘
```

The Flip Clock occupies:

```text
2 columns
```

---

## 11.2 Animation

When the minute changes, the Flip Clock SHOULD use a flip-page animation.

The animation MUST NOT cause noticeable CPU usage or unnecessary redraws.

---

## 11.3 Time format

V0.1 uses:

```text
24-hour format
```

Example:

```text
09:05
18:42
23:59
```

12-hour mode is reserved for a future version.

---

# 12. Clock Style Switching

The application MUST provide a setting:

```text
Clock Style

○ Analog
● Flip Clock
```

When the user changes the setting:

1. Save the new preference.
2. Update ClockWidget.
3. Recalculate its column span.
4. Recalculate Dashboard layout.
5. Animate the layout change if practical.

---

# 13. Todo Widget

## 13.1 Data source

V0.1 MUST use macOS Reminders as the Todo data source.

Do NOT implement an independent Todo database.

---

## 13.2 Permission

The application MUST request the appropriate Reminders permission.

If permission is denied, the Widget MUST show a useful empty/error state instead of crashing.

Example:

```text
Reminders

Permission required

Allow access to display your reminders.
```

---

## 13.3 Display

The Todo Widget SHOULD display:

* list name
* number of incomplete tasks
* incomplete tasks

Example:

```text
Work

3

○ Review PR
○ Reply to email
○ Submit report
```

---

## 13.4 Empty state

When there are no incomplete tasks:

```text
Work

0

All reminders completed
```

---

## 13.5 Overflow

The Widget MUST avoid becoming excessively tall because of a large number of reminders.

If more tasks exist than can reasonably fit:

```text
○ Task 1
○ Task 2
○ Task 3
○ Task 4

+ 5 more
```

The exact maximum number of visible items can be adjusted based on widget height.

---

# 14. Weather Widget

## 14.1 Data source

Use WeatherKit if technically available for the selected deployment target.

Weather data SHOULD be accessed through a dedicated:

```text
WeatherService
```

The UI MUST NOT directly call WeatherKit APIs.

---

# 15. Location

V0.1 SHOULD support automatic location detection using CoreLocation.

Example:

```text
Guangzhou
```

If automatic location cannot be obtained, provide a fallback configuration allowing the user to specify a city manually.

---

# 16. Weather Display

The Weather Widget SHOULD display:

```text
Guangzhou

31°

Mostly Clear

High 33°
Low 26°
```

It SHOULD also display several upcoming hourly forecasts.

Example:

```text
12   13   14   15   16   17

☀️   ☁️   ☁️   ☁️   ☁️   ☁️

32°  32°  33°  31°  29°  27°
```

---

## 16.1 Required weather information

V0.1:

* current temperature
* current weather condition
* daily high
* daily low
* hourly forecast
* weather icon

Future versions:

* humidity
* precipitation probability
* wind
* air quality
* sunrise/sunset

---

# 17. Weather Refresh

Weather data MUST NOT be requested continuously.

The WeatherService SHOULD:

* cache recent results
* refresh periodically
* refresh when the application becomes active
* gracefully handle network failures

If weather data cannot be refreshed, continue displaying the last valid result when possible.

---

# 18. Shared Card Design

All Widgets MUST use a shared visual container.

Create a reusable component such as:

```text
DashboardCard
```

The Card SHOULD provide:

* rounded corners
* consistent padding
* consistent background
* consistent spacing
* consistent typography

Example conceptual style:

```swift
RoundedRectangle(cornerRadius: 24)
```

with a translucent/material background where appropriate.

---

# 19. Appearance

V0.1 SHOULD support:

```text
System
Light
Dark
```

The application should visually work well on a secondary monitor.

The UI should avoid excessively bright backgrounds because the application is intended to remain visible for long periods.

---

# 20. Window Behavior

## 20.1 Resizable

The Dashboard window MUST be resizable.

Widget layout MUST respond to changes in available width.

---

## 20.2 Full Screen

The application SHOULD support full-screen display.

The user should be able to place the application on a secondary monitor and use it as a dedicated dashboard.

---

## 20.3 Multiple displays

V0.1 does not need automatic secondary-display selection.

The user may manually move the window to the desired monitor.

Future versions may provide:

```text
Display

○ Main Display
● Secondary Display
```

---

# 21. Settings

V0.1 settings should remain minimal.

Suggested settings:

```text
General

Clock
    Style
        ○ Analog
        ● Flip Clock

Todo
    List
        [ Work ▼ ]

Weather
    Location
        ○ Automatic
        ○ Manual

Appearance
    ○ System
    ○ Light
    ○ Dark
```

Settings MUST persist between application launches.

---

# 22. Error Handling

The application MUST remain usable if an external data source fails.

Examples:

### Reminders unavailable

```text
Reminders

Unable to access reminders.
```

### Weather unavailable

```text
Weather

Weather data unavailable.

Last updated:
10:42
```

### Location unavailable

```text
Weather

Location unavailable.

Set location manually.
```

The application MUST NOT crash because of missing permissions, network failures, or unavailable external services.

---

# 23. Performance

The application is intended to remain open for long periods.

Therefore:

* avoid unnecessary polling
* avoid excessive view redraws
* avoid memory leaks
* avoid continuous network requests
* animations should be lightweight
* CPU usage should remain low when the UI is idle

The Clock may update continuously, but other widgets should only update when necessary.

---

# 24. Persistence

Persist at least:

```text
Clock Style
Todo List selection
Weather Location
Appearance preference
```

A lightweight local configuration mechanism is sufficient.

Do NOT introduce a database for V0.1.

---

# 25. Accessibility

Basic macOS accessibility SHOULD be supported.

Interactive controls should have meaningful accessibility labels.

Examples:

```text
Clock style: Analog
Clock style: Flip Clock
Todo list: Work
Weather location: Guangzhou
```

---

# 26. Out of Scope

The following are explicitly NOT part of V0.1.

## AI Agents

Do NOT implement:

* Claude Code integration
* Codex integration
* Pi integration
* AI agent status
* agent progress
* agent notifications
* permission requests
* agent control

---

## Custom Widget System

Do NOT implement:

* widget marketplace
* third-party widgets
* drag-and-drop widget editor
* dynamic widget installation

The architecture should support these in the future, but V0.1 does not implement them.

---

## Todo Management

Do NOT implement:

* independent Todo database
* custom Todo creation
* Todo editing
* Todo synchronization service

Use macOS Reminders.

---

# 27. Future Architecture: AI Agent Integration

Although AI integration is out of scope for V0.1, the Widget architecture MUST leave room for a future:

```text
AgentWidget
```

Potential future architecture:

```text
Claude Code
     │
     │ Hooks / events
     ▼
Agent Bridge
     │
     │ local IPC / WebSocket
     ▼
AgentWidget
```

The future AgentWidget may display only high-value events:

```text
● Working

Running tests...
```

```text
✓ Completed

142 tests passed
```

```text
⚠ Needs your attention

Permission required
```

The Dashboard MUST NOT need to be redesigned when this widget is introduced.

---

# 28. V0.1 Acceptance Criteria

The V0.1 implementation is considered complete when all of the following are satisfied.

### Clock

* [ ] Analog Clock works.
* [ ] Flip Clock works.
* [ ] Clock uses system local time.
* [ ] Analog Clock occupies 1 column.
* [ ] Flip Clock occupies 2 columns.
* [ ] Flip animation works when appropriate.
* [ ] Clock style persists after restarting the application.

### Dashboard

* [ ] Default grid contains 4 columns.
* [ ] Dashboard responds to window resizing.
* [ ] Switching clock styles automatically recalculates layout.
* [ ] No manual repositioning is required after switching Clock style.

### Todo

* [ ] macOS Reminders permission can be requested.
* [ ] Selected reminder list can be displayed.
* [ ] Incomplete task count is displayed.
* [ ] Incomplete tasks are displayed.
* [ ] Empty state works.
* [ ] Permission/error state works.

### Weather

* [ ] Current temperature is displayed.
* [ ] Weather condition is displayed.
* [ ] Daily high/low are displayed.
* [ ] Hourly forecast is displayed.
* [ ] Location can be detected or configured.
* [ ] Weather errors do not crash the application.

### UI

* [ ] All widgets use a consistent Card design.
* [ ] Light/Dark/System appearance works.
* [ ] Dashboard can be resized.
* [ ] Dashboard can be used on a secondary monitor.
* [ ] Application can run for extended periods without obvious performance degradation.

---

# 29. Development Guidelines

## 29.1 Keep V0.1 small

Do not implement future features "because they may be useful later".

Only implement functionality required by this specification.

---

## 29.2 Avoid premature abstraction

The Widget architecture should be extensible, but should remain simple.

Do not build a plugin framework in V0.1.

The goal is:

```text
Simple Widget abstraction
+
Simple Grid layout
+
Clean separation of data services and UI
```

---

## 29.3 Separate data from presentation

For example:

```text
WeatherService
      ↓
WeatherViewModel
      ↓
WeatherWidget
```

NOT:

```text
WeatherWidget
      ↓
WeatherKit API
```

Similarly:

```text
ReminderService
      ↓
TodoViewModel
      ↓
TodoWidget
```

---

# 30. Suggested Implementation Order

Claude Code SHOULD implement the project in the following order.

### Phase 1 — Project skeleton

* Create macOS SwiftUI project.
* Configure minimum macOS version.
* Create basic application lifecycle.
* Create DashboardView.
* Create WidgetGrid.

### Phase 2 — Design system

* DashboardCard
* typography
* spacing
* appearance

### Phase 3 — Clock

* ClockWidget
* AnalogClockView
* FlipClockView
* ClockStyle
* style persistence
* automatic column-span change

### Phase 4 — Todo

* ReminderService
* permission handling
* TodoViewModel
* TodoWidget

### Phase 5 — Weather

* LocationService
* WeatherService
* WeatherViewModel
* WeatherWidget
* caching/error state

### Phase 6 — Window behavior

* resizing
* full-screen support
* secondary monitor usage

### Phase 7 — Polish

* animations
* spacing
* typography
* dark/light appearance
* performance optimization
* accessibility

---

# 31. Final V0.1 Product Definition

The finished application should feel like:

> A quiet information panel living on the user's secondary monitor.

At a glance, the user can see:

```text
┌────────┬────────┬────────────────────┐
│        │        │                    │
│ Clock  │  Todo  │      Weather       │
│        │        │                    │
└────────┴────────┴────────────────────┘
```

The application should not demand attention.

It should provide information when the user looks at it.

The core product principle is:

> **Don't make the user open an application to find information. Put the information where they can see it.**

````

### 我建议 Claude Code 的第一轮任务

不要直接让 Claude Code “把整个 SPEC 全部实现”。

最好把任务拆成：

```text
Phase 1
项目骨架 + Widget 架构 + 4栏 Grid + Card Design
````

先做到：

```text
┌────────┬────────┬────────────────────┐
│ Clock  │ Todo   │      Weather       │
│ Demo   │ Demo   │       Demo         │
└────────┴────────┴────────────────────┘
```

其中三个先用 Mock Data。

**第二轮**再做 Analog / Flip Clock。

**第三轮**接 macOS Reminders。

**第四轮**接 WeatherKit。

