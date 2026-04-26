# Classroom Console

Classroom Console is a Rails-based administrative tool for syncing data and grades between **Blackbaud's OnCampus** (school's primary SIS/LMS) and **Canvas LMS** (supplementary LMS used by some teachers). Built over 6 years, it manages the complexity of keeping two separate learning systems in sync while maintaining grade passback capabilities.

## Project Status

- **Current migration**: Transitioning from OnCampus (ON) API to OneRoster + SKY APIs
- **Branch strategy**: Features on `oneroster` branch, main production code on `main`
- **Active deployment**: Digital Ocean Ubuntu 20.04 with Passenger/Nginx
- **Monitoring**: Sidekiq job scheduler in web UI

## Core Architecture

### Main Sync Flow

The bulk of synchronization happens in `models/course.rb:23` via `Course.full_sync`:

```ruby
SchoolYear.sync_sis_school_years
User.sync_sis_users
Course.refresh_sis_courses
Section.refresh_sis_sections
Term.sync_terms
Course.sync_all_sis_enrollments
User.sync_canvas_users
```

### Key Models

- **Course**: Represents OnCampus offerings; has many sections
- **Section**: Individual class instances; has many enrollments and syncs to Canvas
- **User**: Staff and students; syncs between Canvas and OnCampus
- **SchoolYear**: Container for terms and courses
- **Term**: Academic periods (semesters, quarters, etc.)
- **Enrollment**: Links users to sections with grades and role (teacher/student)
- **SyncProfile**: Configuration for which courses sync to which Canvas accounts
- **Subscription**: Links schools/organizations to Canvas instances
- **AdminSetting**: Stores API credentials and configuration

### Supporting Data

- **Event** / **Log**: Audit trail of sync actions
- **GradeChange**: Tracks grade modifications for passback
- **Quarantine**: Flags problematic enrollments to prevent sync
- **Assignment**: Minimal model (mostly unused in recent commits)

## API Integrations

### OnCampus (ON) API
- **Helper**: `app/helpers/on_api_helper.rb`
- **Controller**: `app/controllers/on_api_controller.rb`
- **Currently used for**: Syncing school years, users, courses, sections, assignments, grades
- **Auth**: API key + secret stored in `AdminSetting`
- **Status**: Core sync still relies on this; being phased out

### Canvas API
- **Helper**: `app/helpers/canvas_api_helper.rb`
- **Mostly handles**: User creation, section/course creation in Canvas
- **Auth**: Bearer token stored in `AdminSetting`
- **Used by**: Courses, sections, and users models

### OneRoster (Future)
- **Credentials**: `oneroster_key`, `oneroster_secret` columns already in `admin_settings`
- **Plan**: Add OneRoster endpoints to replace ON API calls
- **Branch**: Work in progress on `oneroster` branch

### SKY APIs (Future Phase)
- Planned but not yet integrated

## Background Jobs

Managed via **Sidekiq** (Redis-backed):

- `SyncCanvasEnrollmentsJob`: Runs every 10 minutes (the heartbeat of the system)
- `SyncAllTeacherEnrollmentsJob`: Teacher enrollment syncs
- `SyncTeacherEnrollmentsJob`: Individual teacher enrollment
- `SyncSubscriptionsJob`: Syncs subscription configurations
- `SyncSisCoursesJob`: Refreshes OnCampus courses
- `SyncSisSectionsJob`: Refreshes OnCampus sections
- `RequestCanvasDataJob`, `RequestSisDataJob`: Fetch data from APIs
- `RequestSisAssignmentsJob`: Fetch assignment data
- `GenerateSampleDataJob`: Dev/testing utility

## Web Interface

**Authentication**: Devise (email + password)

### Key Pages

- `/courses`: Browse/sync courses with Canvas
  - `GET /full_sync`: Trigger complete sync flow
  - `GET /sync_all_sis_enrollments`: Enroll all users
  - `GET /sync_with_canvas`: Sync specific course
- `/sections`: Manage individual sections
  - `GET /sync`: Sync section to Canvas
  - `GET /create_canvas_course`: Create Canvas course
  - `GET /sync_sis_assignments`: Fetch assignments
- `/users`: View users, trigger syncs
- `/school_years`: Manage academic years
- `/terms`: Manage terms
- `/admin`: Configuration (API credentials, settings)
- `/on_api`: Debug view for ON API responses (GET endpoints only)
- `/verify`: Public verification endpoint
- Sidekiq dashboard: Monitor background jobs

## Typical Year Setup

1. **Fall (August)**: 
   - Admin enters new school year in OnCampus
   - Run `/full_sync` to pull users, courses, terms
   - Manually select which courses to sync via `sync_course` checkbox
   - Teachers create Canvas courses or use detected ones

2. **Ongoing**:
   - `SyncCanvasEnrollmentsJob` runs every 10 minutes
   - Grade changes sync back via `GradeChange` tracking
   - Manual fixes via web UI as needed (quarantine, re-sync sections, etc.)

3. **During Year**:
   - New courses added to OnCampus picked up automatically
   - New enrollments synced on schedule
   - Teachers can view/fix sync issues in `/courses` or `/sections`

## Development Environment

- **Ruby**: 3.1.2
- **Rails**: 7.0.3+
- **Database**: PostgreSQL (configurable)
- **Frontend**: Importmap-Rails, Turbolinks, Sass
- **Testing**: RSpec with FactoryBot
- **Deploy**: Capistrano (config in `config/deploy/production.rb`)
- **Secrets**: Rails encrypted credentials + `.rbenv-vars` on production

### Setup

```bash
git clone https://github.com/jefamirault/classroom_console.git
cd classroom_console
bundle
cp .env.example .env
# Edit .env with your institution's values
rails db:create
rails s
# Visit localhost:3000
```

### Environment Variables

Copy `.env.example` to `.env` and fill in your institution's values:

- **DATABASE_USER** / **DATABASE_PASSWORD**: PostgreSQL credentials
- **CANVAS_PATH**: Canvas instance URL (e.g., `https://institution.instructure.com`)
- **CANVAS_ACCESS_TOKEN**: Canvas API token
- **ON_API_PATH**: OnCampus/Blackbaud API endpoint
- **ON_API_USERNAME**, **ON_API_KEY**, **ON_API_SECRET**: OnCampus API credentials
- **ONEROSTER_KEY** / **ONEROSTER_SECRET**: OneRoster credentials (for future migration)
- **PRODUCTION_IP**, **DEPLOY_USER**: Deployment configuration (for Capistrano)

See `.env.example` for a complete template.

## Key Files Map

| File | Purpose |
|------|---------|
| `models/course.rb` | Main sync orchestration |
| `models/section.rb` | Canvas section creation + enrollment |
| `models/user.rb` | User sync between OnCampus and Canvas |
| `models/enrollment.rb` | Grade passback tracking |
| `helpers/on_api_helper.rb` | OnCampus API wrapper |
| `helpers/canvas_api_helper.rb` | Canvas API wrapper |
| `app/controllers/courses_controller.rb` | Course sync UI |
| `app/jobs/sync_canvas_enrollments_job.rb` | Main background sync |
| `config/deploy.rb` | Capistrano deployment |
| `db/schema.rb` | Data model definition |

## FERPA Compliance & Security

**Critical**: This system stores student education records protected under FERPA (Family Educational Rights and Privacy Act). Compliance is mandatory.

### Current State
- ✅ Audit logging via Events/Logs system
- ✅ User authentication via Devise
- ✅ Quarantine feature for isolating problematic records
- ⚠️ **No automated data retention/deletion process**
- ⚠️ **No encryption at rest for sensitive data**
- ⚠️ **No explicit data minimization controls**
- ⚠️ **Limited role-based access control (all admins see all data)**

### Required Capabilities (Not Yet Implemented)

1. **Right to be Forgotten**: Ability to permanently delete a student's records from the system upon request
   - Need: Method to remove user records and cascade delete related enrollments, grades, logs
   - Challenge: Maintains audit trail (Events/Logs) to comply with retention requirements
   
2. **Data Security**:
   - Encrypt PII at rest (names, emails, SSNs if stored)
   - Secure API credential storage (currently plaintext in admin_settings table)
   - TLS/SSL for all data in transit (should already be enforced)

3. **Access Control**:
   - Role-based permissions (currently all admins have full access)
   - Limit teacher access to their own section grades
   - Audit who accessed what data and when

4. **Data Retention Policy**:
   - Define how long records are kept after graduation/withdrawal
   - Automate deletion of records outside retention window
   - Retain audit logs separately from personal data

### Recommended Next Steps

- [ ] Add FERPA compliance checklist to deployment docs
- [ ] Implement encrypted fields for SSN/sensitive identifiers
- [ ] Create user deletion workflow with cascade delete
- [ ] Add role-based access control
- [ ] Implement data retention policy with automated cleanup
- [ ] Regular FERPA audit (annually recommended)
- [ ] Data breach response plan

See `config/deploy.rb` and `admin_settings` table for credential handling improvements.

## Known Quirks & Limitations

1. **Incomplete migration to OneRoster**: Credentials are present but not yet integrated
2. **API design**: Helper methods mix HTTP concerns with business logic (consider separating to service layer)
3. **Grade passback**: Only works one-way (Canvas → OnCampus); limited to supported assignment types
4. **Quarantine feature**: Used to pause problematic enrollments, but cleanup is manual
5. **Test coverage**: Limited—mostly helpers and controllers tested
6. **Admin page**: Basic config interface; lacks validation/error handling
7. **Multi-tenancy**: System is single-tenant per deployment (one school per instance)
8. **FERPA compliance**: No automated data deletion/retention process (see above)

## Common Tasks

### Debug a sync failure
1. Check Sidekiq dashboard for job errors
2. Review `/events` audit log for what failed
3. Check `/admin` settings for expired credentials
4. Use `/on_api` endpoint to test API connectivity

### Fix a specific student enrollment
1. Find section in `/sections`
2. Check Canvas enrollment status
3. Use quarantine if needed to pause sync
4. Run `/sync` on section to re-attempt

### Add a new school year
1. Create in OnCampus
2. Go to `/school_years` → Sync
3. Set `sync_course` = true on desired courses
4. Monitor `/full_sync` or run manually

### Deploy changes
```bash
cap production deploy
```

## Migration Roadmap

1. **Phase 1** (in progress): Add OneRoster endpoints alongside ON API
2. **Phase 2**: Hotfixes on current version as needed
3. **Phase 3**: Duplicate ON endpoint usage with OneRoster alternatives
4. **Phase 4**: Migrate to SKY APIs for remaining operations

## Open Source & Multi-Tenant Safety

This codebase is open source and designed to be reusable by other institutions. To maintain security and portability:

### For Contributors & Forks

1. **Never hard-code institution-specific values**
   - No IP addresses, domain names, Canvas URLs, or OnCampus endpoints
   - No usernames, API keys, or tokens
   - All configuration must come from environment variables

2. **Update deploy configuration when forking**
   - Edit `config/deploy.rb` line 7 to point to your fork: `set :repo_url, "https://github.com/YOUR_ORG/classroom_console.git"`
   - Ensure `.rbenv-vars` is created on your production server with real credentials (never commit this)

3. **Environment variables are your responsibility**
   - Copy `.env.example` to `.env` and fill with your institution's values
   - `.env` is in `.gitignore` — it's safe to use for development but never commit it
   - Production credentials go in `.rbenv-vars` on the server

4. **Secrets management**
   - Rails encrypted credentials are in `config/credentials.yml.enc` (encrypted, safe to commit)
   - Database credentials: use environment variables only
   - API tokens: store in environment variables or `.rbenv-vars`, never in code

### Sensitive Data Handling

**Note**: The current `AdminSetting` model stores Canvas tokens and OnCampus secrets in plaintext in the database. For enhanced security, consider encrypting these fields using Rails `encrypted` attribute or a similar mechanism before production use.

---

**Last updated**: April 2026 | **Current branch**: oneroster
