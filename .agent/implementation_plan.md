# Easy Callers – Implementation Plan

## Status: Phase 1 ✅ COMPLETE

---

## 📋 Business Rules (Confirmed)

| Rule | Decision |
|------|----------|
| Lead reassignment | ✅ Yes, leads can be reassigned between employees |
| Employee limit per manager | No limit for now; future: controlled by plans |
| Deactivated employee leads | Manager gets notified, can reassign leads manually |
| Super Admin acting as Manager | ✅ Yes, with confirmation dialog for every change + notification to affected manager |
| UI Navigation | Will be decided later (backend-first approach) |
| Color scheme | Will be decided later (backend-first approach) |

---

## 🗄️ Phase 1: Foundation ✅ DONE

### What was built:

#### Database Schema (`supabase/migrations/004_separate_role_tables.sql`)
- **Separate Role Tables**: `super_admins`, `managers`, `employees`
- **Data Tables**: `leads`, `lead_batches`, `call_logs`, `daily_reports`, `notifications`, `activity_log`
- **Indexes** on all frequently queried columns 
- **Triggers** for auto-updating `updated_at` on all user and data tables
- **Row Level Security (RLS)** policies strictly scoped to roles and ownership
- **Storage bucket** `lead-files` for uploaded Excel/PDF files

#### Models (`lib/core/models/`)
- `SuperAdminModel` - fields for system administrators
- `ManagerModel` - fields for team managers (max employees, initials)
- `EmployeeModel` - fields for callers (manager reference, OTP state)
- `LeadModel` - with flexible join support for managers/employees
- `LeadBatchModel` - upload batch tracking
- `CallLogModel` - with follow-up tracking (isDueToday, isOverdue)
- `DailyReportModel` - with computed metrics (connectionRate, formatted durations)
- `NotificationModel` - role-based routing (user_type + user_id)

#### Services (`lib/core/services/`)
- `SupabaseService` - Singleton client wrapper with table/storage helpers and role detection
- `AuthService` - 3-table auth: sequential role detection, OTP activation, and manager/employee creation
- `LeadService` - Complete CRUD with support for new separate table joins
- `LeadUploadService` - Flexible Excel parsing (Format 1: Sr No, Format 2: Split Names)
- `NotificationService` - Local push notifications

#### Auth Screens (`lib/features/auth/`)
- `NewLoginScreen` - Email/password login for all roles
- `OTPScreen` - 6-digit OTP verification for employee activation
- `SetPasswordScreen` - Password setup after OTP verification
- `AuthController` - Role-based routing, form validation

#### Infrastructure
- `AppRoutes` - All named routes for the entire app
- `AppPages` - GetX page registry
- `InitialBinding` - Dependency injection setup
- Enums: `UserRole`, `LeadStatus`, `CallStatus`, `CallLeadStatus`, `NotificationType`

#### Dependencies Added
- `supabase_flutter` - Backend
- `file_picker` + `excel` - File handling
- `fl_chart` - Charts & reports
- `flutter_local_notifications` - Reminders
- `shared_preferences` - Local storage
- `intl` - Date formatting
- `uuid` - ID generation

---

## � Next Steps

### Action Items for YOU:
1. **Run the database migration** in Supabase SQL Editor:
   - Go to: [SQL Editor](https://supabase.com/dashboard)
   - Copy & paste `supabase/migrations/004_separate_role_tables.sql`
   - Click "Run"

2. **Create Super Admin auth user**:
   - Go to: Authentication → Users → "Add User"
   - Email: `zeeshan.easycaller@gmail.com`
   - Password: (choose a secure password)
   - Check "Auto Confirm User"
   - Copy the user's UUID

3. **Seed the Super Admin**:
   - Open `supabase/migrations/002_seed_super_admin.sql`
   - Replace `AUTH_USER_UUID_HERE` with the UUID from step 2
   - Run it in SQL Editor

4. **Share the sample Excel/PDF** when available (for fine-tuning the parser)

---

## � Remaining Phases

### Phase 2: Auth Testing & Session (Next)
- [ ] Test the login flow end-to-end with Super Admin
- [ ] Session persistence (auto-login on app restart)
- [ ] Auth middleware for route protection

### Phase 3: Super Admin Panel
- [ ] Dashboard with aggregate stats
- [ ] Add/manage managers
- [ ] Drill into manager data
- [ ] Confirmation dialogs for Super Admin changes
- [ ] Auto-notify managers of Super Admin changes

### Phase 4: Manager – Lead Upload & Assignment
- [ ] Upload leads UI
- [ ] View uploaded batches
- [ ] Split/assign leads (equal or custom)
- [ ] Lead overview with filters

### Phase 5: Manager – Employee Management
- [ ] Add employee + OTP via Brevo
- [ ] Employee list
- [ ] Employee call history & last called data
- [ ] Monthly reports (table + graphs)
- [ ] Average call time per employee

### Phase 6: Employee – Calling & Feedback
- [ ] Enhance existing dashboard with Supabase data
- [ ] Assigned leads list
- [ ] Post-call feedback screen
- [ ] Call history

### Phase 7: Follow-up Reminders
- [ ] Schedule local notifications
- [ ] Follow-up list screen
- [ ] Auto-reschedule missed follow-ups

### Phase 8: Reports & Analytics
- [ ] Daily report auto-generation
- [ ] Monthly graphs (fl_chart)
- [ ] Cross-team analytics for Super Admin

### Phase 9: Polish
- [ ] UI design (once you provide the designs)
- [ ] Realtime updates
- [ ] Error handling
- [ ] Performance optimization

---

*Last Updated: February 12, 2026*
