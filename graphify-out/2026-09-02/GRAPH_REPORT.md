# Graph Report - VerifAI  (2026-09-02)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 31 nodes · 28 edges · 9 communities (5 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `baedcf9e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- package.json
- main.dart
- index.js
- dependencies
- scripts
- dotenv
- express
- firebase-admin
- pg

## God Nodes (most connected - your core abstractions)
1. `scripts` - 3 edges
2. `nodemon` - 2 edges
3. `VerifAIApp` - 2 edges
4. `cors` - 2 edges
5. `dotenv` - 2 edges
6. `express` - 2 edges
7. `firebase-admin` - 2 edges
8. `pg` - 2 edges
9. `main` - 1 edges
10. `nodemon` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (9 total, 4 thin omitted)

### Community 0 - "package.json"
Cohesion: 0.25
Nodes (7): description, devDependencies, nodemon, main, name, version, nodemon

### Community 1 - "main.dart"
Cohesion: 0.40
Nodes (4): build, main, VerifAIApp, StatelessWidget

### Community 2 - "index.js"
Cohesion: 0.50
Nodes (3): app, cors, express

### Community 3 - "dependencies"
Cohesion: 0.67
Nodes (3): dependencies, cors, cors

### Community 4 - "scripts"
Cohesion: 0.67
Nodes (3): scripts, dev, start

## Knowledge Gaps
- **17 isolated node(s):** `description`, `main`, `name`, `version`, `nodemon` (+12 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 18 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `dependencies` connect `dependencies` to `package.json`, `dotenv`, `express`, `firebase-admin`, `pg`?**
  _High betweenness centrality (0.345) - this node is a cross-community bridge._
- **Why does `scripts` connect `scripts` to `package.json`?**
  _High betweenness centrality (0.090) - this node is a cross-community bridge._
- **What connects `description`, `main`, `name` to the rest of the system?**
  _17 weakly-connected nodes found - possible documentation gaps or missing edges._