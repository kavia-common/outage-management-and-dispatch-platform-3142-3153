# Smart Outage MVP - MySQL Schema & Seed Data

This database container runs **MySQL** (DB: `myapp`) and is accessible using the command in `db_connection.txt`:

```bash
mysql -u appuser -pdbuser123 -h localhost -P 5000 myapp
```

This document describes the **MVP schema** (tables/columns/relationships) and the **minimal seed data** inserted for development.

> Note: Tables are created with `ENGINE=InnoDB` and use foreign keys.

---

## Entity overview

- **organizations**: tenant boundary (MVP uses a single seeded org)
- **users**: operators, crew members, customers
- **crews**: groups of crew users
- **locations**: address + optional lat/lng
- **outages**: outage intake + lifecycle
- **jobs**: dispatch assignments linked to outages
- **job_status_events**: audit trail for job state changes
- **outage_updates**: outage timeline notes / events
- **notifications**: queue/history of notifications (in-app/push/sms/email)

---

## Tables

### organizations
- `id` CHAR(36) PK
- `name` VARCHAR(200)
- `created_at` TIMESTAMP

### users
- `id` CHAR(36) PK
- `organization_id` CHAR(36) FK → organizations.id
- `email` VARCHAR(320)
- `full_name` VARCHAR(200)
- `phone` VARCHAR(50) NULL
- `role` ENUM('operator','crew','customer','admin')
- `is_active` TINYINT(1)
- `created_at` TIMESTAMP
- Unique: `(organization_id, email)`

### crews
- `id` CHAR(36) PK
- `organization_id` CHAR(36) FK → organizations.id
- `name` VARCHAR(200)
- `lead_user_id` CHAR(36) NULL FK → users.id (SET NULL)
- `is_active` TINYINT(1)
- `created_at` TIMESTAMP

### locations
- `id` CHAR(36) PK
- `organization_id` CHAR(36) FK → organizations.id
- `address_line1` VARCHAR(200)
- `address_line2` VARCHAR(200) NULL
- `city` VARCHAR(120)
- `state` VARCHAR(120) NULL
- `postal_code` VARCHAR(30) NULL
- `country` VARCHAR(120) default 'US'
- `latitude` DECIMAL(9,6) NULL
- `longitude` DECIMAL(9,6) NULL
- `created_at` TIMESTAMP

### outages
- `id` CHAR(36) PK
- `organization_id` CHAR(36) FK → organizations.id
- `reported_by_user_id` CHAR(36) NULL FK → users.id (SET NULL)
- `customer_user_id` CHAR(36) NULL FK → users.id (SET NULL)
- `location_id` CHAR(36) FK → locations.id
- `title` VARCHAR(200)
- `description` TEXT NULL
- `severity` ENUM('low','medium','high','critical')
- `status` ENUM('new','triaged','dispatched','in_progress','resolved','cancelled')
- `started_at` DATETIME NULL
- `resolved_at` DATETIME NULL
- `created_at` TIMESTAMP
- `updated_at` TIMESTAMP (auto-update)

### jobs
- `id` CHAR(36) PK
- `organization_id` CHAR(36) FK → organizations.id
- `outage_id` CHAR(36) FK → outages.id (CASCADE)
- `assigned_crew_id` CHAR(36) NULL FK → crews.id (SET NULL)
- `assigned_to_user_id` CHAR(36) NULL FK → users.id (SET NULL)
- `status` ENUM('pending','assigned','en_route','on_site','completed','cancelled')
- `priority` ENUM('low','normal','high','urgent')
- `notes` TEXT NULL
- `created_at` TIMESTAMP
- `updated_at` TIMESTAMP (auto-update)

### job_status_events
- `id` BIGINT AI PK
- `job_id` CHAR(36) FK → jobs.id (CASCADE)
- `status` ENUM('pending','assigned','en_route','on_site','completed','cancelled')
- `changed_by_user_id` CHAR(36) NULL FK → users.id (SET NULL)
- `message` VARCHAR(500) NULL
- `created_at` TIMESTAMP

### outage_updates
- `id` BIGINT AI PK
- `outage_id` CHAR(36) FK → outages.id (CASCADE)
- `update_type` ENUM('note','status_change','system')
- `message` TEXT
- `created_by_user_id` CHAR(36) NULL FK → users.id (SET NULL)
- `created_at` TIMESTAMP

### notifications
- `id` BIGINT AI PK
- `organization_id` CHAR(36) FK → organizations.id
- `user_id` CHAR(36) NULL FK → users.id (SET NULL)
- `outage_id` CHAR(36) NULL FK → outages.id (SET NULL)
- `job_id` CHAR(36) NULL FK → jobs.id (SET NULL)
- `channel` ENUM('push','sms','email','in_app')
- `title` VARCHAR(200)
- `body` TEXT
- `status` ENUM('queued','sent','failed')
- `created_at` TIMESTAMP
- `sent_at` DATETIME NULL

---

## Seed data (minimal)

All IDs below are stable and intended for use by the backend/mobile app in development.

### organization
- Demo org:
  - `organizations.id` = `00000000-0000-0000-0000-000000000001`
  - `organizations.name` = `Demo Utility`

### users
- Operator:
  - `users.id` = `00000000-0000-0000-0000-000000000101`
  - `email` = `operator@demo.local`
  - `role` = `operator`
- Crew user:
  - `users.id` = `00000000-0000-0000-0000-000000000201`
  - `email` = `crew1@demo.local`
  - `role` = `crew`
- Customer user:
  - `users.id` = `00000000-0000-0000-0000-000000000301`
  - `email` = `customer1@demo.local`
  - `role` = `customer`

### crew
- Crew Alpha:
  - `crews.id` = `00000000-0000-0000-0000-000000000401`
  - `lead_user_id` = `00000000-0000-0000-0000-000000000201`

### location
- `locations.id` = `00000000-0000-0000-0000-000000000501`
- `100 Main St, Springfield, CA 90001`
- `lat/lng` = `34.052235, -118.243683`

### outage
- `outages.id` = `00000000-0000-0000-0000-000000000601`
- `title` = `Transformer outage near Main St`
- `severity` = `high`
- `status` = `new`

### job
- `jobs.id` = `00000000-0000-0000-0000-000000000701`
- `outage_id` = `00000000-0000-0000-0000-000000000601`
- `assigned_crew_id` = `00000000-0000-0000-0000-000000000401`
- `assigned_to_user_id` = `00000000-0000-0000-0000-000000000201`
- `status` = `assigned`
- `priority` = `high`

---

## Notes for backend/mobile devs

- The system currently uses **CHAR(36)** UUID strings (not binary UUIDs) for simplicity.
- Status/severity fields are enforced via ENUMs to match MVP workflow.
- To query demo outage + job quickly:

```sql
SELECT o.id AS outage_id, o.title, o.status, j.id AS job_id, j.status AS job_status
FROM outages o
JOIN jobs j ON j.outage_id = o.id;
```
