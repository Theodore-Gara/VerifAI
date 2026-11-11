import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';

/// Badge count for the admin Support tab.
final adminUnreadTicketsProvider = FutureProvider<int>((ref) async {
  final data = await ref
      .watch(apiClientProvider)
      .adminRequest('GET', 'support/unread-count');
  return _int(data is Map ? data['count'] : null);
});

/// Small helpers shared by the raw-JSON admin screens. The admin API is broad
/// and changes with content work, so the native portal keeps the server shape
/// instead of mirroring every field in a Dart model.
int adminInt(dynamic value) => _int(value);

/// A number that may arrive as a float (averages are rounded to one decimal
/// on the server). Falls back to 0.
double adminDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String adminString(dynamic value, [String fallback = '']) =>
    value == null ? fallback : '$value';

Map<String, dynamic> adminMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Map<String, dynamic>> adminList(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

int _int(dynamic value) => int.tryParse('$value') ?? 0;
