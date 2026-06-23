# HR System

Bilingual (Arabic/English, RTL-aware) HR platform — **Laravel 13 REST API** + **Flutter client** (Web, Android, iOS from one codebase).

**Live demo:** https://app.130.110.111.198.nip.io  
**API:** https://hr.130.110.111.198.nip.io/api

---

## Project Structure

```
hr-system/
├── api/                          # Laravel 13 REST API (PHP 8.4)
│   ├── app/
│   │   ├── Http/Controllers/Api/ # All REST controllers (see table below)
│   │   ├── Http/Middleware/       # EnsureRole (RBAC), SetLocale (ar/en)
│   │   ├── Models/                # Eloquent models + Approvable trait
│   │   └── Services/              # ApprovalService, AttendanceService, PushNotifier
│   ├── config/hr.php              # ★ Domain config: roles, approval chains, leave, attendance
│   ├── database/migrations/       # 12 migrations (org, attendance, leave, approvals, etc.)
│   ├── database/seeders/          # Demo data: users, branch, sections, employees
│   ├── lang/{en,ar}/              # API response translations
│   ├── routes/api.php             # All API routes (role-gated)
│   └── tests/Feature/             # Integration tests
│
├── app/                          # Flutter client
│   └── lib/
│       ├── core/                  # API client, auth, config, GPS, locale, date utils
│       ├── l10n/                  # Arabic/English translations (.arb + generated)
│       └── features/              # Feature screens (see table below)
│           ├── auth/              # Login + biometric
│           ├── home/              # Shell + role-filtered drawer
│           ├── dashboard/         # Stats cards
│           ├── attendance/        # Check-in/out, history, supervisor recording
│           ├── employees/         # CRUD + documents + detail
│           ├── requests/          # Leave, loan, resignation, shift change
│           ├── approvals/         # Pending approval actions
│           ├── reports/           # Daily & period attendance reports
│           ├── performance/       # KPIs, goals, reviews
│           ├── recruitment/       # Vacancies, candidates, interviews, hire
│           ├── self_service/      # Monthly hours, salary, leave balances
│           ├── organization/      # Branches & sections CRUD
│           └── compensation/      # Salary/insurance history
│
└── README.md
```

---

## Architecture

```
┌─────────────────────┐    Sanctum Token     ┌────────────────────────────────┐
│  Flutter Client     │ ──────────────────► │  Laravel API                    │
│  • Provider state   │ ◄── JSON + i18n ─── │  • routes/api.php (role-gated)  │
│  • Dio HTTP client  │   Accept-Language    │  • EnsureRole middleware        │
│  • GPS geolocation  │                      │  • ApprovalService (chains)     │
│  • Biometric auth   │                      │  • AttendanceService (geofence) │
└─────────────────────┘                      │  • PushNotifier (FCM)           │
                                             └────────────────────────────────┘
                                                        │
                                              config/hr.php
                                              (roles, approval chains,
                                               leave types, attendance rules)
```

---

## Roles & Permissions

| Role | Access |
|------|--------|
| `employee` | Self-service: check-in/out, view salary, leave balances, submit requests |
| `supervisor` | Above + record attendance for phoneless employees, submit shift changes |
| `section_manager` | Above + approve leaves, view section reports |
| `hr_director` | Above + approve loans (step 2), all reports |
| `finance` | Approve loans (step 3), view salary/compensation data |
| `hr_admin` | Full access: manage employees, branches, sections, recruitment, all CRUD |

Authorization is enforced **server-side** on every route. The client only hides what the server also forbids.

---

## API Controllers

| Controller | Purpose |
|------------|---------|
| `AuthController` | Login (Sanctum token), `/me` profile, logout, FCM device registration |
| `DashboardController` | Headcount stats, today's attendance, pending approvals |
| `AttendanceController` | GPS check-in/out, supervisor recording, attendance listing |
| `EmployeeController` | Full CRUD + auto-creates User login on employee creation |
| `BranchController` | Branches with GPS geofence coordinates |
| `SectionController` | Sections with unique main codes |
| `LeaveRequestController` | Leave/vacation/permission requests → approval chain |
| `LoanRequestController` | Loan/advance requests → 3-step approval |
| `ResignationRequestController` | Resignation requests |
| `ShiftChangeRequestController` | Shift change → HR approval → auto-applies |
| `ApprovalController` | View pending approvals, approve/reject |
| `ReportController` | Daily & period attendance reports |
| `PerformanceReviewController` | KPIs, goals, manager evaluation, turnover risk |
| `SelfServiceController` | Employee monthly hours, salary, leave balances |
| `CompensationRecordController` | Salary/insurance history per employee |
| `EmployeeDocumentController` | Remaining papers upload/tracking |
| `ShiftScheduleController` | Per-employee shift schedules |
| **Recruitment/** | `JobVacancyController`, `CandidateController`, `InterviewController`, `CandidateEvaluationController` |

---

## Key Services

| Service | What it does |
|---------|-------------|
| **ApprovalService** | Config-driven multi-step approval chains. Reads `config/hr.php` approval_chains, creates ordered steps, enforces role + sequence, settles request as approved/rejected |
| **AttendanceService** | Haversine geofence validation, check-in/out, lateness calculation from shift schedule, overtime tracking, supervisor override path |
| **PushNotifier** | FCM push notifications to user device tokens |

---

## Models & Approval Engine

Models using the `Approvable` trait (polymorphic approval):
- `LeaveRequest` — 2-step: supervisor → section_manager
- `LoanRequest` — 3-step: section_manager → hr_director → finance
- `ShiftChangeRequest` — 1-step: hr_director
- `ResignationRequest` — 1-step: hr_director

All approval chains are configured in `config/hr.php` and can be changed without code modifications.

---

## Database

12 migrations creating these key tables:

| Group | Tables |
|-------|--------|
| Organization | `branches`, `sections`, `employees`, `employee_documents` |
| Attendance | `shift_schedules`, `attendance_records`, `shift_change_requests` |
| Leave & Compensation | `leave_ledgers`, `leave_requests`, `compensation_records`, `loan_requests`, `resignation_requests` |
| Approvals | `approval_steps` (polymorphic) |
| Performance | `performance_reviews` |
| Recruitment | `job_vacancies`, `candidates`, `interviews`, `candidate_evaluations` |
| Auth | `users`, `personal_access_tokens`, `roles`, `permissions` |

Sensitive fields (`basic_salary`, `national_id`) are **encrypted at rest** and only revealed to HR/Finance roles.

---

## Local Development

### Backend (`api/`)

```bash
cd api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed    # seeds roles + demo data
php artisan serve             # http://localhost:8000
```

SQLite by default (zero-setup). For MySQL, set `DB_*` in `.env`.

**Demo logins** (password: `password`):
`hr_admin@hr.test`, `supervisor@hr.test`, `section_manager@hr.test`, `hr_director@hr.test`, `finance@hr.test`, `employee@hr.test`

Run tests: `php artisan test`

### Client (`app/`)

```bash
cd app
flutter pub get
flutter gen-l10n

# Web (local API):
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api

# Android emulator (host is 10.0.2.2):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Production build (uses default production URL):
flutter build web --release
flutter build apk --release
```

Toggle Arabic/English with the language icon — UI flips to RTL automatically.

---

## Production Deployment

Currently deployed on **Oracle Cloud Always Free** VM:
- Ubuntu 22.04, PHP 8.4-FPM, Caddy (auto HTTPS via Let's Encrypt)
- SQLite database (saves RAM on 1GB micro instance)
- API: `https://hr.130.110.111.198.nip.io/api`
- Web app: `https://app.130.110.111.198.nip.io`

### Deploy steps:
1. SSH into VM, pull latest code to `/home/ubuntu/hr-api`
2. `composer install --no-dev -o`
3. `php artisan migrate --force`
4. `php artisan route:cache && php artisan config:cache`
5. Build Flutter web locally → `rsync` to `/home/ubuntu/hr-web/`

### Security checklist
- `APP_DEBUG=false`, HTTPS enforced, `APP_KEY` set (encrypts salary/national ID)
- Sanctum tokens; login rate-limited (`throttle:10,1`)
- Geofence validated server-side
- All approvals are append-only audit records

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Laravel 13, PHP 8.4, Sanctum, spatie/laravel-permission, intervention/image |
| Frontend | Flutter 3.44, Dart 3.12, Material 3, Provider, Dio |
| Database | SQLite (dev/free tier) / MySQL (production) |
| Auth | Sanctum API tokens + optional biometric unlock |
| Server | Caddy reverse proxy, PHP-FPM, Ubuntu 22.04 |
| i18n | Arabic + English, RTL-aware, server + client localized |
