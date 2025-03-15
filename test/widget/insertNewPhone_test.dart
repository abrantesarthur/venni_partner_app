import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/insertNewPhone.dart';
import 'package:partner_app/screens/insertSmsCode.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseAuth.dart';
import 'package:partner_app/widgets/appButton.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/arrowBackButton.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/inputPhone.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/utils/utils.dart';
import '../mocks.dart';

void main() {
  // define mockers behaviors
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
    when(mockFirebaseModel.isUserSignedIn).thenReturn(true);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
  });

  void setVerifyPhoneNumberMock({
    required WidgetTester tester,
    required verifyPhoneNumberCallbackName,
    FirebaseAuthException exception,
  }) {
    // get InsertNewPhoneState
    final InsertNewPhoneState insertNewPhoneState =
        tester.state(find.byType(InsertNewPhone));

    when(
      mockFirebaseAuth.verifyPhoneNumber(
        phoneNumber: anyNamed("phoneNumber"),
        verificationCompleted: anyNamed("verificationCompleted"),
        verificationFailed: anyNamed("verificationFailed"),
        codeSent: anyNamed("codeSent"),
        codeAutoRetrievalTimeout: anyNamed("codeAutoRetrievalTimeout"),
        timeout: anyNamed("timeout"),
        forceResendingToken: anyNamed("forceResendingToken"),
      ),
    ).thenAnswer((_) async {
      switch (verifyPhoneNumberCallbackName) {
        case "verificationCompleted":
          {
            PhoneAuthCredential credential;
            insertNewPhoneState.verificationCompletedCallback(
              context: insertNewPhoneState.context,
              credential: credential,
            );
          }
          break;
        case "verificationFailed":
          {
            String errorMsg =
                mockFirebaseAuth.verificationFailedCallback(exception);
            insertNewPhoneState.setInactiveState(message: errorMsg);
          }
          break;
        case "codeSent":
          {
            insertNewPhoneState.codeSentCallback(
              insertNewPhoneState.context,
              "verificationId123",
              123,
            );
          }
          break;
        case "codeAutoRetrievalTimeout":
        default:
          PhoneAuthCredential credential;
          mockFirebaseAuth.verificationCompletedCallback(
            context: insertNewPhoneState.context,
            credential: credential,
            firebaseDatabase: mockFirebaseDatabase,
            firebaseAuth: mockFirebaseAuth,
            onExceptionCallback: () => insertNewPhoneState.setInactiveState(
                message: "Algo deu errado. Tente novamente."),
          );
          break;
      }
    });
  }

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<PartnerModel>(
              create: (context) => mockPartnerModel),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => mockConnectivityModel,
          ),
        ],
        builder: (context, child) => MaterialApp(
          home: InsertNewPhone(),
        ),
      ),
    );
  }

  group("state", () {
    testWidgets("inits as disabled", (WidgetTester tester) async {
      await pumpWidget(tester);

      // get InsertNewPhoneState
      InsertNewPhoneState insertNewPhoneState =
          tester.state(find.byType(InsertNewPhone));

      // expect null circularButtonCallback, buttonChild, phoneNumber, warningMessge, and resentToken
      expect(insertNewPhoneState.appButtonCallback, isNull);
      expect(insertNewPhoneState.buttonChild, isNull);
      expect(insertNewPhoneState.phoneNumber, isNull);
      expect(insertNewPhoneState.warningMessage, isNull);
      expect(insertNewPhoneState.resendToken, isNull);

      // find CircularButton widget
      final appButtonFinder = find.byType(AppButton);
      final appButtonWidget = tester.firstWidget(appButtonFinder);

      // expect disabled color
      expect(
          appButtonWidget,
          isA<AppButton>().having(
              (c) => c.buttonColor, "ButtonColor", equals(AppColor.disabled)));

      // expect no warning message
      expect(find.byType(Warning), findsNothing);
    });
    testWidgets("is disabled when user inserts invalid phone number", (
      WidgetTester tester,
    ) async {
      // place widget in the UI
      await pumpWidget(tester);

      // find InputPhone
      final inputPhoneFinder = find.byType(InputPhone);
      expect(inputPhoneFinder, findsOneWidget);

      // enter incomplete phone number into InputPhone
      await tester.enterText(inputPhoneFinder, "3899999999");

      // get InsertNewPhoneState
      InsertNewPhoneState insertNewPhoneState =
          tester.state(find.byType(InsertNewPhone));

      // expect incomplete phone number to show up in controller
      expect(
          insertNewPhoneState.phoneController.text, equals("(38) 99999-999"));

      // expect disabled state
      expectInactiveState(tester: tester);

      // expect no warning message
      expect(find.byType(Warning), findsNothing);
    });

    testWidgets("is enabled when user inserts invalid phone number", (
      WidgetTester tester,
    ) async {
      // place widget in the UI
      await pumpWidget(tester);

      // find InputPhone
      final inputPhoneFinder = find.byType(InputPhone);
      expect(inputPhoneFinder, findsOneWidget);

      // enter valid phone number into InputPhone
      await tester.enterText(inputPhoneFinder, "38999999999");

      // get InsertNewPhoneState
      InsertNewPhoneState insertNewPhoneState =
          tester.state(find.byType(InsertNewPhone));
      await tester.pump();

      // expect complete phone number to show up in controller
      expect(
          insertNewPhoneState.phoneController.text, equals("(38) 99999-9999"));

      // expect enabled state
      expectActiveState(
        tester: tester,
        phoneNumber: "+55 (38) 99999-9999",
        message: "O seu navegador pode se abrir para efetuar verificações :)",
      );
    });
  });

  group("buttonCallback", () {
    testWidgets("doesn't allow change to same number",
        (WidgetTester tester) async {
      // place InsertNewPhone in the UI
      await pumpWidget(tester);

      // set mock to return user's number +5538888888888
      when(mockUser.phoneNumber).thenReturn("+5538888888888");

      // insert same number to InputPhone
      final inputPhoneFinder = find.byType(InputPhone);
      await tester.enterText(inputPhoneFinder, "38888888888");
      await tester.pump();

      // expect enabled state
      expectActiveState(
        tester: tester,
        phoneNumber: "+55 (38) 88888-8888",
        message: "O seu navegador pode se abrir para efetuar verificações :)",
      );

      // // tap AppButton to trigget buttonCallback
      final appButtonFinder = find.byType(AppButton);
      expect(appButtonFinder, findsOneWidget);
      await tester.tap(appButtonFinder);
      await tester.pump();

      // expect inactive state with warning
      expectInactiveState(
        tester: tester,
        message: "O número inserido é igual ao número atual. Tente outro.",
      );
    });

    testWidgets("prevent user interaction before calling verifyPhoneNumber",
        (WidgetTester tester) async {
      // place InsertNewPhone in the UI
      await pumpWidget(tester);

      // set mock to return user's number +5538888888888
      when(mockUser.phoneNumber).thenReturn("+5538888888888");

      // insert same number to InputPhone
      final inputPhoneFinder = find.byType(InputPhone);
      await tester.enterText(inputPhoneFinder, "38999999999");
      await tester.pump();

      // expect enabled state
      expectActiveState(
        tester: tester,
        phoneNumber: "+55 (38) 99999-9999",
        message: "O seu navegador pode se abrir para efetuar verificações :)",
      );

      // before tapping, interaction is enabled
      InsertNewPhoneState insertNewPhoneState =
          tester.state(find.byType(InsertNewPhone));
      expect(insertNewPhoneState.lockScreen, isFalse);
      expect(insertNewPhoneState.buttonChild, isNull);
      expect(insertNewPhoneState.phoneFocusNode.hasFocus, isTrue);

      // // tap AppButton to trigget buttonCallback
      final appButtonFinder = find.byType(AppButton);
      expect(appButtonFinder, findsOneWidget);
      await tester.tap(appButtonFinder);
      await tester.pump();

      // after tapping, interaction is enabled
      expect(insertNewPhoneState.lockScreen, isTrue);
      expect(insertNewPhoneState.buttonChild, isNotNull);
      expect(insertNewPhoneState.phoneFocusNode.hasFocus, isFalse);
    });
  });

  group("verificationCompleted", () {
    testWidgets(
        "calls currentUser.updatePhoneNumber and set success state upon success",
        (WidgetTester tester) async {
      // add InsertNewPhone to the UI
      await pumpWidget(tester);

      final String oldPhoneNumber = "+5538888888888";
      final String newPhoneNumber = "+5538999999999";

      // before updatePhoneNumber is called, user has old phoneNumber
      when(mockUser.phoneNumber).thenReturn(oldPhoneNumber);
      when(mockUser.updatePhoneNumber(any)).thenAnswer((_) async {
        // when update phoneNumber is called, phone Number is updated to newPhoneNumber
        when(mockUser.phoneNumber).thenReturn(newPhoneNumber);
      });
      // mock FirebaseAuth's verifyPhoneNumber to call verifyPhoneNumberCallbackName
      setVerifyPhoneNumberMock(
        tester: tester,
        verifyPhoneNumberCallbackName: "verificationCompleted",
      );

      // insert newPhoneNumber number to InputPhone
      final inputPhoneFinder = find.byType(InputPhone);
      await tester.enterText(inputPhoneFinder, newPhoneNumber.substring(3));
      await tester.pump();

      // tap AppButton to trigger buttonCallback
      final appButtonFinder = find.byType(AppButton);
      expect(appButtonFinder, findsOneWidget);
      await tester.tap(appButtonFinder);
      await tester.pumpAndSettle();

      // expect success warning message
      final warningFinder = find.byType(Warning);
      expect(warningFinder, findsOneWidget);
      final warningWidget = tester.firstWidget(warningFinder);
      expect(
          warningWidget,
          isA<Warning>().having((w) => w.message, "message",
              contains("Número alterado com sucesso para ")));
    });
  });

  group("verificationFailed", () {
    void testVerificationFailed({
      required String errorCode,
      required String warningMessage,
    }) {
      testWidgets("called with " + errorCode, (
        WidgetTester tester,
      ) async {
        // add InsertPhone to the UI
        await pumpWidget(tester);

        // verifyPhoneNumber calls verificationFailed with exception
        final e = FirebaseAuthException(
          message: "m",
          code: errorCode,
        );
        setVerifyPhoneNumberMock(
          tester: tester,
          verifyPhoneNumberCallbackName: "verificationFailed",
          exception: e,
        );

        // enter valid phone number to enable circular button callback
        await tester.enterText(find.byType(InputPhone), "38998601275");
        await tester.pumpAndSettle();

        // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber
        // calling verificationFailed
        await tester.tap(find.byType(AppButton));
        await tester.pump();

        // after tapping button, we receive a warning about exception
        final warningFinder = find.byType(Warning);
        expect(
            tester.firstWidget(warningFinder),
            isA<Warning>().having(
              (w) => w.message,
              "message",
              equals(warningMessage),
            ));
      });
    }

    testVerificationFailed(
      errorCode: "invalid-phone-number",
      warningMessage: "Número de telefone inválido. Por favor, tente outro.",
    );

    testVerificationFailed(
      errorCode: "too-many-requests",
      warningMessage:
          "Ops, número de tentativas excedidas. Tente novamente em alguns minutos.",
    );

    testVerificationFailed(
      errorCode: "any other error code",
      warningMessage: "Ops, algo deu errado. Tente novamente mais tarde.",
    );
  });

  group("codeSentCallback", () {
    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserModel>(
                create: (context) => mockFirebaseModel),
            ChangeNotifierProvider<PartnerModel>(
                create: (context) => mockPartnerModel),
            ChangeNotifierProvider<ConnectivityModel>(
              create: (context) => mockConnectivityModel,
            ),
          ],
          builder: (context, child) => MaterialApp(
            home: InsertNewPhone(),
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == InsertSmsCode.routeName) {
                final InsertSmsCodeArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return InsertSmsCode(
                    verificationId: args.verificationId,
                    resendToken: args.resendToken,
                    phoneNumber: args.phoneNumber,
                    mode: args.mode,
                  );
                });
              }
              assert(false, 'Need to implement ${settings.name}');
              return null;
            },
            navigatorObservers: [mockNavigatorObserver],
          ),
        ),
      );
    }

    testWidgets(
        "pushes InsertSmsCode screen which, on success, returns displaying success",
        (WidgetTester tester) async {
      // push InsertNewPhone to the UI
      await pumpWidget(tester);

      // set mocks to succesfully change phone number
      final String oldPhoneNumber = "+5538888888888";
      final String newPhoneNumber = "+5538999999999";

      // before updatePhoneNumber is called, user has old phoneNumber
      when(mockUser.phoneNumber).thenReturn(oldPhoneNumber);
      when(mockUser.updatePhoneNumber(any)).thenAnswer((_) {
        // after updatePhoneNumber is called, user has new phoneNumber
        when(mockUser.phoneNumber).thenReturn(newPhoneNumber);
        return Future.value();
      });
      // verifyPhoneNumber calls codeSentCallbacks
      setVerifyPhoneNumberMock(
        tester: tester,
        verifyPhoneNumberCallbackName: "codeSent",
      );

      // expect InsertNewPhone to be pushed
      final insertNewPhoneFinder = find.byType(InsertNewPhone);
      expect(insertNewPhoneFinder, findsOneWidget);
      verify(mockNavigatorObserver.didPush(any, any));

      // enter new phone number to enable circular button callback
      await tester.enterText(
          find.byType(InputPhone), newPhoneNumber.substring(3));
      await tester.pumpAndSettle();

      // tapping button triggers buttonCallback, calling mocked codeSentCallbakc
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // after tapping button, we go to the InsertSmsCode screen
      verify(mockNavigatorObserver.didPush(any, any));
      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      final insertSmsCodeWidget = tester.firstWidget(insertSmsCodeFinder);
      expect(insertSmsCodeFinder, findsOneWidget);
      expect(insertNewPhoneFinder, findsNothing);
      expect(
        insertSmsCodeWidget,
        isA<InsertSmsCode>()
            .having(
              (i) => i.verificationId,
              "verificationId",
              equals("verificationId123"),
            )
            .having((i) => i.resendToken, "resendToken", 123),
      );

      // insert valid sms code
      final appInputTextFinder = find.byType(AppInputText);
      expect(appInputTextFinder, findsOneWidget);
      await tester.enterText(appInputTextFinder, "123456");
      await tester.pumpAndSettle();

      // tap CircularButton
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // verify that we navigated back
      verify(mockNavigatorObserver.didPop(any, any));
      expect(insertSmsCodeFinder, findsNothing);
      expect(insertNewPhoneFinder, findsOneWidget);

      // expect success warning message
      final warningFinder = find.byType(Warning);
      expect(warningFinder, findsOneWidget);
      final warningWidget = tester.firstWidget(warningFinder);
      expect(
          warningWidget,
          isA<Warning>().having(
              (w) => w.message,
              "message",
              contains("Número alterado com sucesso para " +
                  newPhoneNumber.withoutCountryCode())));
    });

    void testException({
      required String code,
      required String expectedWarning,
    }) {
      testWidgets(
          "pushes InsertSmsCode screen which, on '" +
              code +
              "', navigates back displaying warning",
          (WidgetTester tester) async {
        // push InsertNewPhone to the UI
        await pumpWidget(tester);

        // set mocks to succesfully change phone number
        final String oldPhoneNumber = "+5538888888888";
        final String newPhoneNumber = "+5538999999999";

        // before updatePhoneNumber is called, user has old phoneNumber
        when(mockUser.phoneNumber).thenReturn(oldPhoneNumber);
        // updating phone fails, throwing 'code'
        when(mockUser.updatePhoneNumber(any)).thenAnswer((_) {
          // after updatePhoneNumber is called, user has new phoneNumber
          throw FirebaseAuthException(message: "message", code: code);
        });

        // verifyPhoneNumber calls codeSentCallbacks
        setVerifyPhoneNumberMock(
          tester: tester,
          verifyPhoneNumberCallbackName: "codeSent",
        );

        // expect InsertNewPhone to be pushed
        final insertNewPhoneFinder = find.byType(InsertNewPhone);
        expect(insertNewPhoneFinder, findsOneWidget);
        verify(mockNavigatorObserver.didPush(any, any));

        // enter new phone number to enable circular button callback
        await tester.enterText(
            find.byType(InputPhone), newPhoneNumber.substring(3));
        await tester.pumpAndSettle();

        // tapping button triggers buttonCallback, calling mocked codeSentCallbakc
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        // after tapping button, we go to the InsertSmsCode screen
        verify(mockNavigatorObserver.didPush(any, any));
        final insertSmsCodeFinder = find.byType(InsertSmsCode);
        final insertSmsCodeWidget = tester.firstWidget(insertSmsCodeFinder);
        expect(insertSmsCodeFinder, findsOneWidget);
        expect(insertNewPhoneFinder, findsNothing);
        expect(
          insertSmsCodeWidget,
          isA<InsertSmsCode>()
              .having(
                (i) => i.verificationId,
                "verificationId",
                equals("verificationId123"),
              )
              .having((i) => i.resendToken, "resendToken", 123),
        );

        // insert any sms code
        final appInputTextFinder = find.byType(AppInputText);
        expect(appInputTextFinder, findsOneWidget);
        await tester.enterText(appInputTextFinder, "123456");
        await tester.pumpAndSettle();

        // tap CircularButton
        await tester.tap(find.byType(CircularButton));
        await tester.pumpAndSettle();

        // verify that we navigated back
        verify(mockNavigatorObserver.didPop(any, any));
        expect(insertSmsCodeFinder, findsNothing);
        expect(insertNewPhoneFinder, findsOneWidget);

        // expect failure warning message
        final warningFinder = find.byType(Warning);
        expect(warningFinder, findsOneWidget);
        final warningWidget = tester.firstWidget(warningFinder);
        expect(
            warningWidget,
            isA<Warning>()
                .having((w) => w.message, "message", equals(expectedWarning)));
      });
    }

    testException(
      code: "invalid-verification-code",
      expectedWarning: "Código inválido. Tente novamente.",
    );

    testException(
      code: "credential-already-in-use",
      expectedWarning: "O número já está sendo usado. Tente outro.",
    );

    testException(
      code: "general-error",
      expectedWarning: "Algo deu errado. Tente novamente mais tarde.",
    );

    testWidgets(
        "pushes InsertSmsCode screen which, on navigate back, returns displaying nothing",
        (WidgetTester tester) async {
      // push InsertNewPhone to the UI
      await pumpWidget(tester);

      // set mocks to succesfully change phone number
      final String oldPhoneNumber = "+5538888888888";
      final String newPhoneNumber = "+5538999999999";

      // before updatePhoneNumber is called, user has old phoneNumber
      when(mockUser.phoneNumber).thenReturn(oldPhoneNumber);
      when(mockUser.updatePhoneNumber(any)).thenAnswer((_) {
        // after updatePhoneNumber is called, user has new phoneNumber
        when(mockUser.phoneNumber).thenReturn(newPhoneNumber);
        return Future.value();
      });
      // verifyPhoneNumber calls codeSentCallback
      setVerifyPhoneNumberMock(
        tester: tester,
        verifyPhoneNumberCallbackName: "codeSent",
      );

      // expect InsertNewPhone to be pushed
      final insertNewPhoneFinder = find.byType(InsertNewPhone);
      expect(insertNewPhoneFinder, findsOneWidget);
      verify(mockNavigatorObserver.didPush(any, any));

      // enter new phone number to enable circular button callback
      await tester.enterText(
          find.byType(InputPhone), newPhoneNumber.substring(3));
      await tester.pumpAndSettle();

      // expect warning
      final warningFinder = find.byType(Warning);
      expect(warningFinder, findsOneWidget);
      final warningWidget = tester.firstWidget(warningFinder);
      expect(
          warningWidget,
          isA<Warning>().having(
              (w) => w.message,
              "message",
              contains(
                  "O seu navegador pode se abrir para efetuar verificações")));

      // tapping button triggers buttonCallback, calling mocked codeSentCallbakc
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // after tapping button, we go to the InsertSmsCode screen
      verify(mockNavigatorObserver.didPush(any, any));
      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      final insertSmsCodeWidget = tester.firstWidget(insertSmsCodeFinder);
      expect(insertSmsCodeFinder, findsOneWidget);
      expect(insertNewPhoneFinder, findsNothing);
      expect(
        insertSmsCodeWidget,
        isA<InsertSmsCode>()
            .having(
              (i) => i.verificationId,
              "verificationId",
              equals("verificationId123"),
            )
            .having((i) => i.resendToken, "resendToken", 123),
      );

      // navigate back
      final arrowBackFinder = find.byType(ArrowBackButton);
      expect(arrowBackFinder, findsOneWidget);
      await tester.tap(arrowBackFinder);
      await tester.pumpAndSettle();

      // verify that we navigated back
      verify(mockNavigatorObserver.didPop(any, any));
      expect(insertSmsCodeFinder, findsNothing);
      expect(insertNewPhoneFinder, findsOneWidget);

      // expect same old warning message
      expect(
          tester.firstWidget(warningFinder),
          isA<Warning>().having(
              (w) => w.message,
              "message",
              contains(
                  "O seu navegador pode se abrir para efetuar verificações")));
    });
  });
}

void expectActiveState({
  required WidgetTester tester,
  required String phoneNumber,
  String message,
}) {
  // get InsertNewPhoneState and AppButton finder
  InsertNewPhoneState insertNewPhoneState =
      tester.state(find.byType(InsertNewPhone));
  final appButtonFinder = find.byType(AppButton);
  final appButtonWidget = tester.firstWidget(appButtonFinder);
  // verify enabled state expectations
  expect(insertNewPhoneState.appButtonCallback, isNotNull);
  expect(insertNewPhoneState.buttonChild, isNull);
  expect(insertNewPhoneState.phoneNumber, isNotNull);
  expect(insertNewPhoneState.phoneNumber, equals(phoneNumber));
  if (message == null) {
    expect(insertNewPhoneState.warningMessage, isNull);
  } else {
    final warningFinder = find.byType(Warning);
    final warningWidget = tester.firstWidget(warningFinder);
    expect(warningFinder, findsOneWidget);
    expect(warningWidget,
        isA<Warning>().having((w) => w.message, "message", equals(message)));
  }
  expect(
      appButtonWidget,
      isA<AppButton>().having(
        (c) => c.buttonColor,
        "ButtonColor",
        equals(AppColor.primaryPink),
      ));
}

void expectInactiveState({
  required WidgetTester tester,
  String message,
}) {
  // get InsertNewPhoneState and AppButton finder
  InsertNewPhoneState insertNewPhoneState =
      tester.state(find.byType(InsertNewPhone));
  final appButtonFinder = find.byType(AppButton);
  final appButtonWidget = tester.firstWidget(appButtonFinder);
  // verify disabled state expectations
  expect(insertNewPhoneState.appButtonCallback, isNull);
  expect(insertNewPhoneState.buttonChild, isNull);
  expect(insertNewPhoneState.resendToken, isNull);
  if (message != null) {
    final warningFinder = find.byType(Warning);
    final warningWidget = tester.firstWidget(warningFinder);
    expect(warningFinder, findsOneWidget);
    expect(warningWidget,
        isA<Warning>().having((w) => w.message, "message", equals(message)));
  } else {
    expect(insertNewPhoneState.warningMessage, isNull);
  }
  expect(
      appButtonWidget,
      isA<AppButton>().having(
        (c) => c.buttonColor,
        "ButtonColor",
        equals(AppColor.disabled),
      ));
}
