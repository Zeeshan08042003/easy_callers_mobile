# Project System - Major Architecture Update

## Summary of Changes

### Current Flow
- Manager uploads Excel → leads created directly → distributes to callers
- Super Admin creates managers directly
- No project concept; leads are just batches of files

### New Flow
1. **Super Admin/Manager creates a Project first** → then uploads Excel sheets into that project
2. **Super Admin creates project** → invites manager → manager accepts invitation → manager distributes leads
3. **Manager creates their own projects** → can optionally share with super admin (visibility toggle)
4. **Manager must accept invitation** to join a super admin's project

---

## Database Changes (Migration 012)

### New Tables

#### 1. `projects` table
```sql
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  subtitle TEXT,
  instruction TEXT,
  created_by_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL,
  created_by_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  -- Exactly one creator
  CONSTRAINT one_project_creator CHECK (
    ((created_by_super_admin_id IS NOT NULL)::int + 
     (created_by_manager_id IS NOT NULL)::int) = 1
  )
);
```

#### 2. `project_members` table (links managers to projects + invitation system)
```sql
CREATE TABLE public.project_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  manager_id UUID REFERENCES public.managers(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  visible_to_super_admin BOOLEAN DEFAULT false, -- For manager-created projects
  invited_by_super_admin_id UUID REFERENCES public.super_admins(id) ON DELETE SET NULL,
  invited_by_manager_id UUID REFERENCES public.managers(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(project_id, manager_id)
);
```

### Modified Tables

#### `lead_batches` → add `project_id`
```sql
ALTER TABLE public.lead_batches ADD COLUMN project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;
```

#### `leads` → add `project_id`
```sql
ALTER TABLE public.leads ADD COLUMN project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL;
```

---

## Dart Code Changes

### New Files to Create

1. **Model**: `lib/features/project/models/project_model.dart`
2. **Model**: `lib/features/project/models/project_member_model.dart`
3. **Service**: `lib/features/project/services/project_service.dart`
4. **Controller**: `lib/features/project/controllers/project_list_controller.dart`
5. **Controller**: `lib/features/project/controllers/create_project_controller.dart`
6. **Controller**: `lib/features/project/controllers/project_detail_controller.dart`
7. **View**: `lib/features/project/views/project_list_view.dart`
8. **View**: `lib/features/project/views/create_project_view.dart`
9. **View**: `lib/features/project/views/project_detail_view.dart`
10. **Binding**: `lib/features/project/bindings/project_binding.dart`
11. **View**: `lib/features/project/views/project_invitations_view.dart`
12. **Controller**: `lib/features/project/controllers/project_invitations_controller.dart`

### Files to Modify

1. **Routes**: `lib/app/routes/app_routes.dart` - Add project routes
2. **Constants**: `lib/core/constants/supabase_constants.dart` - Add table names
3. **Enums**: `lib/core/utils/enums.dart` - Add project/invitation enums
4. **Upload Service**: `lib/features/manager/services/lead_upload_service.dart` - Require project_id
5. **Lead Service**: `lib/features/manager/services/lead_service.dart` - Filter by project
6. **Manager Dashboard**: Controller & View - Add projects section
7. **Super Admin Dashboard**: Controller & View - Add projects section
8. **Lead Controller**: `lead_controller_controller.dart` - Filter by project

---

## Implementation Phases

### Phase 1: Database Migration
- Create migration `012_projects_system.sql`

### Phase 2: Models & Service
- Create ProjectModel, ProjectMemberModel
- Create ProjectService (CRUD, invitations, visibility)

### Phase 3: Project UI (Create & List)
- Project list view for both Super Admin and Manager
- Create project form
- Project detail view with Excel uploads

### Phase 4: Invitation System
- Invitation notifications
- Accept/Decline UI for managers
- Visibility toggle for manager-created projects

### Phase 5: Integration
- Modify lead upload to require project selection
- Update dashboards to show project-level stats
- Update lead views to filter by project
