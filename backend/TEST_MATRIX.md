# Backend Test Matrix

| Area | Test | Expected |
|---|---|---|
| Health | DB available | 200 + `status=ok` |
| Health | DB unavailable | 503 + `status=degraded` |
| Auth | Missing bearer token | 401 |
| Auth | Invalid/expired token | 401 |
| Sync | New Firebase user | User created |
| Sync | Existing Firebase user | User updated without duplicate |
| Tracks | List tracks | Four seeded tracks |
| Profile | Unknown user | 404 |
| Profile | Invalid track | 400 |
| Tasks | No selected track | 400 |
| Tasks | Unseen task | 200 with no `correct_answer` |
| Tasks | No remaining tasks | 200 with `task=null` |
| Attempt | Invalid task ID | 400 |
| Attempt | Missing answer | 400 |
| Attempt | Unknown task | 404 |
| Attempt | Valid answer | 201 + score + feedback |
| Attempt | Score update | Skill score changes |
| Attempt | Progress update | XP/level/streak change |
| Attempt | Transaction failure | No partial updates |
| Progress | Authenticated user | Overall + dimensions + XP/level/streak |
| Achievements | Authenticated user | Earned achievements returned |
| Security | Correct-answer leakage | Never returned by `/tasks/next` |
| Security | SQL injection strings | Parameters remain bound; no string concatenation |
| HTTP | Unknown route | 404 |
