## Modules Overview

Each module in this repository is designed to be standalone yet highly interoperable.

### System Core
* **Core**: The backbone of the project. It handles the lifecycle of the application, event bus management, and cross-module communication.
* **WidgetLoader**: A dynamic injection engine that loads UI components on demand, ensuring a low memory footprint.
* **Widgets**: A library of reusable UI primitives (buttons, bars, and icons) that maintain a consistent design language.
* **WidgetsConfig**: The centralized configuration layer for saving, loading, and importing user-defined widget layouts.

### Accessibility & Display
* **AccessbilityWarning**: A specialized module that monitors UI state to ensure visibility and usability standards are met, alerting the user to potential issues.
* **CustomiseFrame**: The main core, to open Config ingame.
* **NoteDisplay**: A clean, prioritized overlay system for displaying text-based reminders, tactical notes, or system logs.

### Utility & Data
* **HealerMana**: A high-performance tracking module specifically tuned for monitoring resource pools and regeneration in real-time.
* **ProfessionExporter**: An automated tool for scraping profession-based data and formatting it for external use on Site.
