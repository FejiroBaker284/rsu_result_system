-- =====================================================
-- RSU COMPUTER ENGINEERING RESULT PROCESSING SYSTEM
-- Supabase SQL Schema
-- Run this entire file in your Supabase SQL Editor
-- =====================================================

-- ──────────────────────────────────────────────────
-- 1. ENABLE UUID EXTENSION
-- ──────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ──────────────────────────────────────────────────
-- 2. ENUMS
-- ──────────────────────────────────────────────────
CREATE TYPE user_role AS ENUM ('admin', 'lecturer', 'student');
CREATE TYPE semester_type AS ENUM ('first', 'second');
CREATE TYPE result_status AS ENUM ('draft', 'submitted', 'approved', 'rejected', 'published');
CREATE TYPE academic_standing AS ENUM ('good_standing', 'probation', 'withdrawn');

-- ──────────────────────────────────────────────────
-- 3. PROFILES TABLE (extends Supabase auth.users)
-- ──────────────────────────────────────────────────
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role user_role NOT NULL DEFAULT 'student',
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────────
-- 4. ACADEMIC SESSIONS
-- ──────────────────────────────────────────────────
CREATE TABLE academic_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_name TEXT NOT NULL UNIQUE, -- e.g. "2023/2024"
  is_current BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────────
-- 5. STUDENTS TABLE
-- ──────────────────────────────────────────────────
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  matric_number TEXT NOT NULL UNIQUE, -- e.g. "RSU/2021/CE/001"
  level INTEGER NOT NULL CHECK (level IN (100, 200, 300, 400, 500)),
  entry_session_id UUID REFERENCES academic_sessions(id),
  academic_standing academic_standing DEFAULT 'good_standing',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────────
-- 6. LECTURERS TABLE
-- ──────────────────────────────────────────────────
CREATE TABLE lecturers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  staff_id TEXT NOT NULL UNIQUE, -- e.g. "RSU/STAFF/0045"
  designation TEXT, -- e.g. "Senior Lecturer"
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────────
-- 7. COURSES TABLE
-- ──────────────────────────────────────────────────
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_code TEXT NOT NULL UNIQUE, -- e.g. "CPE 301"
  course_title TEXT NOT NULL,       -- e.g. "Digital Electronics"
  credit_units INTEGER NOT NULL CHECK (credit_units BETWEEN 1 AND 6),
  level INTEGER NOT NULL CHECK (level IN (100, 200, 300, 400, 500)),
  semester semester_type NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────────
-- 8. COURSE ASSIGNMENTS (Lecturer -> Course)
-- ──────────────────────────────────────────────────
CREATE TABLE course_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lecturer_id UUID NOT NULL REFERENCES lecturers(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES academic_sessions(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(lecturer_id, course_id, session_id)
);

-- ──────────────────────────────────────────────────
-- 9. RESULT SHEETS (per course per session per semester)
-- ──────────────────────────────────────────────────
CREATE TABLE result_sheets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES academic_sessions(id) ON DELETE CASCADE,
  lecturer_id UUID NOT NULL REFERENCES lecturers(id),
  status result_status DEFAULT 'draft',
  rejection_reason TEXT,
  submitted_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(course_id, session_id)
);

-- ──────────────────────────────────────────────────
-- 10. STUDENT RESULTS (individual scores per student per course)
-- ──────────────────────────────────────────────────
CREATE TABLE student_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  result_sheet_id UUID NOT NULL REFERENCES result_sheets(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id),
  session_id UUID NOT NULL REFERENCES academic_sessions(id),
  ca_score NUMERIC(5,2) DEFAULT 0 CHECK (ca_score BETWEEN 0 AND 30),
  exam_score NUMERIC(5,2) DEFAULT 0 CHECK (exam_score BETWEEN 0 AND 70),
  total_score NUMERIC(5,2) GENERATED ALWAYS AS (ca_score + exam_score) STORED,
  grade TEXT GENERATED ALWAYS AS (
    CASE
      WHEN (ca_score + exam_score) >= 70 THEN 'A'
      WHEN (ca_score + exam_score) >= 60 THEN 'B'
      WHEN (ca_score + exam_score) >= 50 THEN 'C'
      WHEN (ca_score + exam_score) >= 45 THEN 'D'
      WHEN (ca_score + exam_score) >= 40 THEN 'E'
      ELSE 'F'
    END
  ) STORED,
  grade_point NUMERIC(3,1) GENERATED ALWAYS AS (
    CASE
      WHEN (ca_score + exam_score) >= 70 THEN 5.0
      WHEN (ca_score + exam_score) >= 60 THEN 4.0
      WHEN (ca_score + exam_score) >= 50 THEN 3.0
      WHEN (ca_score + exam_score) >= 45 THEN 2.0
      WHEN (ca_score + exam_score) >= 40 THEN 1.0
      ELSE 0.0
    END
  ) STORED,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(result_sheet_id, student_id)
);

-- ──────────────────────────────────────────────────
-- 11. SEMESTER GPA SUMMARY (computed and cached)
-- ──────────────────────────────────────────────────
CREATE TABLE semester_gpa (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES academic_sessions(id) ON DELETE CASCADE,
  semester semester_type NOT NULL,
  total_credit_units INTEGER DEFAULT 0,
  total_quality_points NUMERIC(8,2) DEFAULT 0,
  gpa NUMERIC(4,2) DEFAULT 0,
  computed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, session_id, semester)
);

-- ──────────────────────────────────────────────────
-- 12. NOTIFICATIONS
-- ──────────────────────────────────────────────────
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────────
-- 13. INDEXES FOR PERFORMANCE
-- ──────────────────────────────────────────────────
CREATE INDEX idx_students_matric ON students(matric_number);
CREATE INDEX idx_student_results_student ON student_results(student_id);
CREATE INDEX idx_student_results_session ON student_results(session_id);
CREATE INDEX idx_result_sheets_status ON result_sheets(status);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);

-- ──────────────────────────────────────────────────
-- 14. UPDATED_AT TRIGGER FUNCTION
-- ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_students_updated BEFORE UPDATE ON students
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_result_sheets_updated BEFORE UPDATE ON result_sheets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_student_results_updated BEFORE UPDATE ON student_results
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ──────────────────────────────────────────────────
-- 15. AUTO-CREATE PROFILE ON SIGNUP
-- ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Unknown'),
    NEW.email,
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'student')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ──────────────────────────────────────────────────
-- 16. ROW LEVEL SECURITY (RLS)
-- ──────────────────────────────────────────────────

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE lecturers ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE result_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE semester_gpa ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES: users see their own profile; admin sees all
CREATE POLICY "profiles_self_read" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles_admin_all" ON profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- STUDENTS: students see their own record; lecturers and admins see all
CREATE POLICY "students_self_read" ON students
  FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "students_staff_read" ON students
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('admin', 'lecturer'))
  );

CREATE POLICY "students_admin_write" ON students
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- COURSES: everyone can read; only admin can write
CREATE POLICY "courses_read_all" ON courses FOR SELECT USING (TRUE);
CREATE POLICY "courses_admin_write" ON courses
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ACADEMIC SESSIONS: everyone reads; admin writes
CREATE POLICY "sessions_read_all" ON academic_sessions FOR SELECT USING (TRUE);
CREATE POLICY "sessions_admin_write" ON academic_sessions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- RESULT SHEETS: lecturer sees their own; admin sees all; student sees published
CREATE POLICY "result_sheets_lecturer" ON result_sheets
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM lecturers l
      WHERE l.id = result_sheets.lecturer_id AND l.profile_id = auth.uid()
    )
  );

CREATE POLICY "result_sheets_admin" ON result_sheets
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

CREATE POLICY "result_sheets_student_published" ON result_sheets
  FOR SELECT USING (status = 'published');

-- STUDENT RESULTS: student sees own published; lecturer sees their sheet; admin sees all
CREATE POLICY "student_results_own" ON student_results
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM students s
      JOIN result_sheets rs ON rs.id = student_results.result_sheet_id
      WHERE s.id = student_results.student_id
        AND s.profile_id = auth.uid()
        AND rs.status = 'published'
    )
  );

CREATE POLICY "student_results_lecturer" ON student_results
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM result_sheets rs
      JOIN lecturers l ON l.id = rs.lecturer_id
      WHERE rs.id = student_results.result_sheet_id
        AND l.profile_id = auth.uid()
    )
  );

CREATE POLICY "student_results_admin" ON student_results
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- SEMESTER GPA: students see own; admin sees all
CREATE POLICY "semester_gpa_own" ON semester_gpa
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM students s WHERE s.id = semester_gpa.student_id AND s.profile_id = auth.uid())
  );

CREATE POLICY "semester_gpa_admin" ON semester_gpa
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- NOTIFICATIONS: users see their own
CREATE POLICY "notifications_own" ON notifications
  FOR ALL USING (user_id = auth.uid());

-- ──────────────────────────────────────────────────
-- 17. SEED DATA (sample session + courses)
-- ──────────────────────────────────────────────────
INSERT INTO academic_sessions (session_name, is_current) VALUES
  ('2022/2023', FALSE),
  ('2023/2024', FALSE),
  ('2024/2025', TRUE);

-- 100 Level Courses
INSERT INTO courses (course_code, course_title, credit_units, level, semester) VALUES
  ('CPE 101', 'Introduction to Computer Engineering', 2, 100, 'first'),
  ('CPE 103', 'Engineering Mathematics I', 3, 100, 'first'),
  ('CPE 105', 'Introduction to Programming', 3, 100, 'first'),
  ('GNS 101', 'Use of English I', 2, 100, 'first'),
  ('PHY 101', 'General Physics I', 3, 100, 'first'),
  ('CPE 102', 'Engineering Drawing', 2, 100, 'second'),
  ('CPE 104', 'Engineering Mathematics II', 3, 100, 'second'),
  ('CPE 106', 'Digital Logic Design', 3, 100, 'second'),
  ('GNS 102', 'Use of English II', 2, 100, 'second'),
  ('PHY 102', 'General Physics II', 3, 100, 'second');

-- 200 Level Courses
INSERT INTO courses (course_code, course_title, credit_units, level, semester) VALUES
  ('CPE 201', 'Circuit Theory I', 3, 200, 'first'),
  ('CPE 203', 'Computer Organization', 3, 200, 'first'),
  ('CPE 205', 'Data Structures & Algorithms', 3, 200, 'first'),
  ('CPE 207', 'Engineering Mathematics III', 3, 200, 'first'),
  ('CPE 202', 'Circuit Theory II', 3, 200, 'second'),
  ('CPE 204', 'Microprocessors & Microcontrollers', 3, 200, 'second'),
  ('CPE 206', 'Object Oriented Programming', 3, 200, 'second'),
  ('CPE 208', 'Signals & Systems', 3, 200, 'second');

-- 300 Level Courses
INSERT INTO courses (course_code, course_title, credit_units, level, semester) VALUES
  ('CPE 301', 'Digital Electronics', 3, 300, 'first'),
  ('CPE 303', 'Operating Systems', 3, 300, 'first'),
  ('CPE 305', 'Computer Networks I', 3, 300, 'first'),
  ('CPE 307', 'Embedded Systems', 3, 300, 'first'),
  ('CPE 302', 'VLSI Design', 3, 300, 'second'),
  ('CPE 304', 'Database Management Systems', 3, 300, 'second'),
  ('CPE 306', 'Computer Networks II', 3, 300, 'second'),
  ('CPE 308', 'Software Engineering', 3, 300, 'second');

-- 400 Level Courses
INSERT INTO courses (course_code, course_title, credit_units, level, semester) VALUES
  ('CPE 401', 'Artificial Intelligence', 3, 400, 'first'),
  ('CPE 403', 'Computer Architecture', 3, 400, 'first'),
  ('CPE 405', 'Mobile Application Development', 3, 400, 'first'),
  ('CPE 407', 'Information Security', 3, 400, 'first'),
  ('CPE 402', 'Machine Learning', 3, 400, 'second'),
  ('CPE 404', 'Cloud Computing', 3, 400, 'second'),
  ('CPE 406', 'Internet of Things', 3, 400, 'second'),
  ('CPE 408', 'Project Management', 2, 400, 'second');

-- 500 Level Courses
INSERT INTO courses (course_code, course_title, credit_units, level, semester) VALUES
  ('CPE 501', 'Final Year Project I', 6, 500, 'first'),
  ('CPE 503', 'Advanced Computer Networks', 3, 500, 'first'),
  ('CPE 505', 'Entrepreneurship', 2, 500, 'first'),
  ('CPE 502', 'Final Year Project II', 6, 500, 'second'),
  ('CPE 504', 'Engineering Management', 2, 500, 'second');

-- ──────────────────────────────────────────────────
-- DONE ✅
-- ──────────────────────────────────────────────────
