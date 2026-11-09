# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

World of Warcraft retail addon that displays equipment set names as yellow text overlays on item icons in bags, bank, and character panel. Shows up to 3 set names vertically, with "+" for additional sets. Names truncate at 5 characters.

## Development

No build step. Copy addon folder to WoW AddOns directory and `/reload` in-game to test changes.

Update `## Interface:` in .toc file when WoW version changes (currently 16001 for WoW Forever and 120000 for Midnight/12.0).

Slash commands: `/esl` or `/equipsetlabels` opens options panel.

## Architecture

Two-layer caching system:
1. `itemSetText` - itemID to pre-formatted display string (rebuilt only on EQUIPMENT_SETS_CHANGED)
2. `slotSetText` - "bag:slot" or "e{slotID}" to display string (rebuilt on bag/equipment changes)

Updates are debounced (0.1s) via `ScheduleUpdate()` to coalesce rapid events.

Saved variables: `EquipmentSetLabelsDB` stores user preferences (showBags, showBank, showCharacter).

## WoW API Notes

- `C_EquipmentSet` for equipment set data
- `C_Container` for bag/bank slot inspection
- `ContainerFrameCombinedBags` is the modern unified bag view (ContainerFrame1-13 are legacy/separate view)
- The bank is a tabbed panel: enumerate buttons with `BankFrame.BankPanel:EnumerateValidItems()`, identified by `GetBankTabID()` and `GetContainerSlotID()`
- Character bank tab indices are 6-12 (scanned range)
