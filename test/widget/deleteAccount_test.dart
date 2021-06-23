import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/deleteAccount.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/appInputPassword.dart';
import 'package:partner_app/widgets/borderlessButton.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:partner_app/widgets/yesNoDialog.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';

void main() {
  // define mockers behaviors
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.emailVerified).thenReturn(true);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
  });

  Future<void> pumpDeleteAccount(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
            create: (context) => mockFirebaseModel,
          ),
          ChangeNotifierProvider<PartnerModel>(
            create: (context) => mockPartnerModel,
          ),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => mockConnectivityModel,
          ),
        ],
        builder: (context, child) => MaterialApp(
          home: DeleteAccount(),
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  group("state", () {
    testWidgets("inits as disabled", (WidgetTester tester) async {
      // add DeleteAccount widget to UI
      await pumpDeleteAccount(tester);

      // expect disabled state
      expectDisabledState(tester: tester);
    });

    testWidgets("is enabled when user types valid password",
        (WidgetTester tester) async {
      // add DeleteAccount widget to UI
      await pumpDeleteAccount(tester);

      // enter invalid password
      await tester.enterText(find.byType(AppInputPassword), "1234567");
      await tester.pumpAndSettle();

      // expect disabled state
      expectDisabledState(tester: tester, passwordHasFocus: true);

      // enter valid password
      await tester.enterText(find.byType(AppInputPassword), "12345678");
      await tester.pumpAndSettle();

      // expect enabled state
      expectEnabledState(tester: tester, passwordHasFocus: true);
    });
  });

  group("toggleReason", () {
    testWidgets("updates deleteReasons and UI correctly",
        (WidgetTester tester) async {
      // add DeleteAccount widget to the UI
      await pumpDeleteAccount(tester);

      final borderlessButtonFinders = find.byType(BorderlessButton);
      final badRideExperienceFinder = borderlessButtonFinders.first;
      final hasAnotherAccountFinder = borderlessButtonFinders.at(1);
      final doesntUseServiceFinder = borderlessButtonFinders.at(2);
      final badAppExperienceFinder = borderlessButtonFinders.at(3);
      final anotherFinder = borderlessButtonFinders.last;

      // tap badRideExperience button
      await tester.tap(badRideExperienceFinder);
      await tester.pumpAndSettle();

      // expect reasons to be appropriately updated
      expectDeleteReasons(tester: tester, badRideExperience: true);

      // tap badAppExperience button
      await tester.tap(badAppExperienceFinder);
      await tester.pumpAndSettle();

      // expect reasons to be appropriately updated
      expectDeleteReasons(
        tester: tester,
        badRideExperience: true,
        badAppExperience: true,
      );

      // tap hasAnotherAccount button
      await tester.tap(hasAnotherAccountFinder);
      await tester.pumpAndSettle();

      // expect reasons to be appropriately updated
      expectDeleteReasons(
        tester: tester,
        badRideExperience: true,
        badAppExperience: true,
        hasAnotherAccount: true,
      );

      // tap doesntUseService button
      await tester.tap(doesntUseServiceFinder);
      await tester.pumpAndSettle();

      // expect reasons to be appropriately updated
      expectDeleteReasons(
        tester: tester,
        badRideExperience: true,
        badAppExperience: true,
        hasAnotherAccount: true,
        doesntUseService: true,
      );

      // tap another button
      await tester.tap(anotherFinder);
      await tester.pumpAndSettle();

      // expect reasons and UI to be appropriately updated
      expectDeleteReasons(
        tester: tester,
        badRideExperience: true,
        badAppExperience: true,
        hasAnotherAccount: true,
        doesntUseService: true,
        another: true,
      );
    });
  });

  group("buttonCallback", () {
    testWidgets("displays YesNoDialog which pops off when tapping 'não'",
        (WidgetTester tester) async {
      // add DeleteAccount to the UI
      await pumpDeleteAccount(tester);
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(YesNoDialog), findsNothing);
      expect(find.byType(DeleteAccount), findsOneWidget);

      // enter valid password
      await tester.enterText(find.byType(AppInputPassword), "12345678");
      await tester.pumpAndSettle();

      // tap Excluir Conta
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // verify that dialog was pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(YesNoDialog), findsOneWidget);
      expect(find.byType(DeleteAccount), findsOneWidget);

      // tap on 'não'
      final textButtonFinder = find.byType(TextButton);
      final noFinder = textButtonFinder.first;
      await tester.tap(noFinder);
      await tester.pumpAndSettle();

      // verify that dialog was popped
      verify(mockNavigatorObserver.didPop(any, any));
      expect(find.byType(YesNoDialog), findsNothing);
      expect(find.byType(DeleteAccount), findsOneWidget);
    });

    void testDeleteAccount({
      @required WidgetTester tester,
      @required String errorCode,
      @required String expectedMessage,
    }) async {
      // set mocks to throw errorCode when reauthenticateWithCredential
      when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
        throw FirebaseAuthException(message: "message", code: errorCode);
      });
      when(mockUser.email).thenReturn("test@provider.com");

      // add DeleteAccount to the UI
      await pumpDeleteAccount(tester);
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(YesNoDialog), findsNothing);
      expect(find.byType(DeleteAccount), findsOneWidget);

      // enter valid password
      await tester.enterText(find.byType(AppInputPassword), "12345678");
      await tester.pumpAndSettle();

      // tap Excluir Conta
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // verify that dialog was pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(YesNoDialog), findsOneWidget);
      expect(find.byType(DeleteAccount), findsOneWidget);

      // tap on 'yes'
      final textButtonFinder = find.byType(TextButton);
      final yesFinder = textButtonFinder.last;
      await tester.tap(yesFinder);
      await tester.pumpAndSettle();

      // verify that dialog was popped
      verify(mockNavigatorObserver.didPop(any, any));
      expect(find.byType(YesNoDialog), findsNothing);
      expect(find.byType(DeleteAccount), findsOneWidget);

      // verify that warning is shown
      final warningFinder = find.byType(Warning);
      expect(warningFinder, findsOneWidget);
      final warningWidget = tester.widget(warningFinder);
      expect(
          warningWidget,
          isA<Warning>()
              .having((w) => w.message, "message", equals(expectedMessage)));
    }

    testWidgets(
        "displays YesNoDialog which displays warnings on wrong-password",
        (WidgetTester tester) async {
      testDeleteAccount(
          tester: tester,
          errorCode: "wrong-password",
          expectedMessage: "Senha incorreta. Tente novamente.");
    });

    testWidgets(
        "displays YesNoDialog which displays warnings on wrong-password",
        (WidgetTester tester) async {
      testDeleteAccount(
          tester: tester,
          errorCode: "too-many-requests",
          expectedMessage:
              "Muitas tentativas sucessivas. Tente novamente mais tarde.");
    });

    testWidgets(
        "displays YesNoDialog which displays warnings on any other code",
        (WidgetTester tester) async {
      testDeleteAccount(
          tester: tester,
          errorCode: "anything-else",
          expectedMessage: "Algo deu errado. Tente novamente mais tarde.");
    });
  });
}

void expectEnabledState({
  @required WidgetTester tester,
  bool passwordHasFocus,
}) {
  expectState(
    tester: tester,
    passwordHasFocus: passwordHasFocus ?? false,
    buttonColorIsDisabled: false,
    buttonChildIsNull: true,
    buttonCallbackIsNull: false,
    badAppExperience: false,
    badRideExperience: false,
    hasAnotherAccount: false,
    doesntUseService: false,
    another: false,
  );
}

void expectDisabledState({
  @required WidgetTester tester,
  bool passwordHasFocus,
}) {
  expectState(
    tester: tester,
    passwordHasFocus: passwordHasFocus ?? false,
    buttonColorIsDisabled: true,
    buttonChildIsNull: true,
    buttonCallbackIsNull: true,
    badAppExperience: false,
    badRideExperience: false,
    hasAnotherAccount: false,
    doesntUseService: false,
    another: false,
  );
}

void expectState({
  @required WidgetTester tester,
  @required bool passwordHasFocus,
  @required bool buttonColorIsDisabled,
  @required bool buttonChildIsNull,
  @required bool buttonCallbackIsNull,
  @required bool badAppExperience,
  @required bool badRideExperience,
  @required bool hasAnotherAccount,
  @required bool doesntUseService,
  @required bool another,
}) {
  DeleteAccountState state = tester.state(find.byType(DeleteAccount));
  expect(state.passwordFocusNode.hasFocus, equals(passwordHasFocus));
  if (buttonColorIsDisabled) {
    expect(state.buttonColor, equals(AppColor.disabled));
  } else {
    expect(state.buttonColor, equals(AppColor.primaryPink));
  }
  expect(state.buttonChild == null, buttonChildIsNull);
  expect(state.buttonCallback == null, buttonCallbackIsNull);
  expectDeleteReasons(
    tester: tester,
    badRideExperience: badRideExperience,
    badAppExperience: badAppExperience,
    hasAnotherAccount: hasAnotherAccount,
    doesntUseService: doesntUseService,
    another: another,
  );
}

void expectDeleteReasons(
    {@required WidgetTester tester,
    bool badAppExperience,
    bool badRideExperience,
    bool hasAnotherAccount,
    bool doesntUseService,
    bool another}) {
  // check deleteReasons
  DeleteAccountState state = tester.state(find.byType(DeleteAccount));
  expect(state.deleteReasons[DeleteReason.badAppExperience],
      equals(badAppExperience ?? false));
  expect(state.deleteReasons[DeleteReason.badTripExperience],
      equals(badRideExperience ?? false));
  expect(state.deleteReasons[DeleteReason.hasAnotherAccount],
      equals(hasAnotherAccount ?? false));
  expect(state.deleteReasons[DeleteReason.doesntUseService],
      equals(doesntUseService ?? false));
  expect(state.deleteReasons[DeleteReason.another], equals(another ?? false));

  // check iconRight
  final borderlessButtonFinders = find.byType(BorderlessButton);
  final badRideExperienceFinder = borderlessButtonFinders.first;
  final hasAnotherAccountFinder = borderlessButtonFinders.at(1);
  final doesntUseServiceFinder = borderlessButtonFinders.at(2);
  final badAppExperienceFinder = borderlessButtonFinders.at(3);
  final anotherFinder = borderlessButtonFinders.last;

  // check badRideExperience iconRight
  expect(
      tester.widget(badRideExperienceFinder),
      isA<BorderlessButton>().having(
          (b) => b.iconRight,
          "iconRight",
          equals(badRideExperience ?? false
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank)));
  // check badAppExperience iconRight
  expect(
      tester.widget(badAppExperienceFinder),
      isA<BorderlessButton>().having(
          (b) => b.iconRight,
          "iconRight",
          equals(badAppExperience ?? false
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank)));
  // check hasAnotherAccount iconRight
  expect(
      tester.widget(hasAnotherAccountFinder),
      isA<BorderlessButton>().having(
          (b) => b.iconRight,
          "iconRight",
          equals(hasAnotherAccount ?? false
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank)));
  // check doesntUseService iconRight
  expect(
      tester.widget(doesntUseServiceFinder),
      isA<BorderlessButton>().having(
          (b) => b.iconRight,
          "iconRight",
          equals(doesntUseService ?? false
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank)));
  // check another iconRight
  expect(
      tester.widget(anotherFinder),
      isA<BorderlessButton>().having(
          (b) => b.iconRight,
          "iconRight",
          equals(another ?? false
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank)));
}
