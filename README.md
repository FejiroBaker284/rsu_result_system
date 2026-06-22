# RSU Computer Engineering — Online Result Processing System

**Rivers State University, Port Harcourt**
Department of Computer Engineering

---

## Stack
- **Frontend:** Flutter (Mobile + Web)
- **Backend:** Supabase (Auth + PostgreSQL + RLS)
- **State Management:** Flutter Riverpod
- **Navigation:** GoRouter
- **PDF:** pdf + printing packages

---

## Setup Instructions

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com) → New Project
2. Name it `rsu-result-system`
3. Choose a strong database password and save it

### 2. Run the SQL Schema
1. In your Supabase dashboard, go to **SQL Editor**
2. Open `supabase_schema.sql` from this project
3. Paste the entire file and click **Run**
4. You should see: tables, RLS policies, triggers, and seed data created

### 3. Configure Flutter App
Open `lib/core/constants/app_constants.dart` and replace:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```
Get these values from: Supabase Dashboard → Settings → API

### 4. Create Asset Folders
```bash
mkdir -p assets/images assets/icons
```
Add a placeholder image `assets/images/rsu_logo.png` (optional)

### 5. Run the App
```bash
flutter pub get
flutter run
```

---

## Creating the First Admin User

Since there's no registration screen (by design), create the admin manually:

1. Go to Supabase Dashboard → **Authentication → Users → Add User**
2. Enter email and password for the admin
3. Go to **Table Editor → profiles**
4. Find the new user's row and set `role` to `admin`

---

## User Roles & Default Passwords

| Role | Login | Default Password |
|------|-------|-----------------|
| Admin | Created manually in Supabase | Set during creation |
| Lecturer | Created by Admin | `RSU@Lecturer<staff_id>` |
| Student | Created by Admin | `RSU@<matric_number>` |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App constants, grading logic
│   ├── router/         # GoRouter navigation
│   ├── services/       # Supabase data services
│   └── theme/          # Colors, typography, theme
├── models/             # Data models (Student, Result, etc.)
├── providers/          # Riverpod state providers
├── screens/
│   ├── admin/          # Admin screens (dashboard, CRUD)
│   ├── auth/           # Login, forgot password
│   ├── lecturer/       # Lecturer screens (score entry)
│   ├── shared/         # Splash, notifications
│   └── student/        # Student screens (results, transcript)
└── widgets/            # Reusable UI components
```

---

## RSU Grading Scale

| Score | Grade | Grade Point |
|-------|-------|-------------|
| 70–100 | A | 5.0 |
| 60–69 | B | 4.0 |
| 50–59 | C | 3.0 |
| 45–49 | D | 2.0 |
| 40–44 | E | 1.0 |
| 0–39 | F | 0.0 |

---

## Result Workflow

```
Lecturer enters scores (Draft)
        ↓
Lecturer submits (Submitted)
        ↓
Admin reviews → Approve or Reject
        ↓ (if approved)
Admin publishes (Published)
        ↓
Students can view results
```

---

## Features Implemented

### Admin
- [x] Dashboard with live stats
- [x] Add/manage students
- [x] Add/manage lecturers
- [x] View all courses by level and semester
- [x] Add new courses
- [x] Result approval workflow (approve/reject/publish)
- [x] Notifications

### Lecturer
- [x] Dashboard with course list
- [x] Score entry (CA + Exam per student)
- [x] Real-time grade preview while entering scores
- [x] Submit for approval
- [x] Notifications

### Student
- [x] Dashboard with CGPA display
- [x] Academic standing label
- [x] View results per session
- [x] Full academic transcript
- [x] Download transcript as PDF
- [x] GPA per semester history
- [x] Notifications
