# Excel Upload Flow - Visual Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    MANAGER UPLOADS EXCEL FILE                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      STEP 1: FILE VALIDATION                     │
│  • Check file type (.xlsx, .xls, .csv)                          │
│  • Read file bytes                                               │
│  • Decode Excel workbook                                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   STEP 2: HEADER ANALYSIS                        │
│  • Extract first row as headers                                  │
│  • Convert to lowercase                                          │
│  • Apply regex pattern matching                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │ Headers Clear?  │
                    └─────────────────┘
                       ↙           ↘
                    YES              NO
                     ↓                ↓
        ┌──────────────────┐   ┌──────────────────────┐
        │ Use Header Map   │   │ CONTENT DETECTION    │
        │                  │   │ • Analyze 5 rows     │
        │ Phone: Col 2     │   │ • Score each column  │
        │ Name: Col 1      │   │ • Detect patterns    │
        │ Email: Col 3     │   │ • Assign columns     │
        └──────────────────┘   └──────────────────────┘
                     ↓                ↓
                     └────────┬───────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   STEP 3: DATA EXTRACTION                        │
│  For each row (skip header):                                     │
│    • Extract values based on column map                          │
│    • Clean phone numbers (remove formatting)                     │
│    • Merge first + last name if needed                           │
│    • Store extra columns in extra_data                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   STEP 4: VALIDATION                             │
│  • Check each lead has name OR phone                             │
│  • Skip empty rows                                               │
│  • Validate data formats                                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   STEP 5: UPLOAD TO STORAGE                      │
│  • Upload file to Supabase Storage                               │
│  • Generate unique filename with timestamp                       │
│  • Get public URL                                                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   STEP 6: CREATE BATCH RECORD                    │
│  • Insert into lead_batches table                                │
│  • Store: file_name, file_url, total_leads, uploaded_by         │
│  • Get batch_id                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   STEP 7: INSERT LEADS                           │
│  • Batch insert (100 leads at a time)                            │
│  • Save to leads table with:                                     │
│    - name, phone (cleaned), email                                │
│    - location, project, budget, source, notes                    │
│    - status: 'new'                                               │
│    - uploaded_by, batch_id                                       │
│    - extra_data (unmapped columns)                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        SUCCESS!                                  │
│  • Show success message                                          │
│  • Display lead count                                            │
│  • Refresh dashboard                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Column Detection Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    REGEX PATTERN MATCHING                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
        ┌─────────────────────────────────────────┐
        │  Header: "Contact No."                  │
        └─────────────────────────────────────────┘
                              ↓
        ┌─────────────────────────────────────────┐
        │  Convert to lowercase: "contact no."    │
        └─────────────────────────────────────────┘
                              ↓
        ┌─────────────────────────────────────────┐
        │  Apply Phone Regex Pattern:             │
        │  ^(phone|mobile|contact|...)            │
        │  [\s_-]?(number|no)?\.?$                │
        └─────────────────────────────────────────┘
                              ↓
        ┌─────────────────────────────────────────┐
        │  ✅ MATCH! → Assign as PHONE column     │
        └─────────────────────────────────────────┘
```

---

## Content Detection Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  NO CLEAR HEADERS DETECTED                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              ANALYZE FIRST 5 DATA ROWS                           │
│                                                                  │
│  Row 1: John Doe      | 9876543210 | john@email.com             │
│  Row 2: Jane Smith    | 9876543211 | jane@email.com             │
│  Row 3: Bob Wilson    | 9876543212 | bob@email.com              │
│  Row 4: Alice Cooper  | 9876543213 | alice@email.com            │
│  Row 5: Tom Hardy     | 9876543214 | tom@email.com              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    SCORE EACH COLUMN                             │
│                                                                  │
│  Column 0:                                                       │
│    • _isPhoneNumber("John Doe") → NO                            │
│    • _isEmail("John Doe") → NO                                  │
│    • _isName("John Doe") → YES ✅                               │
│    Score: { phone: 0, email: 0, name: 5 }                       │
│                                                                  │
│  Column 1:                                                       │
│    • _isPhoneNumber("9876543210") → YES ✅                      │
│    • _isEmail("9876543210") → NO                                │
│    • _isName("9876543210") → NO                                 │
│    Score: { phone: 5, email: 0, name: 0 }                       │
│                                                                  │
│  Column 2:                                                       │
│    • _isPhoneNumber("john@email.com") → NO                      │
│    • _isEmail("john@email.com") → YES ✅                        │
│    • _isName("john@email.com") → NO                             │
│    Score: { phone: 0, email: 5, name: 0 }                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   ASSIGN COLUMNS BY SCORE                        │
│                                                                  │
│  ✅ Column 0 → NAME (highest name score: 5)                     │
│  ✅ Column 1 → PHONE (highest phone score: 5)                   │
│  ✅ Column 2 → EMAIL (highest email score: 5)                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    PROCEED WITH IMPORT                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phone Number Cleaning Flow

```
┌─────────────────────────────────────────────────────────────────┐
│              Input: "+91 98765-43210"                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: Remove whitespace                                       │
│  Result: "+9198765-43210"                                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: Remove formatting chars: ( ) - .                       │
│  Result: "+9198765 43210"                                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: Keep only digits (preserve leading +)                  │
│  Result: "+919876543210"                                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: Remove + and keep digits only                          │
│  Result: "919876543210"                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              ✅ SAVED TO DATABASE                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    UPLOAD ATTEMPT                                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Valid File?    │
                    └─────────────────┘
                       ↙           ↘
                    NO              YES
                     ↓                ↓
        ┌──────────────────┐   ┌──────────────────┐
        │ Error:           │   │ Continue...      │
        │ "Invalid file"   │   │                  │
        └──────────────────┘   └──────────────────┘
                                       ↓
                              ┌─────────────────┐
                              │ Headers Found?  │
                              └─────────────────┘
                                 ↙           ↘
                              NO              YES
                               ↓                ↓
                    ┌──────────────────┐   ┌──────────────────┐
                    │ Try Content      │   │ Use Headers      │
                    │ Detection        │   │                  │
                    └──────────────────┘   └──────────────────┘
                               ↓                ↓
                               └────────┬───────┘
                                        ↓
                              ┌─────────────────┐
                              │ Name/Phone OK?  │
                              └─────────────────┘
                                 ↙           ↘
                              NO              YES
                               ↓                ↓
                    ┌──────────────────┐   ┌──────────────────┐
                    │ Error:           │   │ Import Leads     │
                    │ "No name/phone   │   │                  │
                    │  columns found"  │   │                  │
                    │ + Details        │   │                  │
                    └──────────────────┘   └──────────────────┘
                                                   ↓
                                         ┌─────────────────┐
                                         │ Import Success? │
                                         └─────────────────┘
                                            ↙           ↘
                                         NO              YES
                                          ↓                ↓
                               ┌──────────────────┐   ┌──────────────────┐
                               │ Error:           │   │ Success!         │
                               │ "Upload failed"  │   │ "X leads saved"  │
                               │ + Error details  │   │                  │
                               └──────────────────┘   └──────────────────┘
```

---

## Database Schema

```
┌─────────────────────────────────────────────────────────────────┐
│                        lead_batches                              │
├─────────────────────────────────────────────────────────────────┤
│  id              UUID (PK)                                       │
│  file_name       TEXT                                            │
│  file_url        TEXT                                            │
│  total_leads     INTEGER                                         │
│  uploaded_by     UUID (FK → users)                              │
│  created_at      TIMESTAMP                                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓ (1:N)
┌─────────────────────────────────────────────────────────────────┐
│                           leads                                  │
├─────────────────────────────────────────────────────────────────┤
│  id              UUID (PK)                                       │
│  name            TEXT (required)                                 │
│  phone           TEXT (required, cleaned)                        │
│  email           TEXT                                            │
│  location        TEXT                                            │
│  project_name    TEXT                                            │
│  budget          TEXT                                            │
│  source          TEXT                                            │
│  notes           TEXT                                            │
│  status          TEXT (default: 'new')                           │
│  uploaded_by     UUID (FK → users)                              │
│  assigned_to     UUID (FK → users)                              │
│  batch_id        UUID (FK → lead_batches)                       │
│  extra_data      JSONB (unmapped columns)                        │
│  created_at      TIMESTAMP                                       │
│  updated_at      TIMESTAMP                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

**This visual flow shows the complete Excel upload process from start to finish!**
