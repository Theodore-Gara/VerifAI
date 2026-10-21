import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/features/rewards/presentation/rewards_screen.dart';
import 'package:verifai/features/rewards/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/reward_image.dart';

RewardsData _catalogue() => const RewardsData(
      rewards: [
        Reward(
          id: 1,
          code: 'coffee',
          title: 'Coffee break',
          subtitle: 'A coffee reward concept.',
          costTokens: 10,
          imageAsset: 'reward_coffee.jpg',
        ),
        Reward(
          id: 2,
          code: 'mystery',
          title: 'Mystery perk',
          subtitle: 'Artwork not shipped yet.',
          costTokens: 12,
        ),
      ],
      wallet: RewardWallet(tokens: 30, level: 3, xp: 400),
    );

Future<void> _pumpCatalogue(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rewardsProvider.overrideWith((ref) async => _catalogue()),
      ],
      child: const MaterialApp(home: RewardsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('RewardImage', () {
    test('resolves a catalogue file name inside the bundled images folder', () {
      expect(
        const RewardImage(imageAsset: 'reward_coffee.jpg').resolvedAsset,
        'assets/images/reward_coffee.jpg',
      );
      expect(
        const RewardImage(imageAsset: '  reward_m365.jpg  ').resolvedAsset,
        'assets/images/reward_m365.jpg',
      );
    });

    test('leaves an already-qualified path alone and rejects a blank one', () {
      expect(
        const RewardImage(imageAsset: 'assets/images/reward_fuel.jpg')
            .resolvedAsset,
        'assets/images/reward_fuel.jpg',
      );
      expect(const RewardImage(imageAsset: '   ').resolvedAsset, isNull);
    });

    testWidgets('falls back to the gift glyph when there is no artwork',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Center(
          child: RewardImage(imageAsset: '', width: 92, height: 64),
        ),
      ));

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
    });
  });

  testWidgets('the catalogue draws one thumbnail per reward', (tester) async {
    await _pumpCatalogue(tester);

    expect(find.byType(RewardImage), findsNWidgets(2));
    // The coffee reward points at a bundled picture; the second reward has no
    // artwork, so only the first renders an Image (the other shows the glyph).
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
    expect(find.byType(Hero), findsNWidgets(2));
  });
}
