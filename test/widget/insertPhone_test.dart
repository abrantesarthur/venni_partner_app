import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/insertSmsCode.dart';
import 'package:partner_app/screens/documents.dart';
import 'package:partner_app/screens/home.dart';
import 'package:partner_app/screens/insertEmail.dart';
import 'package:partner_app/screens/insertName.dart';
import 'package:partner_app/screens/insertPhone.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/vendors/firebaseAuth.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/inputPhone.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';
import '../mocks.dart';

void main() {
  // define mockers behaviors
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.displayName).thenReturn("Fulano");
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
    when(mockFirebaseDatabase.reference()).thenReturn(mockDatabaseReference);
    when(mockDatabaseReference.child(any)).thenReturn(mockDatabaseReference);
    when(mockDatabaseReference.onValue).thenAnswer((_) => mockEvent);
    when(mockEvent.listen(any)).thenAnswer((_) => mockStreamSubscription);
    when(mockFirebaseModel.hasClientAccount).thenReturn(true);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
    when(mockPartnerModel.name).thenReturn("Fulano");
    when(mockPartnerModel.cnhSubmitted).thenReturn(true);
    when(mockPartnerModel.crlvSubmitted).thenReturn(true);
    when(mockPartnerModel.photoWithCnhSubmitted).thenReturn(true);
    when(mockPartnerModel.profilePhotoSubmitted).thenReturn(true);
    when(mockPartnerModel.bankAccountSubmitted).thenReturn(true);
  });

  void setupFirebaseMocks({
    @required WidgetTester tester,
    @required String verifyPhoneNumberCallbackName,
    bool userHasPartnerAccount,
    bool partnerAccountStatusIsApproved,
    bool userHasClientAccount,
    bool signInSucceeds,
    FirebaseAuthException firebaseAuthException,
  }) {
    when(mockUserCredential.user).thenReturn(mockUser);

    if (userHasPartnerAccount != null && userHasPartnerAccount) {
      when(mockDatabaseReference.once()).thenAnswer(
        (_) => Future.value(mockDataSnapshot),
      );
      if (partnerAccountStatusIsApproved) {
        when(mockDataSnapshot.value).thenReturn(
          {"account_status": "approved"},
        );
      } else {
        when(mockDataSnapshot.value).thenReturn(
          {"account_status": "pending_documents"},
        );
      }
    } else {
      when(mockDataSnapshot.value).thenReturn(null);
    }

    if (userHasClientAccount != null && userHasClientAccount) {
      when(mockFirebaseModel.hasClientAccount).thenReturn(true);
    } else {
      when(mockFirebaseModel.hasClientAccount).thenReturn(false);
    }

    // mock FirebaseAuth's signInWithCredential to return mockUserCredential
    if (signInSucceeds != null && signInSucceeds) {
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer(
        (_) => Future.value(mockUserCredential),
      );
    } else {
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer(
        (_) => throw FirebaseAuthException(
          message: "error message",
          code: "error code",
        ),
      );
    }

    // get InsertPhoneNumberState
    final insertPhoneState =
        tester.state(find.byType(InsertPhone)) as InsertPhoneNumberState;

    // mock FirebaseAuth's verifyPhoneNumber to call verifyPhoneNumberCallbackName
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
            mockFirebaseAuth.verificationCompletedCallback(
              context: insertPhoneState.context,
              credential: credential,
              firebaseDatabase: mockFirebaseDatabase,
              firebaseAuth: mockFirebaseAuth,
              onExceptionCallback: (FirebaseAuthException e) =>
                  insertPhoneState.setInactiveState(
                      message: "Algo deu errado. Tente novamente."),
            );
          }
          break;
        case "verificationFailed":
          {
            String errorMsg = mockFirebaseAuth
                .verificationFailedCallback(firebaseAuthException);
            insertPhoneState.setInactiveState(message: errorMsg);
          }
          break;
        case "codeSent":
          {
            insertPhoneState.codeSentCallback(
              insertPhoneState.context,
              "verificationId123",
              123,
            );
          }
          break;
        case "codeAutoRetrievalTimeout":
        default:
          PhoneAuthCredential credential;
          mockFirebaseAuth.verificationCompletedCallback(
            context: insertPhoneState.context,
            credential: credential,
            firebaseDatabase: mockFirebaseDatabase,
            firebaseAuth: mockFirebaseAuth,
            onExceptionCallback: () => insertPhoneState.setInactiveState(
                message: "Algo deu errado. Tente novamente."),
          );
          break;
      }
    });
  }

  group("state ", () {
    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => mockConnectivityModel,
          ),
        ],
        builder: (context, child) => MaterialApp(home: InsertPhone()),
      ));
    }

    testWidgets("inits as disabled", (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester);

      // expect no warning message
      expect(find.byType(Warning), findsNothing);

      // expect disabled state
      stateIsDisabled(
        tester,
        tester.state(find.byType(InsertPhone)),
        find.byType(CircularButton),
      );
      // expect autoFocus
      final inputText = tester.firstWidget(find.byType(AppInputText));
      expect(inputText,
          isA<AppInputText>().having((i) => i.autoFocus, "autoFocus", isTrue));
    });

    testWidgets("is disabled when phone is invalid", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // enter incomplete phone number into the text field
      await tester.enterText(find.byType(InputPhone), "389");

      // find InsertPhone state
      final insertPhoneState =
          tester.state(find.byType(InsertPhone)) as InsertPhoneNumberState;

      // expect incomplete phone number to show up in controller
      expect(
          insertPhoneState.phoneTextEditingController.text, equals("(38) 9"));

      // expect disabled state
      stateIsDisabled(
        tester,
        tester.state(find.byType(InsertPhone)),
        find.byType(CircularButton),
      );

      // expect no warning message
      expect(find.byType(Warning), findsNothing);
    });

    testWidgets("is enabled when phone is valid", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // enter complete phone number into the text field
      await tester.enterText(find.byType(InputPhone), "38998601275");

      // find InsertPhone state
      final insertPhoneState =
          tester.state(find.byType(InsertPhone)) as InsertPhoneNumberState;

      // expect complete phone number to show up in controller
      expect(
        insertPhoneState.phoneTextEditingController.text,
        equals("(38) 99860-1275"),
      );

      // settle state
      await tester.pump();

      // expect enabled state
      stateIsEnabled(
        tester,
        tester.state(find.byType(InsertPhone)),
        find.byType(CircularButton),
      );

      // expect a warning message
      final warningMessageFinder = find.byType(Warning);
      final warningMessageWidget = tester.firstWidget(warningMessageFinder);
      expect(warningMessageFinder, findsOneWidget);
      expect(
          warningMessageWidget,
          isA<Warning>().having(
              (w) => w.message,
              "message",
              equals(
                  "O seu navegador pode se abrir para efetuar verificações :)")));

      // enter incomplete phone number into the text field
      await tester.enterText(find.byType(InputPhone), "3899860127");

      // expect incomplete phone number to show up in controller
      expect(
        insertPhoneState.phoneTextEditingController.text,
        equals("(38) 99860-127"),
      );

      // settle state
      await tester.pump();

      // expect disabled state
      stateIsDisabled(
        tester,
        tester.state(find.byType(InsertPhone)),
        find.byType(CircularButton),
      );

      // expect no warning message
      expect(warningMessageFinder, findsNothing);
    });
  });

  group("verificationCompleted ", () {
    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => mockConnectivityModel,
          ),
          ChangeNotifierProvider<PartnerModel>(
            create: (context) => mockPartnerModel,
          )
        ],
        builder: (context, child) => MaterialApp(
          home: InsertPhone(),
          onGenerateRoute: (RouteSettings settings) {
            // if Documents is pushed
            if (settings.name == Documents.routeName) {
              return MaterialPageRoute(builder: (context) {
                return Documents(
                  firebase: mockFirebaseModel,
                  partner: mockPartnerModel,
                );
              });
            }
            return null;
          },
          routes: {
            Home.routeName: (context) => Home(),
            InsertEmail.routeName: (context) => InsertEmail(
                  userCredential: mockUserCredential,
                ),
            InsertName.routeName: (context) => InsertName(
                  userCredential: mockUserCredential,
                  userEmail: "example@provider.com",
                ),
          },
          // mockNavigatorObserver will receive all navigation events
          navigatorObservers: [mockNavigatorObserver],
        ),
      ));
    }

    testWidgets("displays warning when sign in fails", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "verificationCompleted",
        signInSucceeds: false,
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber,
      // calling verificationCompletedCallback
      await tester.tap(find.byType(CircularButton));
      await tester.pump();

      // after tapping button, there is a Warning about failed sign in
      final warningFinder =
          find.widgetWithText(Warning, "Algo deu errado. Tente novamente.");
      expect(warningFinder, findsOneWidget);
    });

    testWidgets(
        "pushes Home when user has a partner account with 'approved' status", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // tester.pumpWidget() built our widget and triggered the
      // pushObserver method on the mockNavigatorObserver once.
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; mockFirebaseDatabase.getPilotFromID
      // returns mockPilotInterface (i.e., userHasPartnerAccount is true), and
      // mockPartnerInterface.accountStatus returns 'AccountStatus.approved'
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "verificationCompleted",
        userHasPartnerAccount: true,
        partnerAccountStatusIsApproved: true,
        signInSucceeds: true,
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // before tapping button, we are still in InsertPhoneScreen
      expect(find.byType(InsertPhone), findsOneWidget);
      expect(find.byType(Home), findsNothing);

      // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber
      // calling verificationCompletedCallback
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, we are go to Home
      expect(find.byType(InsertPhone), findsNothing);
      expect(find.byType(Home), findsOneWidget);
    });

    testWidgets(
        "pushes Document when user has a partner account without 'approved' status",
        (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // tester.pumpWidget() built our widget and triggered the
      // pushObserver method on the mockNavigatorObserver once.
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; mockFirebaseDatabase.getPilotFromID
      // returns mockPilotInterface (i.e., userHasPartnerAccount is true), and
      // mockPartnerInterface.accountStatus returns 'AccountStatus.approved'
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "verificationCompleted",
        userHasPartnerAccount: true,
        partnerAccountStatusIsApproved: false,
        signInSucceeds: true,
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // before tapping button, we are still in InsertPhoneScreen
      expect(find.byType(InsertPhone), findsOneWidget);
      expect(find.byType(Documents), findsNothing);

      // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber
      // calling verificationCompletedCallback
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, we are go to Home
      expect(find.byType(InsertPhone), findsNothing);
      expect(find.byType(Documents), findsOneWidget);
    });

    testWidgets("pushes InsertName when user already has a client account", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // tester.pumpWidget() built our widget and triggered the
      // pushObserver method on the mockNavigatorObserver once.
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; mockFirebaseDatabase.getPilotFromID
      // returns mockPilotInterface (i.e., userHasPartnerAccount is true), and
      // mockPartnerInterface.accountStatus returns 'AccountStatus.approved'
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "verificationCompleted",
        userHasPartnerAccount: false,
        userHasClientAccount: true,
        signInSucceeds: true,
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // before tapping button, we are still in InsertPhoneScreen
      expect(find.byType(InsertPhone), findsOneWidget);
      expect(find.byType(InsertName), findsNothing);

      // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber
      // calling verificationCompletedCallback
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, we are go to Home
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertPhone), findsNothing);
      expect(find.byType(InsertName), findsOneWidget);
    });

    testWidgets(
        "pushes InsertEmail when user doesn't have any account whatsoever", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // tester.pumpWidget() built our widget and triggered the
      // pushObserver method on the mockNavigatorObserver once.
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; mockFirebaseDatabase.getPilotFromID
      // returns mockPilotInterface (i.e., userHasPartnerAccount is true), and
      // mockPartnerInterface.accountStatus returns 'AccountStatus.approved'
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "verificationCompleted",
        signInSucceeds: true,
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // before tapping button, we are still in InsertPhoneScreen
      expect(find.byType(InsertPhone), findsOneWidget);
      expect(find.byType(InsertEmail), findsNothing);

      // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber
      // calling verificationCompletedCallback
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, we are go to Home
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertPhone), findsNothing);
      expect(find.byType(InsertEmail), findsOneWidget);
    });
  });

  group("verificationFailed ", () {
    void testVerificationFailed({
      @required String errorCode,
      @required String warningMessage,
    }) {
      testWidgets("called with " + errorCode, (
        WidgetTester tester,
      ) async {
        // add InsertPhone to the UI
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<FirebaseModel>(
                create: (context) => mockFirebaseModel),
            ChangeNotifierProvider<ConnectivityModel>(
              create: (context) => mockConnectivityModel,
            ),
          ],
          builder: (context, child) => MaterialApp(
            home: InsertPhone(),
          ),
        ));
        // verifyPhoneNumber calls verificationFailed with exception
        final e = FirebaseAuthException(
          message: "m",
          code: errorCode,
        );
        setupFirebaseMocks(
          tester: tester,
          verifyPhoneNumberCallbackName: "verificationFailed",
          firebaseAuthException: e,
        );

        // enter valid phone number to enable circular button callback
        await tester.enterText(find.byType(InputPhone), "38998601275");
        await tester.pumpAndSettle();

        // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber
        // calling verificationFailed
        await tester.tap(find.byType(CircularButton));
        await tester.pump();

        // after tapping button, we receive a warnign about invalid phone number
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

  group("codeSent", () {
    testWidgets("redirects to InsertSmsCode screen", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FirebaseModel>(
                create: (context) => mockFirebaseModel),
            ChangeNotifierProvider<ConnectivityModel>(
              create: (context) => mockConnectivityModel,
            ),
          ],
          child: MaterialApp(
            home: InsertPhone(),
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

      // verifyPhoneNumber calls codeSent
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "codeSent",
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // tapping button triggers buttonCallback, calling codeSent
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, we go to the InsertSmsCode screen
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertPhone), findsNothing);
      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      final insertSmsCodeWidget = tester.firstWidget(insertSmsCodeFinder);
      expect(insertSmsCodeFinder, findsOneWidget);
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
    });
  });
}

void stateIsEnabled(
  WidgetTester tester,
  InsertPhoneNumberState insertPhoneState,
  Finder circularButtonFinder,
) {
  // find CircularButton widget
  final circularButtonWidget = tester.firstWidget(circularButtonFinder);

  // expect not null phoneNumber
  expect(insertPhoneState.phoneNumber, isNotNull);

  // expect not null circularButtonCallback
  expect(insertPhoneState.circularButtonCallback, isNotNull);

  // expect primaryPink as button color
  expect(
      circularButtonWidget,
      isA<CircularButton>().having(
          (c) => c.buttonColor, "ButtonColor", equals(AppColor.primaryPink)));
}

void stateIsDisabled(
  WidgetTester tester,
  InsertPhoneNumberState insertPhoneState,
  Finder circularButtonFinder,
) {
  // find CircularButton widget
  final circularButtonWidget = tester.firstWidget(circularButtonFinder);

  // expect null phoneNumber
  expect(insertPhoneState.phoneNumber, isNull);

  // expect null circularButtonCallback
  expect(insertPhoneState.circularButtonCallback, isNull);

  // expect disabled color
  expect(
      circularButtonWidget,
      isA<CircularButton>().having(
          (c) => c.buttonColor, "ButtonColor", equals(AppColor.disabled)));
}
