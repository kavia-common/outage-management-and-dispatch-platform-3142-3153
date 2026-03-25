# MVP Schema Applied (MySQL)

The MySQL MVP schema + minimal seed data for the Smart Outage system is applied by:

- `database/startup.sh` (creates tables, indexes, foreign keys; then seeds demo org/users/crew/location/outage/job + audit rows)
- Schema spec reference: `database/SMART_OUTAGE_MVP_SCHEMA.md`

## Tables created

- organizations
- users
- crews
- locations
- outages
- jobs
- job_status_events (audit)
- outage_updates (audit/timeline)
- notifications

## Seed data (stable IDs)

Matches `SMART_OUTAGE_MVP_SCHEMA.md`:
- Org `00000000-0000-0000-0000-000000000001`
- Operator `...0101`
- Crew user `...0201`
- Customer `...0301`
- Crew `...0401`
- Location `...0501`
- Outage `...0601`
- Job `...0701`

## How to verify

Use `db_connection.txt`, then:

```sql
SELECT o.id AS outage_id, o.title, o.status, j.id AS job_id, j.status AS job_status
FROM outages o
JOIN jobs j ON j.outage_id = o.id;
```
