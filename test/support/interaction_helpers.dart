import 'package:flutter_test/flutter_test.dart';

/// Reveal the control and lay out the resulting scroll offset before tapping.
/// Fixed pumps also work while an indeterminate animation is running.
Future<void> revealForInteraction(WidgetTester tester, Finder finder) async {
  await tester.pump();
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(
    finder.hitTestable(),
    findsOneWidget,
    reason: 'The control must be on screen and hit-testable after scrolling.',
  );
}
