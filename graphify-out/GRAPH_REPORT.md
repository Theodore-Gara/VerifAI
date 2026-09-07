# Graph Report - VerifAI  (2026-09-07)

## Corpus Check
- 159 files · ~60,145 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 302 nodes · 364 edges · 15 communities (14 shown, 1 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bcb28b1b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- package.json
- daily_task_card.dart
- index.js
- app_colors.dart
- VerifAI
- scoreboard_screen.dart
- dimension_bar.dart
- Screens Implemented — 9 Screens
- score_ring.dart
- main_nav_shell.dart
- app_radius.dart
- profile_screen.dart
- track_roadmap_screen.dart
- Person 1 — Foundation Complete ✅
- @company

## God Nodes (most connected - your core abstractions)
1. `Screens Implemented — 9 Screens` - 11 edges
2. `VerifAI` - 9 edges
3. `Person 1 — Foundation Complete ✅` - 8 edges
4. `🎨 VerifAI Modern Design System & Collaborator Guide` - 5 edges
5. `3. Key Component Usage Guidelines` - 5 edges
6. `_DashboardScreenState` - 5 edges
7. `_ScoreboardScreenState` - 5 edges
8. `Getting Started` - 5 edges
9. `Knowledge Graph (Graphify)` - 5 edges
10. `VerifAI Mobile App` - 4 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `currentUserProvider`  [EXTRACTED]
  mobile/lib/features/profile/presentation/profile_screen.dart → None  _Bridges community 5 → community 11_
- `TrackRoadmapScreen` --references--> `currentUserProvider`  [EXTRACTED]
  mobile/lib/features/track/presentation/track_roadmap_screen.dart → None  _Bridges community 5 → community 12_
- `ProfileScreen` --inherits--> `ConsumerWidget`  [EXTRACTED]
  mobile/lib/features/profile/presentation/profile_screen.dart → None  _Bridges community 11 → community 12_

## Import Cycles
- None detected.

## Communities (15 total, 1 thin omitted)

### Community 0 - "package.json"
Cohesion: 0.09
Nodes (21): dependencies, cors, dotenv, express, firebase-admin, pg, description, devDependencies (+13 more)

### Community 1 - "daily_task_card.dart"
Cohesion: 0.08
Nodes (25): DailyTask, build, main, VerifAIApp, build, DailyTaskCard, dimension, _DimensionChip (+17 more)

### Community 2 - "index.js"
Cohesion: 0.50
Nodes (3): app, cors, express

### Community 3 - "app_colors.dart"
Cohesion: 0.05
Nodes (37): accentCyan, accentGreen, accentLight, ambientCyan, ambientGold, ambientGreen, AppColors, background (+29 more)

### Community 4 - "VerifAI"
Cohesion: 0.09
Nodes (21): About the Project, AI Workplace Readiness App, Backend setup, Branch naming, Database setup, Getting Started, Git Workflow, Industry Tracks (+13 more)

### Community 5 - "scoreboard_screen.dart"
Cohesion: 0.07
Nodes (35): ConsumerState, ConsumerStatefulWidget, currentUserProvider, dashboardProvider, build, _buildDashboard, _buildShimmer, createState (+27 more)

### Community 6 - "dimension_bar.dart"
Cohesion: 0.08
Nodes (28): IconData?, AppTypography, textTheme, build, icon, label, maxValue, progressColor (+20 more)

### Community 7 - "Screens Implemented — 9 Screens"
Cohesion: 0.08
Nodes (24): 1. Visual Philosophy & Core Pillars, 2. Design Tokens Reference, 3. Key Component Usage Guidelines, 4. Git Collaborator Guide (Rules for Adding Code), Auth Flow (3), Border Radii (`lib/core/theme/app_radius.dart`), Color Palette (`lib/core/theme/app_colors.dart`), `DailyTaskCard` (`lib/shared/widgets/daily_task_card.dart`) (+16 more)

### Community 8 - "score_ring.dart"
Cohesion: 0.10
Nodes (19): CustomPainter, dart:math, build, child, color, _getDefaultTier, _getScoreColor, maxScore (+11 more)

### Community 9 - "main_nav_shell.dart"
Cohesion: 0.11
Nodes (19): dart:ui, List, build, _buildNavItem, createState, _currentIndex, initialIndex, initState (+11 more)

### Community 10 - "app_radius.dart"
Cohesion: 0.12
Nodes (16): AppRadius, badge, button, card, fab, input, lg, md (+8 more)

### Community 11 - "profile_screen.dart"
Cohesion: 0.13
Nodes (15): authNotifierProvider, Color?, _Badge, build, _buildBentoStat, _buildModernBadgeTile, color, description (+7 more)

### Community 12 - "track_roadmap_screen.dart"
Cohesion: 0.15
Nodes (12): ConsumerWidget, _buildMilestoneCard, _buildNodeIndicator, description, icon, _Milestone, MilestoneStatus, status (+4 more)

### Community 13 - "Person 1 — Foundation Complete ✅"
Cohesion: 0.25
Nodes (8): Architecture, Core Packages, Design System (`lib/core/theme/`), Mock Backend (Swap-Ready) — `ApiClient` Interface, Models (Freezed + JSON Serializable) — 5 Models, Person 1 — Foundation Complete ✅, Secure Storage, Shared Widgets (`lib/shared/widgets/`) — 10 Components

## Knowledge Gaps
- **195 isolated node(s):** `Architecture`, `Core Packages`, `Design System (`lib/core/theme/`)`, `Shared Widgets (`lib/shared/widgets/`) — 10 Components`, `Models (Freezed + JSON Serializable) — 5 Models` (+190 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 225 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `VerifAI Mobile App` connect `Screens Implemented — 9 Screens` to `Person 1 — Foundation Complete ✅`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **What connects `Architecture`, `Core Packages`, `Design System (`lib/core/theme/`)` to the rest of the system?**
  _195 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `package.json` be split into smaller, more focused modules?**
  _Cohesion score 0.09090909090909091 - nodes in this community are weakly interconnected._
- **Should `daily_task_card.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07977207977207977 - nodes in this community are weakly interconnected._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05263157894736842 - nodes in this community are weakly interconnected._
- **Should `VerifAI` be split into smaller, more focused modules?**
  _Cohesion score 0.09090909090909091 - nodes in this community are weakly interconnected._
- **Should `scoreboard_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06606606606606606 - nodes in this community are weakly interconnected._