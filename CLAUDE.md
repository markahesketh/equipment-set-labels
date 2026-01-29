# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

World of Warcraft retail addon that displays equipment set names as yellow text overlays on item icons in bags and bank. Shows up to 3 set names vertically, with "+" for additional sets. Names truncate at 5 characters.

## Development

No build step. Copy addon folder to WoW AddOns directory and `/reload` in-game to test changes.

Update `## Interface:` in .toc file when WoW version changes (currently 120000 for Midnight/12.0).

## Architecture

Two-layer caching system:
1. `itemSetText` - itemID to pre-formatted display string (rebuilt only on EQUIPMENT_SETS_CHANGED)
2. `slotSetText` - "bag:slot" to display string (rebuilt on bag changes)

Updates are debounced (0.1s) via `ScheduleUpdate()` to coalesce rapid events.

## WoW API Notes

- `C_EquipmentSet` for equipment set data
- `C_Container` for bag/bank slot inspection
- `ContainerFrameCombinedBags` is the modern unified bag view (ContainerFrame1-13 are legacy/separate view)
- Bank bag index is -1 (`BANK_BAG` constant)
