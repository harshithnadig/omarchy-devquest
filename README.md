# ⚔️ DevQuest: RPG Gamification for Developers

## Marketplace installation and review notes

This section describes the current implementation and takes precedence over broader feature claims below.

### Requirements and dependencies

Requires Omarchy Quattro's plugin-capable shell, Qt 6 / QtQuick / QtQuick.Controls / QtQuick.Layouts, Quickshell and Omarchy qs.Commons / qs.Ui modules. This is not a standalone QML application.

Bash, jq, Git, GNU coreutils and findutils; Omarchy notification helper for level-up messages.

### Install

Review the unsandboxed plugin source, then run in an Omarchy Quattro session:

    omarchy plugin add https://github.com/harshithnadig/omarchy-devquest.git --enable

Use the Omarchy bar editor to place the widget if necessary. Installation fetches upstream HEAD, not a pinned marketplace-reviewed snapshot.

### Remove

    omarchy plugin remove harshith.devquest

### Permissions and persistent state

Stores progress in ~/.local/state/omarchy/devquest.json and scans Git repositories under ~/Work. Plugin removal retains the progress file; remove it separately only to reset progress.

### Current limitations

Prototype: commits refresh on date rollover, rather than continuously; the sprint button grants progress immediately without timing 25 minutes; the PR quest starts with sample progress.

Repository structure and documentation were reviewed for resubmission. This is not a fresh end-to-end runtime test or security audit.

### License

MIT; see LICENSE. External applications, models and dependencies retain their own licenses.

---

**DevQuest** is a retro 8-bit RPG companion and developer gamification plugin for **Omarchy** and **Hyprland**.

Earn XP, level up your character, complete daily coding quests, and maintain your commit streaks right from your desktop topbar!

---

## ✨ Features

- 🧙 **Hero Avatar & Titles:** Evolve from a *Novice Coder* to *Code Mage*, *Bug Slayer*, and *Kernel Archmage* as you code.
- 📊 **XP & Level Progression:** Real-time XP tracking with dynamic level-up popups and notifications.
- 💚 **Streak HP & Focus Mana:** Daily vitality tracking linked to your Git commits and active sessions.
- 📜 **Daily Quests:**
  - *Daily Forge:* Make 3 Git commits today.
  - *Deep Work Sprint:* 25-minute uninterrupted coding sprint.
  - *Open Source Hero:* Submit or triage PRs and open-source contributions.
- ⚡ **1-Click Sprint Grind:** Quick-start a focus session with one click in the panel.
- 🎨 **Adaptive Theme Sync:** Automatically blends with your active Omarchy theme colors (Catppuccin, Tokyo Night, Everforest, Cyberpunk, etc.).

---

## 🛠️ Structure

```
~/.config/omarchy/plugins/harshith.devquest/
├── manifest.json       # Plugin metadata and config schema
├── BarWidget.qml       # Animated bar pill with avatar and level badge
├── Panel.qml           # Retro RPG character sheet & quest log popup
├── devquest-engine.sh  # High-performance state tracker
└── README.md
```

---

## 🚀 Usage

Enable the plugin via the Omarchy Plugin Manager:
```bash
omarchy plugin enable harshith.devquest
```
Click the 8-bit avatar in your bar to open your character sheet and claim quest XP!
