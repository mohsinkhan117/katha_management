// test/add_party_view_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/theme/app_themes/themes.dart';
import 'package:katha_management/core/widgets/glass_card.dart';
import 'package:katha_management/ui/features/add_party/add_party_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: child,
    );
  }

  group('AddPartyView Frosted Glass & Widget Styling Tests', () {
    testWidgets('Renders properly in Light Theme with GlassCard sections', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const AddPartyView(),
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      // Verify title
      expect(find.text(AppStrings.addPartyTitle), findsOneWidget);

      // Verify GlassCard widgets are used
      expect(find.byType(GlassCard), findsAtLeastNWidgets(4));

      // Verify Section Headers
      expect(find.text(AppStrings.basicInfoSection), findsOneWidget);
      expect(find.text(AppStrings.categorySection), findsOneWidget);
      expect(find.text(AppStrings.openingBalanceSection), findsOneWidget);
      expect(find.text(AppStrings.noteOptional), findsAtLeastNWidgets(1));

      // Verify Choice Chips for Party Tags
      for (final tag in PartyTag.values) {
        expect(find.text(tag.label), findsOneWidget);
      }

      // Verify Save button
      expect(find.text(AppStrings.savePartyButton), findsOneWidget);
    });

    testWidgets('Renders properly in Dark Theme with frosted styling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const AddPartyView(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addPartyTitle), findsOneWidget);
      expect(find.byType(GlassCard), findsAtLeastNWidgets(4));
    });

    testWidgets('Allows entering text and selecting tag', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const AddPartyView(),
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      // Enter party name
      final nameField = find.widgetWithText(
        TextField,
        AppStrings.partyNameLabel,
      );
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Acme Traders');
      await tester.pumpAndSettle();

      // Select tag
      final wholesaleChip = find.widgetWithText(
        ChoiceChip,
        PartyTag.wholesale.label,
      );
      expect(wholesaleChip, findsOneWidget);
      await tester.tap(wholesaleChip);
      await tester.pumpAndSettle();

      // Verify tag is selected
      final chipWidget = tester.widget<ChoiceChip>(wholesaleChip);
      expect(chipWidget.selected, isTrue);
    });

    testWidgets(
      'In edit mode, displays existing party data and delete action',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final sampleParty = PartyModel(
          id: 'party_123',
          name: 'Metro Pharmacy',
          phone: '03001234567',
          address: 'Main Commercial Area',
          openingBalance: 2500,
          tag: PartyTag.retail,
          note: 'Prompt payer',
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: AddPartyView(partyToEdit: sampleParty),
            themeMode: ThemeMode.light,
          ),
        );
        await tester.pumpAndSettle();

        // Verify title is Edit Party
        expect(find.text(AppStrings.editPartyTitle), findsOneWidget);

        // Verify populated fields
        expect(find.text('Metro Pharmacy'), findsOneWidget);
        expect(find.text('03001234567'), findsOneWidget);
        expect(find.text('Main Commercial Area'), findsOneWidget);
        expect(find.text('2500'), findsOneWidget);
        expect(find.text('Prompt payer'), findsOneWidget);

        // Verify update button is present
        expect(find.text(AppStrings.updatePartyButton), findsOneWidget);

        // Verify delete button is present in AppBar
        final deleteBtn = find.byIcon(Icons.delete_outline);
        expect(deleteBtn, findsOneWidget);

        // Tap delete button to open confirmation dialog
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.deletePartyTitle), findsOneWidget);
        expect(find.text(AppStrings.deletePartyMessage), findsOneWidget);
        expect(find.text(AppStrings.no), findsOneWidget);
      },
    );
  });
}
