class AppConstants {
  static const String appName = 'RSU Result Portal';
  static const String university = 'Rivers State University';
  static const String department = 'Computer Engineering';
  static const String shortName = 'RSU-CE';

  // Supabase
  static const String supabaseUrl = 'https://imjkqtyvzagtbojyyjjy.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltamtxdHl2emFndGJvanl5amp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1MzgzOTYsImV4cCI6MjA5NzExNDM5Nn0.QmENdcLrr6InkESfT197HqaIv95P-c2LYLLVyzmHfvM';

  // RSU Grading Scale
  static const Map<String, double> gradePoints = {
    'A': 5.0,
    'B': 4.0,
    'C': 3.0,
    'D': 2.0,
    'E': 1.0,
    'F': 0.0,
  };

  static String getGrade(double score) {
    if (score >= 70) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 45) return 'D';
    if (score >= 40) return 'E';
    return 'F';
  }

  static double getGradePoint(double score) {
    if (score >= 70) return 5.0;
    if (score >= 60) return 4.0;
    if (score >= 50) return 3.0;
    if (score >= 45) return 2.0;
    if (score >= 40) return 1.0;
    return 0.0;
  }

  static String getAcademicStanding(double cgpa) {
    if (cgpa >= 3.5) return 'First Class';
    if (cgpa >= 3.0) return 'Second Class Upper';
    if (cgpa >= 2.5) return 'Second Class Lower';
    if (cgpa >= 2.0) return 'Third Class';
    if (cgpa >= 1.0) return 'Pass';
    return 'Fail';
  }

  // Level labels
  static const Map<int, String> levelLabels = {
    100: '100 Level',
    200: '200 Level',
    300: '300 Level',
    400: '400 Level',
    500: '500 Level',
  };
}