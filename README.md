# ⚔️ DevQuest: RPG Gamification for Developers

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
