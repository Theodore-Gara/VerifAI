import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/shared/models.dart';

void main() {
  VerificationResult report({
    String status = 'appears_sound',
    Map<String, dynamic>? checks,
  }) =>
      VerificationResult.fromJson({
        'analysis': {
          'id': 1,
          'version': checks == null ? 1 : 2,
          'kind': 'text',
          'overall_status': status,
          if (checks != null) 'checks': checks,
        },
      });

  test('a legacy report without checks is never shown as sound', () {
    expect(report().isSound, isFalse);
  });

  test('an appears_sound report needs sources and checked claims', () {
    expect(
        report(checks: {
          'web_search': true,
          'sources_found': 3,
          'claims_checked': 2,
          'citations_checked': 1,
        }).isSound,
        isTrue);
    expect(
        report(checks: {
          'web_search': true,
          'sources_found': 0,
          'claims_checked': 2,
        }).isSound,
        isFalse);
  });

  test('catalog earned flag defaults to whether earned_at is present', () {
    expect(
        Achievement.fromJson({'id': 1, 'code': 'first-task', 'earned': true})
            .earned,
        isTrue);
    expect(
        Achievement.fromJson(
                {'id': 1, 'code': 'first-task', 'earned_at': '2026-01-01'})
            .earned,
        isTrue);
    expect(
        Achievement.fromJson({'id': 1, 'code': 'first-task'}).earned, isFalse);
  });
}
