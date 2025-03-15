import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/editEmail.dart';
import 'package:partner_app/screens/insertNewEmail.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/warning.dart';
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

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<PartnerModel>(
            create: (context) => mockPartnerModel,
          ),
          ChangeNotifierProvider<ConnectivityModel>(
              create: (context) => mockConnectivityModel),
        ],
        builder: (context, child) => MaterialApp(
          home: InsertNewEmail(),
        ),
      ),
    );
  }

  group("state", () {
    testWidgets("inits as disabled", (WidgetTester tester) async {
      // add widget to the UI
      await pumpWidget(tester);

      expectDisabledState(
        tester: tester,
        emailHasFocus: true,
        passwordHasFocus: false,
      );
    });

    testWidgets("locks screen when lockScreen is true",
        (WidgetTester tester) async {
      // configure current email to be 'currentemail@provider.com'
      when(mockUser.email).thenReturn("currentemail@provider.com");

      // configure reauthenticateWithCredential to run smoothly
      when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
        return Future.value();
      });

      // configure updateEmail to run smoothly
      when(mockUser.updateEmail(any)).thenAnswer((_) {
        return Future.value();
      });

      // add EditEmail to the UI
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserModel>(
                create: (context) => mockFirebaseModel),
            ChangeNotifierProvider<PartnerModel>(
                create: (context) => mockPartnerModel),
            ChangeNotifierProvider<ConnectivityModel>(
                create: (context) => mockConnectivityModel),
          ],
          builder: (context, child) => MaterialApp(
            home: EditEmail(),
            routes: {
              InsertNewEmail.routeName: (context) => InsertNewEmail(),
            },
            navigatorObservers: [mockNavigatorObserver],
          ),
        ),
      );

      // verify that EditEmail is being displayed
      final editEmailFinder = find.byType(EditEmail);
      final insertNewEmailFinder = find.byType(InsertNewEmail);
      verify(mockNavigatorObserver.didPush(any, any));
      expect(editEmailFinder, findsOneWidget);
      expect(insertNewEmailFinder, findsNothing);

      // tap "Alterar email"
      await tester.tap(find.widgetWithText(AppButton, "Alterar Email"));
      await tester.pumpAndSettle();

      // verify that InsertNewEmail screen was pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(editEmailFinder, findsNothing);
      expect(insertNewEmailFinder, findsOneWidget);

      // verify password doesnt have focus
      final passwordFinder = find.byType(AppInputText).last;
      final passwordwidget = tester.widget(passwordFinder);
      expect(
          passwordwidget,
          isA<AppInputText>().having(
            (a) => a.focusNode.hasFocus,
            "focusNode",
            isFalse,
          ));

      // tap password field
      await tester.tap(passwordFinder);
      await tester.pump();

      // verify password has focus
      expect(
          passwordwidget,
          isA<AppInputText>().having(
            (a) => a.focusNode.hasFocus,
            "focusNode",
            isTrue,
          ));

      // lock screen
      InsertNewEmailState insertNewEmailState =
          tester.state(find.byType(InsertNewEmail));
      insertNewEmailState.lockScreen = true;
      expect(insertNewEmailState.lockScreen, isTrue);
      await tester.pumpAndSettle();

      // verify email doesnt have focus
      final emailFinder = find.byType(AppInputText).first;
      final emailWidget = tester.widget(emailFinder);
      expect(
          emailWidget,
          isA<AppInputText>().having(
            (a) => a.focusNode.hasFocus,
            "focusNode",
            isFalse,
          ));

      // tap email field
      await tester.tap(emailFinder);
      await tester.pump();

      // verify email still doesn't has focus
      expect(
          emailWidget,
          isA<AppInputText>().having(
            (a) => a.focusNode.hasFocus,
            "focusNode",
            isFalse,
          ));

      // try to navigate back
      await tester.tap(find.byType(ArrowBackButton));
      await tester.pumpAndSettle();

      // verify that we didn't navigate back
      verifyNever(mockNavigatorObserver.didPop(any, any));
    });

    testWidgets("is enabled when email and password are valid",
        (WidgetTester tester) async {
      // add widget to the UI
      await pumpWidget(tester);

      // insert invalid email
      await tester.enterText(
          find.byType(AppInputText).first, "example@provider");
      await tester.pump();
      expectDisabledState(
        tester: tester,
        emailHasFocus: true,
        passwordHasFocus: false,
      );

      // insert valid email
      await tester.enterText(
          find.byType(AppInputText).first, "example@provider.com");
      await tester.pump();
      expectDisabledState(
        tester: tester,
        emailHasFocus: true,
        passwordHasFocus: false,
      );

      // insert invalid password
      await tester.enterText(find.byType(AppInputText).last, "1234567");
      await tester.pump();
      expectDisabledState(
        tester: tester,
        emailHasFocus: false,
        passwordHasFocus: true,
      );

      // insert valid password
      await tester.enterText(find.byType(AppInputText).last, "12345678");
      await tester.pump();

      // expect enabled state
      expectEnabledState(
        tester: tester,
        emailHasFocus: false,
        passwordHasFocus: true,
      );
    });
  });

  group("buttonCallback", () {
    Future<void> pumpWidgetAndInsertEmailAndPassword(
      WidgetTester tester, {
      String email,
    }) async {
      // configure current email to be 'currentemail@provider.com'
      when(mockUser.email).thenReturn("currentemail@provider.com");

      // add InsertNewEmail to the UI
      await pumpWidget(tester);

      // insert email and password
      String _email = email ?? "validemail@provider.com";
      await tester.enterText(find.byType(AppInputText).first, _email);
      await tester.enterText(find.byType(AppInputText).last, "12345678");
      await tester.pump();

      // hit button
      await tester.tap(find.byType(AppButton));
      await tester.pump();
    }

    testWidgets("displays warning when email is the same",
        (WidgetTester tester) async {
      // add InsertNewEmail to the UI
      await pumpWidgetAndInsertEmailAndPassword(
        tester,
        email: "currentemail@provider.com",
      );

      // expect disabled state with warning
      expectDisabledState(
        tester: tester,
        emailHasFocus: false,
        passwordHasFocus: false,
        message: "O email inserido é idêntico ao email atual. Tente outro.",
      );
    });

    testWidgets("displays warning when password is incorrect",
        (WidgetTester tester) async {
      // configure reauthenticateWithCredential to throw wrong-password exception
      when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
        throw FirebaseAuthException(message: "message", code: "wrong-password");
      });

      // add InsertNewEmail to the UI
      await pumpWidgetAndInsertEmailAndPassword(tester);

      // expect disabled state with warning
      expectDisabledState(
        tester: tester,
        emailHasFocus: false,
        passwordHasFocus: false,
        message: "Senha incorreta. Tente novamente.",
      );
    });

    testWidgets(
        "displays warning when reauthenticateWithCredential throws exceptions",
        (WidgetTester tester) async {
      // configure reauthenticateWithCredential to throw general exception
      when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
        throw FirebaseAuthException(message: "message", code: "any-code");
      });

      // add InsertNewEmail to the UI
      await pumpWidgetAndInsertEmailAndPassword(tester);

      // expect disabled state with warning
      expectDisabledState(
        tester: tester,
        emailHasFocus: false,
        passwordHasFocus: false,
        message: "Algo deu errado. Tente novamente mais tarde.",
      );
    });

    testWidgets("displays warning when updateEmail throws email-already-in-use",
        (WidgetTester tester) async {
      // configure reauthenticateWithCredential to run smoothly
      when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
        return Future.value();
      });

      // configure updateEmail to thorw email-already-in-use
      when(mockUser.updateEmail(any)).thenAnswer((_) {
        throw FirebaseAuthException(
            message: "message", code: "email-already-in-use");
      });

      await pumpWidgetAndInsertEmailAndPassword(tester);

      // expect disabled state with warning
      expectDisabledState(
        tester: tester,
        emailHasFocus: false,
        passwordHasFocus: false,
        message: "O email já está sendo usado. Tente outro.",
      );
    });

    testWidgets("displays warning when updateEmail throws invalid-email",
        (WidgetTester tester) async {
      // configure reauthenticateWithCredential to run smoothly
      when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
        return Future.value();
      });

      // configure updateEmail to thorw email-already-in-use
      when(mockUser.updateEmail(any)).thenAnswer((_) {
        throw FirebaseAuthException(message: "message", code: "invalid-email");
      });

      await pumpWidgetAndInsertEmailAndPassword(tester);

      // expect disabled state with warning
      expectDisabledState(
        tester: tester,
        emailHasFocus: false,
        passwordHasFocus: false,
        message: "Email inválido. Tente outro.",
      );
    });

    testWidgets("displays warning when updateEmail throws anythin else",
        (WidgetTester tester) async {
      // configure reauthenticateWithCredential to run smoothly
      when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
        return Future.value();
      });

      // configure updateEmail to thorw email-already-in-use
      when(mockUser.updateEmail(any)).thenAnswer((_) {
        throw FirebaseAuthException(message: "message", code: "anything else");
      });

      await pumpWidgetAndInsertEmailAndPassword(tester);

      // expect disabled state with warning
      expectDisabledState(
        tester: tester,
        emailHasFocus: false,
        passwordHasFocus: false,
        message:
            "Falha ao alterar email. Saia e entre novamente na sua conta e tente novamente.",
      );
    });

    testWidgets("pops back to EditEmail screen when succesfully updates email",
        (WidgetTester tester) async {
      String currentEmail = "currentemail@provider.com";
      String newEmail = "newemail@provider.com";

      // configure current email to be 'currentemail@provider.com'
      when(mockUser.email).thenReturn(currentEmail);

      // configure reauthenticateWithCredential to run smoothly
      when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
        return Future.value();
      });

      // configure updateEmail to run smoothly
      when(mockUser.updateEmail(any)).thenAnswer((_) {
        // update email
        when(mockUser.email).thenReturn(newEmail);
        return Future.value();
      });

      // add EditEmail to the UI
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserModel>(
                create: (context) => mockFirebaseModel),
            ChangeNotifierProvider<PartnerModel>(
              create: (context) => mockPartnerModel,
            ),
            ChangeNotifierProvider<ConnectivityModel>(
              create: (context) => mockConnectivityModel,
            ),
          ],
          builder: (context, child) => MaterialApp(
            home: EditEmail(),
            routes: {
              InsertNewEmail.routeName: (context) => InsertNewEmail(),
            },
            navigatorObservers: [mockNavigatorObserver],
          ),
        ),
      );

      // verify that EditEmail is being displayed
      final editEmailFinder = find.byType(EditEmail);
      final insertNewEmailFinder = find.byType(InsertNewEmail);
      verify(mockNavigatorObserver.didPush(any, any));
      expect(editEmailFinder, findsOneWidget);
      expect(insertNewEmailFinder, findsNothing);

      // tap "Alterar email"
      await tester.tap(find.widgetWithText(AppButton, "Alterar Email"));
      await tester.pumpAndSettle();

      // verify that InsertNewEmail screen was pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(editEmailFinder, findsNothing);
      expect(insertNewEmailFinder, findsOneWidget);

      // insert valid email and password
      await tester.enterText(find.byType(AppInputText).first, newEmail);
      await tester.enterText(find.byType(AppInputText).last, "12345678");
      await tester.pump();

      // hit "Redefinir" button
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // verify that screen was locked
      InsertNewEmailState insertNewEmailState =
          tester.state(find.byType(InsertNewEmail));
      expect(insertNewEmailState.lockScreen, isTrue);

      // settle
      await tester.pumpAndSettle();

      // verify that we navigated back to EditEmail
      verify(mockNavigatorObserver.didPop(any, any));
      expect(editEmailFinder, findsOneWidget);
      expect(insertNewEmailFinder, findsNothing);

      // expect success warning message
      final warningFinder = find.byType(Warning);
      expect(warningFinder, findsOneWidget);
      final warningWidget = tester.firstWidget(warningFinder);
      expect(
        warningWidget,
        isA<Warning>().having((w) => w.message, "message",
            equals("Email alterado com sucesso para " + newEmail)),
      );
    });
  });
}

// defaults to expecting email to be focused and passwor
void expectDisabledState({
  required WidgetTester tester,
  required bool emailHasFocus,
  required bool passwordHasFocus,
  String message,
}) {
  // expect button color to be disabled
  final buttonFinder = find.byType(AppButton);
  final buttonWidget = tester.firstWidget(buttonFinder);
  expect(
      buttonWidget,
      isA<AppButton>().having(
          (b) => b.buttonColor, "buttonColor", equals(AppColor.disabled)));

  // expect button callback, button child, and message to be null
  InsertNewEmailState insertNewEmailState =
      tester.state(find.byType(InsertNewEmail));
  expect(insertNewEmailState.appButtonCallback, isNull);
  expect(insertNewEmailState.appButtonChild, isNull);

  // expect locked screen to be false
  expect(insertNewEmailState.lockScreen, isFalse);

  // verify message
  final warningFinder = find.byType(Warning);
  if (message != null) {
    // expect warning
    expect(warningFinder, findsOneWidget);
    final warningWidget = tester.firstWidget(warningFinder);
    expect(
      warningWidget,
      isA<Warning>().having((w) => w.message, "message", equals(message)),
    );
  } else {
    // don't expect warning
    expect(warningFinder, findsNothing);
  }

  final inputFinder = find.byType(AppInputText);

  // verify email's focus
  final emailInputWidget = tester.widget(inputFinder.first);
  expect(
      emailInputWidget,
      isA<AppInputText>()
          .having(
              (a) => a.focusNode.hasFocus, "focusNode.hasFocus", emailHasFocus)
          .having(
              (a) => a.hintText, "hintText", equals("exemplo@dominio.com")));

  // verify password's focus
  final passwordInputWidget = tester.widget(inputFinder.last);
  expect(
      passwordInputWidget,
      isA<AppInputText>()
          .having((p) => p.focusNode.hasFocus, "focusNode.hasFocus",
              passwordHasFocus)
          .having((p) => p.hintText, "hintText", equals("senha")));
}

// defaults to expecting email to be focused and passwor
void expectEnabledState({
  required WidgetTester tester,
  required bool emailHasFocus,
  required bool passwordHasFocus,
}) {
  // expect button color to be primary pink
  final buttonFinder = find.byType(AppButton);
  final buttonWidget = tester.firstWidget(buttonFinder);
  expect(
      buttonWidget,
      isA<AppButton>().having(
          (b) => b.buttonColor, "buttonColor", equals(AppColor.primaryPink)));

  // expect button callback not to be null
  InsertNewEmailState insertNewEmailState =
      tester.state(find.byType(InsertNewEmail));
  expect(insertNewEmailState.appButtonCallback, isNotNull);

  // expect button child and warning to be null
  expect(insertNewEmailState.appButtonChild, isNull);
  expect(insertNewEmailState.warningMessage, isNull);
  final inputFinder = find.byType(AppInputText);

  // verify email's focus
  final emailInputWidget = tester.widget(inputFinder.first);
  expect(
      emailInputWidget,
      isA<AppInputText>()
          .having(
              (a) => a.focusNode.hasFocus, "focusNode.hasFocus", emailHasFocus)
          .having(
              (a) => a.hintText, "hintText", equals("exemplo@dominio.com")));

  // verify password's focus
  final passwordInputWidget = tester.widget(inputFinder.last);
  expect(
      passwordInputWidget,
      isA<AppInputText>()
          .having((p) => p.focusNode.hasFocus, "focusNode.hasFocus",
              passwordHasFocus)
          .having((p) => p.hintText, "hintText", equals("senha")));
}
