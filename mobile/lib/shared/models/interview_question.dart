// A single Interview Practice question from `GET /api/interview/questions`.
// Ungraded, read-only. Plain class (no codegen).
class InterviewQuestion {
  final int id;
  final String question;
  final String sampleAnswer;
  final String whatEmployersTest;
  final bool practiced;
  final int sortOrder;

  const InterviewQuestion({
    required this.id,
    required this.question,
    required this.sampleAnswer,
    required this.whatEmployersTest,
    required this.practiced,
    required this.sortOrder,
  });

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) =>
      InterviewQuestion(
        id: int.tryParse('${json['id']}') ?? 0,
        question: json['question'] as String? ?? '',
        sampleAnswer: json['sample_answer'] as String? ?? '',
        whatEmployersTest: json['what_employers_test'] as String? ?? '',
        practiced: json['practiced'] as bool? ?? false,
        sortOrder: int.tryParse('${json['sort_order']}') ?? 0,
      );
}
