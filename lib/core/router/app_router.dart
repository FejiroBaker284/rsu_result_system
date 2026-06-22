import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/manage_students_screen.dart';
import '../../screens/admin/manage_lecturers_screen.dart';
import '../../screens/admin/manage_courses_screen.dart';
import '../../screens/admin/result_approval_screen.dart';
import '../../screens/admin/add_student_screen.dart';
import '../../screens/admin/add_lecturer_screen.dart';
import '../../screens/lecturer/lecturer_dashboard_screen.dart';
import '../../screens/lecturer/score_entry_screen.dart';
import '../../screens/student/student_dashboard_screen.dart';
import '../../screens/student/student_results_screen.dart';
import '../../screens/student/transcript_screen.dart';
import '../../screens/shared/splash_screen.dart';
import '../../screens/shared/notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final profile = authState.value;
      final isLoggedIn = profile != null;
      final loc = state.matchedLocation;

      if (isLoading) return loc == '/splash' ? null : '/splash';
      if (!isLoggedIn && loc != '/login' && loc != '/forgot-password') return '/login';
      if (isLoggedIn && (loc == '/login' || loc == '/splash')) {
        return switch (profile.role) {
          UserRole.admin => '/admin',
          UserRole.lecturer => '/lecturer',
          UserRole.student => '/student',
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // ── Admin ──────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboardScreen(),
        routes: [
          GoRoute(path: 'students', builder: (_, __) => const ManageStudentsScreen()),
          GoRoute(path: 'students/add', builder: (_, __) => const AddStudentScreen()),
          GoRoute(path: 'lecturers', builder: (_, __) => const ManageLecturersScreen()),
          GoRoute(path: 'lecturers/add', builder: (_, __) => const AddLecturerScreen()),
          GoRoute(path: 'courses', builder: (_, __) => const ManageCoursesScreen()),
          GoRoute(
            path: 'results',
            builder: (_, __) => const ResultApprovalScreen(),
            routes: [
              GoRoute(
                path: ':sheetId',
                builder: (_, state) => ResultApprovalScreen(
                  sheetId: state.pathParameters['sheetId'],
                ),
              ),
            ],
          ),
          GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
        ],
      ),

      // ── Lecturer ───────────────────────────────
      GoRoute(
        path: '/lecturer',
        builder: (_, __) => const LecturerDashboardScreen(),
        routes: [
          GoRoute(
            path: 'scores/:sheetId',
            builder: (_, state) =>
                ScoreEntryScreen(sheetId: state.pathParameters['sheetId']!),
          ),
          GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
        ],
      ),

      // ── Student ────────────────────────────────
      GoRoute(
        path: '/student',
        builder: (_, __) => const StudentDashboardScreen(),
        routes: [
          GoRoute(path: 'results', builder: (_, __) => const StudentResultsScreen()),
          GoRoute(path: 'transcript', builder: (_, __) => const TranscriptScreen()),
          GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
        ],
      ),
    ],
  );
});
