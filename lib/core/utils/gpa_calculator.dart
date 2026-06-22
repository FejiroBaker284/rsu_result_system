import '../models/models.dart';

class GPACalculator {
  /// Compute GPA for a list of results (single semester)
  static double computeGPA(List<Result> results) {
    if (results.isEmpty) return 0.0;

    double totalWeightedPoints = 0;
    int totalUnits = 0;

    for (final result in results) {
      if (result.course == null || result.gradePoint == null) continue;
      final units = result.course!.creditUnits;
      totalWeightedPoints += (result.gradePoint! * units);
      totalUnits += units;
    }

    if (totalUnits == 0) return 0.0;
    return double.parse((totalWeightedPoints / totalUnits).toStringAsFixed(2));
  }

  /// Compute CGPA across all semesters
  static double computeCGPA(List<Result> allResults) {
    if (allResults.isEmpty) return 0.0;

    double totalWeightedPoints = 0;
    int totalUnits = 0;

    for (final result in allResults) {
      if (result.course == null || result.gradePoint == null) continue;
      final units = result.course!.creditUnits;
      totalWeightedPoints += (result.gradePoint! * units);
      totalUnits += units;
    }

    if (totalUnits == 0) return 0.0;
    return double.parse((totalWeightedPoints / totalUnits).toStringAsFixed(2));
  }

  /// Group results by session + semester
  static Map<String, List<Result>> groupBySemester(List<Result> results) {
    final Map<String, List<Result>> grouped = {};
    for (final result in results) {
      final key = '${result.sessionId}_${result.semester}';
      grouped.putIfAbsent(key, () => []).add(result);
    }
    return grouped;
  }

  /// Get academic classification
  static String getClassification(double cgpa) {
    if (cgpa >= 4.5) return 'First Class Honours';
    if (cgpa >= 3.5) return 'Second Class Upper';
    if (cgpa >= 2.5) return 'Second Class Lower';
    if (cgpa >= 1.5) return 'Third Class';
    return 'Pass';
  }

  /// Get academic standing
  static String getStanding(double cgpa) {
    if (cgpa >= 1.5) return 'good_standing';
    if (cgpa >= 1.0) return 'probation';
    return 'withdrawn';
  }

  /// Get standing label
  static String getStandingLabel(String standing) {
    switch (standing) {
      case 'good_standing': return 'Good Standing';
      case 'probation': return 'Academic Probation';
      case 'withdrawn': return 'Academically Withdrawn';
      default: return 'Unknown';
    }
  }

  /// Get total credit units registered
  static int getTotalUnits(List<Result> results) {
    return results.fold(0, (sum, r) => sum + (r.course?.creditUnits ?? 0));
  }

  /// Get total units earned (excluding F grades)
  static int getUnitsEarned(List<Result> results) {
    return results
        .where((r) => r.grade != 'F')
        .fold(0, (sum, r) => sum + (r.course?.creditUnits ?? 0));
  }

  /// Get grade from total score
  static String getGrade(double totalScore) {
    if (totalScore >= 70) return 'A';
    if (totalScore >= 60) return 'B';
    if (totalScore >= 50) return 'C';
    if (totalScore >= 45) return 'D';
    if (totalScore >= 40) return 'E';
    return 'F';
  }

  /// Get grade point from grade
  static double getGradePoint(String grade) {
    switch (grade) {
      case 'A': return 5.0;
      case 'B': return 4.0;
      case 'C': return 3.0;
      case 'D': return 2.0;
      case 'E': return 1.0;
      default: return 0.0;
    }
  }
}
