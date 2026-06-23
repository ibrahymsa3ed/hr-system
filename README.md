# HR System

Bilingual (Arabic / English, RTL-aware) HR platform for web and mobile.

- **`api/`** — Laravel 11/13 REST API (PHP 8.4), MySQL/MariaDB, Sanctum auth, spatie roles.
- **`app/`** — Flutter client (one codebase → Web, iOS, Android) with biometric + GPS.

## Features

Dashboard · Branches (with GPS geofence) · Sections & Employees (section main-code +
employee sub-code, photos, age, insurance, *remaining papers*) · Attendance (geofenced
check-in/out, supervisor-records-for-phoneless, lateness/overtime) · Shift schedules &
shift-change approval (auto-applies hours) · Leave / permission / vacation with balances ·
Loans & advances (manager → HR director → finance) · Resignation · Daily & period reports ·
Performance appraisal (KPIs, goals, manager evaluation, turnover) · Recruitment (vacancies →
CV → interview → evaluation → hire) · Employee self-service (monthly hours, salary, requests) ·
Push reminders for missed punches.

## Roles

`employee` · `supervisor` (restaurant manager) · `section_manager` · `hr_director` ·
`finance` · `hr_admin`. Authorization is enforced **server-side** on every route; the client
only hides what the server also forbids. Salary and national ID are encrypted at rest and
revealed only to HR/Finance.

---

## Local development

### Backend (`api/`)

```bash
cd api
composer install
cp .env.example .env            # then set DB + APP_KEY
php artisan key:generate
php artisan migrate --seed       # seeds roles + demo org data (non-production)
php artisan serve                # http://localhost:8000
```

Local dev uses SQLite by default (zero-setup). Production uses MySQL — set the `DB_*` values
in `.env` (see `.env.example`). Migrations are DB-agnostic and run on both.

Demo logins (seeded, password `password`): `hr_admin@hr.test`, `supervisor@hr.test`,
`section_manager@hr.test`, `hr_director@hr.test`, `finance@hr.test`, `employee@hr.test`.

Run tests: `php artisan test`.

### Client (`app/`)

```bash
cd app
flutter pub get
flutter gen-l10n
# Web:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
# Android emulator (host is 10.0.2.2):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Switch Arabic/English with the translate icon — the UI flips to RTL automatically.

---

## Production deployment (recommended: DigitalOcean, low-ops)

1. **Database** — DigitalOcean Managed MySQL 8 (or MariaDB). Pick the region nearest users
   (e.g. Frankfurt). Create DB `hr_system` and a least-privilege user.
2. **API** — DigitalOcean App Platform from `api/` (or Laravel Cloud / Forge + droplet):
   - Set env from `.env.example`: `APP_KEY`, `DB_*`, `APP_URL`, `FILESYSTEM_CLOUD=s3`, S3
     (`AWS_*`) for **Spaces/R2**, and `FCM_SERVER_KEY`.
   - Build: `composer install --no-dev -o`; run `php artisan migrate --force` on release.
   - Run the scheduler (`php artisan schedule:run` every minute via cron / a worker) so
     `hr:missing-punch-reminders` fires, and a queue worker (`php artisan queue:work`).
3. **Storage** — DigitalOcean Spaces or Cloudflare R2 for employee photos & documents.
4. **Push** — Firebase project; set `FCM_SERVER_KEY`. For iOS, upload the APNs key in Firebase.
5. **Client** — `flutter build web` (host on App Platform static site / CDN) and
   `flutter build apk` / `ipa` for internal distribution. Point `API_BASE_URL` at the API.

### Security checklist
- `APP_DEBUG=false`, HTTPS enforced, `APP_KEY` set (encrypts salary/national ID).
- Sanctum tokens; rotate on logout/role change. Login is rate-limited (`throttle:10,1`).
- Geofence validated server-side; mock-location rejected where detectable.
- All approvals are append-only audit records.
