# Quick Reference: File Organization by Role

## 📁 Where to Find Files

### Super Admin Files
**Location**: `lib/features/super_admin/`

- **Models**: `lib/features/super_admin/models/`
  - `super_admin_model.dart` - Super admin user model
  - `manager_model.dart` - Manager model (used by super admin)
  - `system_settings_model.dart` - System-wide settings

- **Services**: `lib/features/super_admin/services/`
  - `system_service.dart` - System-wide operations

- **Features**:
  - `dashboard/` - Super admin dashboard
  - `managers/` - Manager management (add, list, oversight)
  - `reports/` - System reports
  - `settings/` - System settings

### Manager Files
**Location**: `lib/features/manager/`

- **Models**: `lib/features/manager/models/`
  - `employee_model.dart` - Employee model
  - `lead_model.dart` - Lead/contact model
  - `lead_batch_model.dart` - Batch lead operations

- **Services**: `lib/features/manager/services/`
  - `lead_service.dart` - Lead management operations
  - `lead_upload_service.dart` - Lead upload/import

- **Features**:
  - `dashboard/` - Manager dashboard
  - `employees/` - Employee management (team view, details)
  - `leads/` - Lead management (distribution, control)
  - `reports/` - Manager reports

### Employee Files
**Location**: `lib/features/employee/`

- **Models**: `lib/features/employee/models/`
  - `call_log_model.dart` - Call log records
  - `daily_report_model.dart` - Daily activity reports
  - `notification_model.dart` - Notifications

- **Services**: `lib/features/employee/services/`
  - `notification_service.dart` - Notification handling

- **Features**:
  - `dashboard/` - Employee dashboard
  - `feedback/` - Call feedback

### Shared/Core Files
**Location**: `lib/core/`

- **Services**: `lib/core/services/`
  - `auth_service.dart` - Authentication (used by all roles)
  - `auth_service_improved.dart` - Improved auth implementation
  - `supabase_service.dart` - Supabase database operations

- **Other**:
  - `constants/` - App-wide constants
  - `theme/` - App theming
  - `utils/` - Utility functions
  - `widgets/` - Shared widgets

## 📝 Import Path Examples

### Super Admin
```dart
// Models
import 'package:easy_callers_mobile/features/super_admin/models/super_admin_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/system_settings_model.dart';

// Services
import 'package:easy_callers_mobile/features/super_admin/services/system_service.dart';
```

### Manager
```dart
// Models
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';

// Services
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_upload_service.dart';
```

### Employee
```dart
// Models
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/employee/models/daily_report_model.dart';
import 'package:easy_callers_mobile/features/employee/models/notification_model.dart';

// Services
import 'package:easy_callers_mobile/features/employee/services/notification_service.dart';
```

### Shared/Core
```dart
// Auth services (used by all roles)
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
```

## 🎯 Guidelines

### When Adding New Files

1. **Role-Specific Models/Services**
   - Place in the appropriate role directory
   - Example: New employee feature → `lib/features/employee/`

2. **Shared Models/Services**
   - Place in `lib/core/` if used by multiple roles
   - Example: Common utilities → `lib/core/utils/`

3. **Feature Organization**
   - Each feature should have its own directory
   - Use MVC pattern: `bindings/`, `controllers/`, `views/`
   - Add `widgets/` if feature has custom widgets

### Cross-Role Access

- **Super Admin** can access Manager and Employee models (for oversight)
- **Manager** can access Employee models (for team management)
- **Employee** should primarily use their own models
- All roles can access shared core services

## 🔍 Finding Files

### By Role
```bash
# Super Admin files
find lib/features/super_admin -name "*.dart"

# Manager files
find lib/features/manager -name "*.dart"

# Employee files
find lib/features/employee -name "*.dart"
```

### By Type
```bash
# All models
find lib/features -path "*/models/*.dart"

# All services
find lib/features -path "*/services/*.dart"

# All controllers
find lib/features -path "*/controllers/*.dart"
```

## ✅ Benefits of This Structure

1. **Clear Ownership**: Easy to identify which team/role owns which code
2. **Reduced Conflicts**: Different roles work in different directories
3. **Better Imports**: Import paths clearly show dependencies
4. **Easier Testing**: Test files can mirror the structure
5. **Scalability**: Easy to add new roles or features

## 🚀 Migration Complete

All existing imports have been updated. The app compiles successfully with no errors.
