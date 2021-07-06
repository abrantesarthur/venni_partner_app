import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/insertNewPassword.dart';
import 'package:partner_app/screens/profile.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/appInputPassword.dart';
import 'package:partner_app/widgets/passwordWarning.dart';
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

  Future<void> pumpInsertNewPassword(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<PartnerModel>(
            create: (context) => mockPartnerModel,
          ),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => mockConnectivityModel,
          ),
          ChangeNotifierProvider<GoogleMapsModel>(
            create: (context) => mockGoogleMapsModel,
          ),
        ],
        builder: (context, child) => MaterialApp(
          home: InsertNewPassword(),
        ),
      ),
    );
  }

  Future<void> pumpProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<PartnerModel>(
            create: (context) => mockPartnerModel,
          ),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => mockConnectivityModel,
          ),
          ChangeNotifierProvider<GoogleMapsModel>(
            create: (context) => mockGoogleMapsModel,
          ),
        ],
        builder: (context, child) => MaterialApp(
          home: Profile(
            firebase: mockFirebaseModel,
            partner: mockPartnerModel,
          ),
          routes: {
            InsertNewPassword.routeName: (context) => InsertNewPassword(),
          },
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  group("state", () {
    testWidgets("inits as disabled", (WidgetTester tester) async {
      // add widget to the UI
      await pumpInsertNewPassword(tester);

      expectDisabledState(tester: tester);
    });

    testWidgets("is enabled if old and new passwords meet criteria",
        (WidgetTester tester) async {
      // add widget to the UI
      await pumpInsertNewPassword(tester);

      // get password finders
      final passwordFinder = find.byType(AppInputPassword);
      final oldPasswordFinder = passwordFinder.first;
      final newPasswordFinder = passwordFinder.last;

      // type invalid old password
      await tester.enterText(oldPasswordFinder, "1234567");
      await tester.pump();

      // expect state to be disabled
      expectDisabledState(tester: tester);

      // type invalid new password
      await tester.enterText(newPasswordFinder, "abc");
      await tester.pump();

      // expect state to be disabled
      expectDisabledState(
        tester: tester,
        oldPasswordHasFocus: false,
        newPasswordHasFocus: true,
        passwordHasLetter: true,
      );

      // type valid old and new password
      await tester.enterText(oldPasswordFinder, "12345678");
      await tester.enterText(newPasswordFinder, "abcd1234");
      await tester.pump();

      // expect enabled state
      expectEnabledState(tester: tester);
    });

    testWidgets("passwordChecks work correclty", (WidgetTester tester) async {
      // add widget to the UI
      await pumpInsertNewPassword(tester);

      // get password finder
      final passwordFinder = find.byType(AppInputPassword);
      final newPasswordFinder = passwordFinder.last;

      // enter new password with eight characters
      await tester.enterText(newPasswordFinder, "12345678");
      await tester.pump();

      expectDisabledState(
        tester: tester,
        passwordHasEightCharacters: true,
        passwordHasNumber: true,
        newPasswordHasFocus: true,
        oldPasswordHasFocus: false,
      );

      // enter new password with a character
      await tester.enterText(newPasswordFinder, "abcd");
      await tester.pump();

      expectDisabledState(
        tester: tester,
        passwordHasLetter: true,
        newPasswordHasFocus: true,
        oldPasswordHasFocus: false,
      );

      // enter new password with a number
      await tester.enterText(newPasswordFinder, "1234");
      await tester.pump();

      expectDisabledState(
        tester: tester,
        passwordHasNumber: true,
        newPasswordHasFocus: true,
        oldPasswordHasFocus: false,
      );

      // enter password without eight characters
      await tester.enterText(newPasswordFinder, "a1234");
      await tester.pump();

      expectDisabledState(
        tester: tester,
        passwordHasNumber: true,
        passwordHasLetter: true,
        newPasswordHasFocus: true,
        oldPasswordHasFocus: false,
      );

      // enter password with all criteria
      await tester.enterText(newPasswordFinder, "abcd1234");
      await tester.pump();

      expectDisabledState(
        tester: tester,
        passwordHasNumber: true,
        passwordHasLetter: true,
        passwordHasEightCharacters: true,
        newPasswordHasFocus: true,
        oldPasswordHasFocus: false,
      );
    });
  });

  group("buttonCallback", () {
    testWidgets("displays warning if old and new passwords are the same",
        (WidgetTester tester) async {
      await pumpInsertNewPassword(tester);

      // get password finders
      final passwordFinders = find.byType(AppInputPassword);
      final oldPasswordFinder = passwordFinders.first;
      final newPasswordFinder = passwordFinders.last;

      // get password warnings
      final warning = find.widgetWithText(
        Warning,
        "A nova senha deve ser diferente da senha atual.",
      );

      // get InsertNewPasswordState
      InsertNewPasswordState state =
          tester.state(find.byType(InsertNewPassword));

      // enter valid and identical passwords
      await tester.enterText(oldPasswordFinder, "abcd1234");
      await tester.enterText(newPasswordFinder, "abcd1234");
      await tester.pump();

      // before tapping button, there are no warnings
      expect(state.registrationWarnings, isNull);
      expect(warning, findsNothing);

      // display passwordWarnings is true
      expect(state.displayPasswordChecks, isTrue);

      // tap AppButton
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // after tapping buton, registrationWarnings is not null
      expect(state.registrationWarnings, isNotNull);
      expect(warning, findsOneWidget);

      // display passwordWarnings is false
      expect(state.displayPasswordChecks, isFalse);
    });

    void testUpdatingPassword({
      @required WidgetTester tester,
      String errorCode,
      @required String expectedMessage,
      @required bool failWhenReauthenticating,
      @required bool failWhenUpdatingPassword,
    }) async {
      // define old and new passwords
      String oldPassword = "oldpass123";
      String newPassword = "newpass123";

      // set mocks to throw old-password error
      when(mockUser.email).thenReturn("test@provider.com");
      if (failWhenReauthenticating) {
        when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
          throw FirebaseAuthException(message: "message", code: errorCode);
        });
      } else {
        when(mockUser.reauthenticateWithCredential(any)).thenAnswer((_) {
          return Future.value();
        });
      }
      if (failWhenUpdatingPassword) {
        when(mockUser.updatePassword(any)).thenAnswer((_) {
          throw FirebaseAuthException(message: "message", code: errorCode);
        });
      } else {
        when(mockUser.updatePassword(any)).thenAnswer((_) {
          return Future.value();
        });
      }

      await pumpInsertNewPassword(tester);

      // get password finders
      final passwordFinders = find.byType(AppInputPassword);
      final oldPasswordFinder = passwordFinders.first;
      final newPasswordFinder = passwordFinders.last;

      // get password warnings
      final warning = find.widgetWithText(Warning, expectedMessage);

      // get InsertNewPasswordState
      InsertNewPasswordState state =
          tester.state(find.byType(InsertNewPassword));

      // enter valid and different passwords
      await tester.enterText(oldPasswordFinder, oldPassword);
      await tester.enterText(newPasswordFinder, newPassword);
      await tester.pump();

      // before tapping button, there are no warnings
      expect(state.registrationWarnings, isNull);
      expect(warning, findsNothing);

      // display passwordWarnings is true
      expect(state.displayPasswordChecks, isTrue);

      // tap AppButton
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // after tapping buton, registrationWarnings is not null
      expect(state.registrationWarnings, isNotNull);
      expect(warning, findsOneWidget);

      // display passwordWarnings is false
      expect(state.displayPasswordChecks, isFalse);
    }

    testWidgets("displays warning on wrong-password when reauthenticating",
        (WidgetTester tester) async {
      testUpdatingPassword(
        tester: tester,
        errorCode: "wrong-password",
        expectedMessage: "Senha incorreta. Tente novamente.",
        failWhenReauthenticating: true,
        failWhenUpdatingPassword: false,
      );
    });

    testWidgets("displays warning on too-many-requests  when reauthenticating",
        (WidgetTester tester) async {
      testUpdatingPassword(
        tester: tester,
        errorCode: "too-many-requests",
        expectedMessage:
            "Muitas tentativas sucessivas. Tente novamente mais tarde.",
        failWhenReauthenticating: true,
        failWhenUpdatingPassword: false,
      );
    });

    testWidgets(
        "displays warning on any other error code when reauthenticating",
        (WidgetTester tester) async {
      testUpdatingPassword(
        tester: tester,
        errorCode: "anything-else",
        expectedMessage: "Algo deu errado. Tente novamente mais tarde.",
        failWhenReauthenticating: true,
        failWhenUpdatingPassword: false,
      );
    });

    testWidgets("displays warning on weak-password when updating pasword",
        (WidgetTester tester) async {
      testUpdatingPassword(
        tester: tester,
        errorCode: "weak-password",
        expectedMessage: "Nova senha muito fraca. Tente novamente.",
        failWhenReauthenticating: false,
        failWhenUpdatingPassword: true,
      );
    });

    testWidgets("displays warning on anything else when updating pasword",
        (WidgetTester tester) async {
      testUpdatingPassword(
        tester: tester,
        errorCode: "anything-else",
        expectedMessage:
            "Falha ao atualizar senha. Saia da conta, entre novamente e tente outra vez.",
        failWhenReauthenticating: false,
        failWhenUpdatingPassword: true,
      );
    });

    testWidgets("displays success warning when updating pasword successfully",
        (WidgetTester tester) async {
      testUpdatingPassword(
        tester: tester,
        expectedMessage: "Senha atualizada com sucesso!",
        failWhenReauthenticating: false,
        failWhenUpdatingPassword: false,
      );
    });
  });
}

void expectEnabledState({
  @required WidgetTester tester,
  bool nullButtonChild,
  bool nullRegistrationWarnings,
  bool displayPasswordChecks,
  bool oldPasswordHasFocus,
  bool newPasswordHasFocus,
}) {
  expectState(
    tester: tester,
    nullCallback: false,
    nullButtonChild: nullButtonChild ?? true,
    nullRegistrationWarnings: nullRegistrationWarnings ?? true,
    disabledColor: false,
    screenIsLocked: false,
    displayPasswordChecks: displayPasswordChecks ?? true,
    passwordHasEightCharacters: true,
    passwordHasLetter: true,
    passwordHasNumber: true,
    oldPasswordHasFocus: oldPasswordHasFocus ?? false,
    newPasswordHasFocus: newPasswordHasFocus ?? true,
  );
}

void expectDisabledState({
  @required WidgetTester tester,
  bool screenIsLocked,
  bool displayPasswordChecks,
  bool passwordHasEightCharacters,
  bool passwordHasLetter,
  bool passwordHasNumber,
  bool oldPasswordHasFocus,
  bool newPasswordHasFocus,
}) {
  expectState(
    tester: tester,
    nullCallback: true,
    nullButtonChild: true,
    nullRegistrationWarnings: true,
    disabledColor: true,
    screenIsLocked: false,
    displayPasswordChecks: displayPasswordChecks ?? true,
    passwordHasEightCharacters: passwordHasEightCharacters ?? false,
    passwordHasLetter: passwordHasLetter ?? false,
    passwordHasNumber: passwordHasNumber ?? false,
    oldPasswordHasFocus: oldPasswordHasFocus ?? true,
    newPasswordHasFocus: newPasswordHasFocus ?? false,
  );
}

void expectState({
  @required WidgetTester tester,
  @required bool nullCallback,
  @required bool nullButtonChild,
  @required bool nullRegistrationWarnings,
  @required bool disabledColor,
  @required bool screenIsLocked,
  @required bool displayPasswordChecks,
  @required bool passwordHasEightCharacters,
  @required bool passwordHasLetter,
  @required bool passwordHasNumber,
  @required bool oldPasswordHasFocus,
  @required bool newPasswordHasFocus,
}) {
  // get InsertNewPasswordState
  InsertNewPasswordState state = tester.state(find.byType(InsertNewPassword));

  // expect null button callback, child, and registrationWarnings
  expect(state.appButtonCallback, nullCallback ? isNull : isNotNull);
  expect(state.buttonChild, nullButtonChild ? isNull : isNotNull);
  expect(state.registrationWarnings,
      nullRegistrationWarnings ? isNull : isNotNull);

  // expect disabled buttonColor
  expect(
      state.appButtonColor,
      equals(
        disabledColor ? AppColor.disabled : AppColor.primaryPink,
      ));

  // screen lock
  expect(state.lockScreen, equals(screenIsLocked));

  // displayPassswordWarnings
  expect(state.displayPasswordChecks, equals(displayPasswordChecks));

  // password checks
  expect(state.passwordChecks[0], equals(passwordHasEightCharacters));
  expect(state.passwordChecks[1], equals(passwordHasLetter));
  expect(state.passwordChecks[2], equals(passwordHasNumber));
}
