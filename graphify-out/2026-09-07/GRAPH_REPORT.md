# Graph Report - VerifAI  (2026-09-04)

## Corpus Check
- 8 files · ~1,400 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 53 nodes · 49 edges · 7 communities
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cbe99795`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- package.json
- main.dart
- index.js
- dependencies
- VerifAI
- Getting Started
- Knowledge Graph (Graphify)

## God Nodes (most connected - your core abstractions)
1. `VerifAI` - 9 edges
2. `Knowledge Graph (Graphify)` - 5 edges
3. `Getting Started` - 5 edges
4. `About the Project` - 3 edges
5. `Git Workflow` - 3 edges
6. `scripts` - 3 edges
7. `nodemon` - 2 edges
8. `VerifAIApp` - 2 edges
9. `cors` - 2 edges
10. `dotenv` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (7 total, 0 thin omitted)

### Community 0 - "package.json"
Cohesion: 0.18
Nodes (10): description, devDependencies, nodemon, main, name, scripts, dev, start (+2 more)

### Community 1 - "main.dart"
Cohesion: 0.40
Nodes (4): build, main, VerifAIApp, StatelessWidget

### Community 2 - "index.js"
Cohesion: 0.50
Nodes (3): app, cors, express

### Community 3 - "dependencies"
Cohesion: 0.18
Nodes (11): dependencies, cors, dotenv, express, firebase-admin, pg, cors, dotenv (+3 more)

### Community 4 - "VerifAI"
Cohesion: 0.17
Nodes (11): About the Project, AI Workplace Readiness App, Branch naming, Git Workflow, Industry Tracks, Project Structure, Step-by-step process, Team — Group SE16 (+3 more)

### Community 5 - "Getting Started"
Cohesion: 0.40
Nodes (5): Backend setup, Database setup, Getting Started, Mobile setup, Prerequisites

### Community 6 - "Knowledge Graph (Graphify)"
Cohesion: 0.40
Nodes (5): Install (one-time, per contributor), Keeping the graph current, Knowledge Graph (Graphify), Querying the graph, What it does

## Knowledge Gaps
- **33 isolated node(s):** `AI Workplace Readiness App`, `The Five Readiness Dimensions`, `Industry Tracks`, `Tech Stack`, `Project Structure` (+28 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 35 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `VerifAI` connect `VerifAI` to `Getting Started`, `Knowledge Graph (Graphify)`?**
  _High betweenness centrality (0.139) - this node is a cross-community bridge._
- **Why does `dependencies` connect `dependencies` to `package.json`?**
  _High betweenness centrality (0.113) - this node is a cross-community bridge._
- **Why does `Knowledge Graph (Graphify)` connect `Knowledge Graph (Graphify)` to `VerifAI`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **What connects `AI Workplace Readiness App`, `The Five Readiness Dimensions`, `Industry Tracks` to the rest of the system?**
  _33 weakly-connected nodes found - possible documentation gaps or missing edges._