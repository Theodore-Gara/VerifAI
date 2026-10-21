// AI Lab: lessons, textbook sections, practice activities and capstones.
// Plain classes (no codegen).
import 'vera.dart' show VeraSource;

class LabLesson {
  final int id;
  final String code;
  final String title;
  final String summary;
  final int estimatedMinutes;
  final int level;
  final String? competency;
  final int sectionsCount;
  final int activitiesCount;
  final int questionsCount;
  final int sectionsCompleted;
  final int activitiesCompleted;
  final int assessmentBestScore;
  final String status; // not_started | in_progress | completed
  final bool seen;

  const LabLesson({
    required this.id,
    required this.code,
    required this.title,
    required this.summary,
    this.estimatedMinutes = 0,
    this.level = 1,
    this.competency,
    this.sectionsCount = 0,
    this.activitiesCount = 0,
    this.questionsCount = 0,
    this.sectionsCompleted = 0,
    this.activitiesCompleted = 0,
    this.assessmentBestScore = 0,
    this.status = 'not_started',
    this.seen = false,
  });

  bool get completed => status == 'completed';

  factory LabLesson.fromJson(Map<String, dynamic> json) => LabLesson(
        id: int.tryParse('${json['id']}') ?? 0,
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        estimatedMinutes: int.tryParse('${json['estimated_minutes']}') ?? 0,
        level: int.tryParse('${json['level']}') ?? 1,
        competency: json['competency'] as String?,
        sectionsCount: int.tryParse('${json['sections_count']}') ?? 0,
        activitiesCount: int.tryParse('${json['activities_count']}') ?? 0,
        questionsCount: int.tryParse('${json['questions_count']}') ?? 0,
        sectionsCompleted: int.tryParse('${json['sections_completed']}') ?? 0,
        activitiesCompleted:
            int.tryParse('${json['activities_completed']}') ?? 0,
        assessmentBestScore:
            int.tryParse('${json['assessment_best_score']}') ?? 0,
        status: json['status'] as String? ?? 'not_started',
        seen: json['seen'] as bool? ?? false,
      );
}

class LabSection {
  final int id;
  final int? parentId;
  final String heading;
  final String body;
  final int sortOrder;

  const LabSection(
      {required this.id,
      this.parentId,
      required this.heading,
      required this.body,
      this.sortOrder = 0});

  factory LabSection.fromJson(Map<String, dynamic> json) => LabSection(
        id: int.tryParse('${json['id']}') ?? 0,
        parentId: json['parent_id'] == null
            ? null
            : int.tryParse('${json['parent_id']}'),
        heading: json['heading'] as String? ?? '',
        body: json['body'] as String? ?? '',
        sortOrder: int.tryParse('${json['sort_order']}') ?? 0,
      );
}

class LabActivity {
  final int id;
  final String
      type; // multiple_choice | true_false | fill_blank | matching | ordering
  final String prompt;
  final Map<String, dynamic> payload;
  final int xpReward;
  final bool passed;
  final bool attempted;
  final int sortOrder;

  const LabActivity({
    required this.id,
    required this.type,
    required this.prompt,
    this.payload = const {},
    this.xpReward = 10,
    this.passed = false,
    this.attempted = false,
    this.sortOrder = 0,
  });

  List<String> get options => (payload['options'] as List<dynamic>? ?? const [])
      .map((e) => '$e')
      .toList();
  List<String> get left =>
      (payload['left'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
  List<String> get right => (payload['right'] as List<dynamic>? ?? const [])
      .map((e) => '$e')
      .toList();
  List<String> get items => (payload['items'] as List<dynamic>? ?? const [])
      .map((e) => '$e')
      .toList();

  factory LabActivity.fromJson(Map<String, dynamic> json) => LabActivity(
        id: int.tryParse('${json['id']}') ?? 0,
        type: json['type'] as String? ?? 'multiple_choice',
        prompt: json['prompt'] as String? ?? '',
        payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        xpReward: int.tryParse('${json['xp_reward']}') ?? 10,
        passed: json['passed'] as bool? ?? false,
        attempted: json['attempted'] as bool? ?? false,
        sortOrder: int.tryParse('${json['sort_order']}') ?? 0,
      );
}

class LabQuestion {
  final int id;
  final String prompt;
  final List<String> options;
  final int sortOrder;

  const LabQuestion(
      {required this.id,
      required this.prompt,
      this.options = const [],
      this.sortOrder = 0});

  factory LabQuestion.fromJson(Map<String, dynamic> json) => LabQuestion(
        id: int.tryParse('${json['id']}') ?? 0,
        prompt: json['prompt'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((e) => '$e')
            .toList(),
        sortOrder: int.tryParse('${json['sort_order']}') ?? 0,
      );
}

class LabProgress {
  final int sectionsCompleted;
  final int activitiesCompleted;
  final int assessmentBestScore;
  final String status;

  const LabProgress({
    this.sectionsCompleted = 0,
    this.activitiesCompleted = 0,
    this.assessmentBestScore = 0,
    this.status = 'not_started',
  });

  factory LabProgress.fromJson(Map<String, dynamic> json) => LabProgress(
        sectionsCompleted: int.tryParse('${json['sections_completed']}') ?? 0,
        activitiesCompleted:
            int.tryParse('${json['activities_completed']}') ?? 0,
        assessmentBestScore:
            int.tryParse('${json['assessment_best_score']}') ?? 0,
        status: json['status'] as String? ?? 'not_started',
      );
}

class LabAttribution {
  final String creditLine;
  final String sourceUrl;
  final String licenseUrl;
  final String title;
  final String license;
  final String useType;

  const LabAttribution({
    required this.creditLine,
    required this.sourceUrl,
    required this.licenseUrl,
    required this.title,
    required this.license,
    required this.useType,
  });

  factory LabAttribution.fromJson(Map<String, dynamic> json) => LabAttribution(
        creditLine: json['credit_line'] as String? ?? '',
        sourceUrl: json['source_url'] as String? ?? '',
        licenseUrl: json['license_url'] as String? ?? '',
        title: json['title'] as String? ?? '',
        license: json['license'] as String? ?? '',
        useType: json['use_type'] as String? ?? '',
      );
}

class LabLessonDetail {
  final LabLesson lesson;
  final List<LabSection> sections;
  final List<LabActivity> activities;
  final List<LabQuestion> questions;
  final List<VeraSource> sources;
  final List<LabAttribution> attributions;
  final bool shareAlike;
  final LabProgress progress;

  const LabLessonDetail({
    required this.lesson,
    this.sections = const [],
    this.activities = const [],
    this.questions = const [],
    this.sources = const [],
    this.attributions = const [],
    this.shareAlike = false,
    this.progress = const LabProgress(),
  });

  factory LabLessonDetail.fromJson(Map<String, dynamic> json) {
    final l = (json['lesson'] as Map?)?.cast<String, dynamic>() ?? const {};
    List<T> list<T>(String key, T Function(Map<String, dynamic>) build) =>
        (l[key] as List<dynamic>? ?? const [])
            .map((e) => build(Map<String, dynamic>.from(e as Map)))
            .toList();
    return LabLessonDetail(
      lesson: LabLesson.fromJson(l),
      sections: list('sections', LabSection.fromJson),
      activities: list('activities', LabActivity.fromJson),
      questions: list('questions', LabQuestion.fromJson),
      sources: list('sources', VeraSource.fromJson),
      attributions: list('attributions', LabAttribution.fromJson),
      shareAlike: l['share_alike'] as bool? ?? false,
      progress: LabProgress.fromJson(
          (l['progress'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  /// Chapters are top-level sections (no parent).
  List<LabSection> get chapters =>
      sections.where((s) => s.parentId == null).toList();

  /// Topics are the sections directly under a chapter.
  List<LabSection> topicsOf(int chapterId) =>
      sections.where((s) => s.parentId == chapterId).toList();

  /// All topics flattened in reading order (chapter by chapter).
  List<LabSection> get orderedTopics {
    final result = <LabSection>[];
    for (final c in chapters) {
      result.addAll(topicsOf(c.id));
    }
    return result;
  }

  /// Subtopics are the sections under a topic; rendered together on the reader.
  List<LabSection> subtopicsOf(int topicId) =>
      sections.where((s) => s.parentId == topicId).toList();

  /// Total number of topics (the unit that progress counts).
  int get topicCount {
    final chapterIds = chapters.map((c) => c.id).toSet();
    return sections
        .where((s) => s.parentId != null && chapterIds.contains(s.parentId))
        .length;
  }
}

class LabActivityResult {
  final bool passed;
  final int xpEarned;
  final bool practice;
  final String explanation;
  final dynamic answer;

  const LabActivityResult(
      {required this.passed,
      required this.xpEarned,
      this.practice = false,
      this.explanation = '',
      this.answer});

  factory LabActivityResult.fromJson(Map<String, dynamic> json) {
    final r = (json['result'] as Map?)?.cast<String, dynamic>() ?? const {};
    return LabActivityResult(
      passed: r['passed'] as bool? ?? false,
      xpEarned: int.tryParse('${r['xp_earned']}') ?? 0,
      practice: r['practice'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
      answer: json['answer'],
    );
  }
}

class LabAssessment {
  final int id;
  final String code;
  final String title;
  final String summary;
  final int totalMarks;
  final int timeLimitSeconds;
  final int passScore;
  final int maxAttempts;
  final int questionCount;
  final int attemptsUsed;
  final int attemptsRemaining;
  final int? bestScore;
  final bool passed;
  final bool viewOnly;
  final Map<String, dynamic>? scenario;
  final List<String> instructions;

  const LabAssessment({
    required this.id,
    required this.code,
    required this.title,
    this.summary = '',
    this.totalMarks = 0,
    this.timeLimitSeconds = 5400,
    this.passScore = 60,
    this.maxAttempts = 3,
    this.questionCount = 0,
    this.attemptsUsed = 0,
    this.attemptsRemaining = 0,
    this.bestScore,
    this.passed = false,
    this.viewOnly = false,
    this.scenario,
    this.instructions = const [],
  });

  factory LabAssessment.fromJson(Map<String, dynamic> json) => LabAssessment(
        id: int.tryParse('${json['id']}') ?? 0,
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        totalMarks: int.tryParse('${json['total_marks']}') ?? 0,
        timeLimitSeconds: int.tryParse('${json['time_limit_seconds']}') ?? 5400,
        passScore: int.tryParse('${json['pass_score']}') ?? 60,
        maxAttempts: int.tryParse('${json['max_attempts']}') ?? 3,
        questionCount: int.tryParse('${json['question_count']}') ?? 0,
        attemptsUsed: int.tryParse('${json['attempts_used']}') ?? 0,
        attemptsRemaining: int.tryParse('${json['attempts_remaining']}') ?? 0,
        bestScore: json['best_score'] == null
            ? null
            : int.tryParse('${json['best_score']}'),
        passed: json['passed'] as bool? ?? false,
        viewOnly: json['view_only'] as bool? ?? false,
        scenario: (json['scenario'] as Map?)?.cast<String, dynamic>(),
        instructions: (json['instructions'] as List<dynamic>? ?? const [])
            .map((e) => '$e')
            .toList(),
      );
}

class LabAssessmentQuestion {
  final int id;
  final String type;
  final String? section;
  final String? scenario;
  final String prompt;
  final Map<String, dynamic> payload;
  final List<String> codeLines;
  final Map<String, dynamic>? wordLimit;
  final String? competency;
  final String? cognitiveLevel;
  final int marks;
  final String marking; // auto | rubric
  final int sortOrder;

  const LabAssessmentQuestion({
    required this.id,
    required this.type,
    this.section,
    this.scenario,
    required this.prompt,
    this.payload = const {},
    this.codeLines = const [],
    this.wordLimit,
    this.competency,
    this.cognitiveLevel,
    this.marks = 0,
    this.marking = 'auto',
    this.sortOrder = 0,
  });

  List<String> get options => (payload['options'] as List<dynamic>? ?? const [])
      .map((e) => '$e')
      .toList();
  List<String> get left =>
      (payload['left'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
  List<String> get right => (payload['right'] as List<dynamic>? ?? const [])
      .map((e) => '$e')
      .toList();
  List<String> get items => (payload['items'] as List<dynamic>? ?? const [])
      .map((e) => '$e')
      .toList();
  List<Map<String, dynamic>> get parts =>
      (payload['parts'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  /// The numbered question this sub-question belongs to (1..6). Sub-questions
  /// sharing a number are shown together on one page.
  int? get questionNo {
    final v = payload['question_no'];
    if (v == null) return null;
    return int.tryParse('$v');
  }

  factory LabAssessmentQuestion.fromJson(Map<String, dynamic> json) =>
      LabAssessmentQuestion(
        id: int.tryParse('${json['id']}') ?? 0,
        type: json['type'] as String? ?? 'multiple_choice',
        section: json['section'] as String?,
        scenario: json['scenario'] as String?,
        prompt: json['prompt'] as String? ?? '',
        payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        codeLines: (json['code_lines'] as List<dynamic>? ?? const [])
            .map((e) => '$e')
            .toList(),
        wordLimit: (json['word_limit'] as Map?)?.cast<String, dynamic>(),
        competency: json['competency'] as String?,
        cognitiveLevel: json['cognitive_level'] as String?,
        marks: int.tryParse('${json['marks']}') ?? 0,
        marking: json['marking'] as String? ?? 'auto',
        sortOrder: int.tryParse('${json['sort_order']}') ?? 0,
      );
}

/// A startable [LabAssessment] plus its questions (answer keys withheld).
class LabAssessmentPaper {
  final LabAssessment assessment;
  final List<LabAssessmentQuestion> questions;

  const LabAssessmentPaper(
      {required this.assessment, this.questions = const []});

  factory LabAssessmentPaper.fromJson(Map<String, dynamic> json) =>
      LabAssessmentPaper(
        assessment: LabAssessment.fromJson(
            (json['assessment'] as Map?)?.cast<String, dynamic>() ?? const {}),
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .map((e) => LabAssessmentQuestion.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// A started (timed) attempt: the shuffled questions plus timing info.
class LabAssessmentStart {
  final int attemptId;
  final String startedAt;
  final String expiresAt;
  final int timeLimitSeconds;
  final int passScore;
  final int totalMarks;
  final Map<String, dynamic>? scenario;
  final List<String> instructions;
  final int attemptsRemaining;
  final List<LabAssessmentQuestion> questions;

  const LabAssessmentStart({
    required this.attemptId,
    required this.startedAt,
    required this.expiresAt,
    required this.timeLimitSeconds,
    required this.passScore,
    required this.totalMarks,
    this.scenario,
    this.instructions = const [],
    required this.attemptsRemaining,
    this.questions = const [],
  });

  factory LabAssessmentStart.fromJson(Map<String, dynamic> json) =>
      LabAssessmentStart(
        attemptId: int.tryParse('${json['attempt_id']}') ?? 0,
        startedAt: json['started_at'] as String? ?? '',
        expiresAt: json['expires_at'] as String? ?? '',
        timeLimitSeconds: int.tryParse('${json['time_limit_seconds']}') ?? 5400,
        passScore: int.tryParse('${json['pass_score']}') ?? 60,
        totalMarks: int.tryParse('${json['total_marks']}') ?? 0,
        scenario: (json['scenario'] as Map?)?.cast<String, dynamic>(),
        instructions: (json['instructions'] as List<dynamic>? ?? const [])
            .map((e) => '$e')
            .toList(),
        attemptsRemaining: int.tryParse('${json['attempts_remaining']}') ?? 0,
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .map((e) => LabAssessmentQuestion.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class LabQuestionResult {
  final int questionId;
  final bool pending;
  final bool? correct;
  final int? awarded;
  final int max;
  final dynamic answer;
  final String? explanation;

  const LabQuestionResult({
    required this.questionId,
    this.pending = false,
    this.correct,
    this.awarded,
    this.max = 0,
    this.answer,
    this.explanation,
  });

  factory LabQuestionResult.fromJson(Map<String, dynamic> json) =>
      LabQuestionResult(
        questionId: int.tryParse('${json['question_id']}') ?? 0,
        pending: json['pending'] as bool? ?? false,
        correct: json['correct'] as bool?,
        awarded:
            json['awarded'] == null ? null : int.tryParse('${json['awarded']}'),
        max: int.tryParse('${json['max'] ?? json['marks']}') ?? 0,
        answer: json['answer'],
        explanation: json['explanation'] as String?,
      );
}

class LabAssessmentResult {
  final bool pendingMarking;
  final int score;
  final bool passed;
  final bool timedOut;
  final int marksAwarded;
  final int totalMarks;
  final int attemptsRemaining;
  final int xpEarned;
  final int tokensEarned;
  final String? achievement;
  final List<LabQuestionResult> questions;

  const LabAssessmentResult({
    this.pendingMarking = false,
    this.score = 0,
    this.passed = false,
    this.timedOut = false,
    this.marksAwarded = 0,
    this.totalMarks = 0,
    this.attemptsRemaining = 0,
    this.xpEarned = 0,
    this.tokensEarned = 0,
    this.achievement,
    this.questions = const [],
  });

  factory LabAssessmentResult.fromJson(Map<String, dynamic> json) {
    final r = (json['result'] as Map?)?.cast<String, dynamic>() ?? const {};
    final questions = ((json['results'] as List<dynamic>?) ?? const [])
        .map((e) =>
            LabQuestionResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return LabAssessmentResult(
      pendingMarking: r['pending_marking'] as bool? ?? false,
      score: int.tryParse('${r['score']}') ?? 0,
      passed: r['passed'] as bool? ?? false,
      timedOut: r['timed_out'] as bool? ?? false,
      marksAwarded:
          int.tryParse('${r['marks_awarded'] ?? r['auto_marks']}') ?? 0,
      totalMarks: int.tryParse('${r['total_marks']}') ?? 0,
      attemptsRemaining: int.tryParse('${r['attempts_remaining']}') ?? 0,
      xpEarned: int.tryParse('${json['xp_earned']}') ?? 0,
      tokensEarned: int.tryParse('${json['tokens_earned']}') ?? 0,
      achievement: json['achievement'] as String?,
      questions: questions,
    );
  }
}

class LabAssessmentAnalysis {
  final String headline;
  final List<String> strengths;
  final List<String> focus;
  final String report;

  const LabAssessmentAnalysis(
      {this.headline = '',
      this.strengths = const [],
      this.focus = const [],
      this.report = ''});

  factory LabAssessmentAnalysis.fromJson(Map<String, dynamic> json) {
    final a = (json['analysis'] as Map?)?.cast<String, dynamic>() ?? json;
    return LabAssessmentAnalysis(
      headline: a['headline'] as String? ?? '',
      strengths: (a['strengths'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(),
      focus:
          (a['focus'] as List<dynamic>? ?? const []).map((e) => '$e').toList(),
      report: a['report'] as String? ?? '',
    );
  }
}
