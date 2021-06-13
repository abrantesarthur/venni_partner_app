import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/documents.dart';
import 'package:partner_app/screens/home.dart';
import 'package:partner_app/screens/insertEmail.dart';
import 'package:partner_app/screens/insertName.dart';
import 'package:partner_app/screens/start.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';
import 'package:partner_app/screens/insertSmsCode.dart';
import 'package:partner_app/vendors/firebaseAuth.dart';
import '../mocks.dart';

// TODO: test different modes
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.displayName).thenReturn("Fulano");
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
    when(mockFirebaseDatabase.reference()).thenReturn(mockDatabaseReference);
    when(mockDatabaseReference.child(any)).thenReturn(mockDatabaseReference);
    when(mockFirebaseModel.hasClientAccount).thenReturn(true);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
    when(mockPartnerModel.name).thenReturn("Fulano");
    when(mockPartnerModel.allDocumentsSubmitted).thenReturn(true);
    when(mockPartnerModel.cnhSubmitted).thenReturn(true);
    when(mockPartnerModel.crlvSubmitted).thenReturn(true);
    when(mockPartnerModel.photoWithCnhSubmitted).thenReturn(true);
    when(mockPartnerModel.profilePhotoSubmitted).thenReturn(true);
    when(mockPartnerModel.bankAccountSubmitted).thenReturn(true);
  });

  void setupFirebaseMocks({
    @required WidgetTester tester,
    String verifyPhoneNumberCallbackName,
    bool userHasPartnerAccount,
    bool partnerAccountStatusIsApproved,
    bool userHasClientAccount,
    bool signInSucceeds,
    FirebaseAuthException verificationCompletedException,
    Function verificationCompletedOnExceptionCallback,
    FirebaseAuthException verificationFailedException,
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
    if (signInSucceeds != null &&
        signInSucceeds &&
        verificationCompletedException == null) {
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer(
        (_) => Future.value(mockUserCredential),
      );
    } else if (verificationCompletedException != null) {
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) => throw verificationCompletedException);
    } else {
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer(
        (_) => throw FirebaseAuthException(
          message: "error message",
          code: "error code",
        ),
      );
    }

    final insertSmsCodeState =
        tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

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
                context: insertSmsCodeState.context,
                credential: credential,
                firebaseDatabase: mockFirebaseDatabase,
                firebaseAuth: mockFirebaseAuth,
                onExceptionCallback: verificationCompletedOnExceptionCallback);
          }
          break;
        case "verificationFailed":
          {
            insertSmsCodeState.resendCodeVerificationFailedCallback(
                verificationFailedException);
          }
          break;
        case "codeSent":
          {
            insertSmsCodeState.codeSentCallback("verificationId", 123);
          }
          break;
        case "codeAutoRetrievalTimeout":
        default:
          PhoneAuthCredential credential;
          mockFirebaseAuth.verificationCompletedCallback(
            context: insertSmsCodeState.context,
            credential: credential,
            firebaseDatabase: mockFirebaseDatabase,
            firebaseAuth: mockFirebaseAuth,
            onExceptionCallback: () => insertSmsCodeState.setState(() {
              insertSmsCodeState.warningMessage =
                  Warning(message: "Algo deu errado. Tente novamente");
            }),
          );
          break;
      }
    });
  }

  group("state ", () {
    Future<void> pumpInsertSmsCodeWidget(WidgetTester tester) async {
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
            home: InsertSmsCode(
              verificationId: "verificationId",
              resendToken: 123,
              phoneNumber: "+55 (38) 99999-9999",
              mode: InsertSmsCodeMode.insertNewPhone,
            ),
          ),
        ),
      );
    }

    testWidgets("inits as disabled", (WidgetTester tester) async {
      await pumpInsertSmsCodeWidget(tester);

      // expect resendCodewarning and editPhoneWarning messages
      final warningFinder = find.byType(Warning);
      final warningWidgets = tester.widgetList(warningFinder);
      expect(warningFinder, findsNWidgets(2));
      expect(
          warningWidgets.elementAt(0),
          isA<Warning>().having(
              (w) => w.message, "message", contains("Reenviar o código em")));
      expect(
          warningWidgets.elementAt(1),
          isA<Warning>().having((w) => w.message, "message",
              equals("Editar o número do meu celular")));

      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      // expect disabled state
      stateIsDisabled(tester.state(insertSmsCodeFinder));
      // expect autoFocus
      final inputText = tester.firstWidget(find.byType(AppInputText));
      expect(inputText,
          isA<AppInputText>().having((i) => i.autoFocus, "autoFocus", isTrue));
    });

    testWidgets("is disabled if incomplete code is entered",
        (WidgetTester tester) async {
      await pumpInsertSmsCodeWidget(tester);

      // insert incomplete sms code
      await tester.enterText(find.byType(AppInputText), "12345");

      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      final insertSmsCodeState =
          tester.state(insertSmsCodeFinder) as InsertSmsCodeState;

      // expect incomplete number to show up in controller
      expect(insertSmsCodeState.smsCodeTextEditingController.text,
          equals("12345"));

      // expect disabled state
      stateIsDisabled(insertSmsCodeState);
    });

    testWidgets("is enabled if complete code is entered",
        (WidgetTester tester) async {
      await pumpInsertSmsCodeWidget(tester);

      // insert complete sms code
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);

      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      final insertSmsCodeState =
          tester.state(insertSmsCodeFinder) as InsertSmsCodeState;

      stateIsEnabled(insertSmsCodeState, completeCode);

      // insert incomplete sms code again
      await tester.enterText(find.byType(AppInputText), "12345");

      // expect disabled state
      stateIsDisabled(insertSmsCodeState);
    });
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
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
        child: MaterialApp(
          home: InsertSmsCode(
            verificationId: "verificationId",
            resendToken: 123,
            phoneNumber: "+55 (38) 99999-9999",
            mode: InsertSmsCodeMode.insertNewPhone,
          ),
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
            Start.routeName: (context) => Start(),
            InsertEmail.routeName: (context) => InsertEmail(
                  userCredential: mockUserCredential,
                ),
            InsertName.routeName: (context) => InsertName(
                  userCredential: mockUserCredential,
                  userEmail: "example@provider.com",
                ),
          },
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  group("verifySmsCode ", () {
    testWidgets(
        "disables warning, callback and displays CircularProgressIndicator",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // code verification succeeds and user is registered
      setupFirebaseMocks(
        tester: tester,
        userHasClientAccount: true,
        signInSucceeds: true,
      );

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no Home screen
      expect(find.byType(Home), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // before tapping button, there is the following state
      final insertSmsState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;
      expect(insertSmsState.circularButtonCallback, isNotNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // tap circular button and update state once
      await tester.tap(find.byType(CircularButton));
      await tester.pump();

      // after tapping button, verifySmsCode is called and sets the following state
      expect(insertSmsState.circularButtonCallback, isNull);
      expect(insertSmsState.warningMessage, isNull);
    });

    testWidgets(
        "pushes Home screen when user is registered and sign in succeeds",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; mockFirebaseDatabase.getPilotFromID
      // returns mockPilotInterface (i.e., userHasPartnerAccount is true), and
      // mockPartnerInterface.accountStatus returns 'AccountStatus.approved'
      setupFirebaseMocks(
        tester: tester,
        userHasPartnerAccount: true,
        partnerAccountStatusIsApproved: true,
        signInSucceeds: true,
      );

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no Home screen
      expect(find.byType(Home), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, Home screen is pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(Home), findsOneWidget);
      expect(find.byType(InsertSmsCode), findsNothing);
    });

    testWidgets(
        "pushes Document when user has a partner account without 'approved' status",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; mockFirebaseDatabase.getPilotFromID
      // returns mockPilotInterface (i.e., userHasPartnerAccount is true), and
      // mockPartnerInterface.accountStatus returns 'AccountStatus.approved'
      setupFirebaseMocks(
        tester: tester,
        userHasPartnerAccount: true,
        partnerAccountStatusIsApproved: false,
        signInSucceeds: true,
      );

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no Home screen
      expect(find.byType(Documents), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, Documents screen is pushed
      // verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(Documents), findsOneWidget);
      expect(find.byType(InsertSmsCode), findsNothing);
    });

    testWidgets("pushes InsertName when user already has a client account",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; mockFirebaseDatabase.getPilotFromID
      // returns mockPilotInterface (i.e., userHasPartnerAccount is true), and
      // mockPartnerInterface.accountStatus returns 'AccountStatus.approved'
      setupFirebaseMocks(
        tester: tester,
        userHasClientAccount: true,
        signInSucceeds: true,
      );

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no Home screen
      expect(find.byType(InsertName), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, InsertName screen is pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertName), findsOneWidget);
      expect(find.byType(InsertSmsCode), findsNothing);
    });

    testWidgets(
        "pushes InsertEmail when user doesn't have any account whatsoever",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; mockFirebaseDatabase.getPilotFromID
      // returns mockPilotInterface (i.e., userHasPartnerAccount is true), and
      // mockPartnerInterface.accountStatus returns 'AccountStatus.approved'
      setupFirebaseMocks(
        tester: tester,
        signInSucceeds: true,
      );

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no Home screen
      expect(find.byType(InsertEmail), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, InsertEmail screen is pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertEmail), findsOneWidget);
      expect(find.byType(InsertSmsCode), findsNothing);
    });

    testWidgets(
        "displays right warning when userIsRegistered but 'invalid-verification-code' exception happens",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

      // user is registered but sign in throws exception
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: "invalid-verification-code",
      );
      setupFirebaseMocks(
          tester: tester,
          userHasClientAccount: true,
          verificationCompletedException: e,
          verificationCompletedOnExceptionCallback: (e) => insertSmsCodeState
              .displayErrorMessage(insertSmsCodeState.context, e));

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no 'Código inválido' warning
      expect(
        find.widgetWithText(Warning, "Código inválido. Tente outro."),
        findsNothing,
      );

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, there is 'Código inválido" warning
      expect(
        find.widgetWithText(Warning, "Código inválido. Tente outro."),
        findsOneWidget,
      );
    });

    testWidgets(
        "displays right warning when userIsRegistered and other exceptions happen",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

      // user is registered but sign in throws exception
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: "any other code",
      );
      setupFirebaseMocks(
          tester: tester,
          userHasClientAccount: true,
          verificationCompletedException: e,
          verificationCompletedOnExceptionCallback: (e) => insertSmsCodeState
              .displayErrorMessage(insertSmsCodeState.context, e));

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no 'Algo deu errado' warning
      expect(
        find.widgetWithText(Warning, "Algo deu errado. Tente mais tarde."),
        findsNothing,
      );

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, there is 'Algo deu errado" warning
      expect(
        find.widgetWithText(Warning, "Algo deu errado. Tente mais tarde."),
        findsOneWidget,
      );
    });
  });

  group("resendCode ", () {
    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
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
          child: MaterialApp(
            home: InsertSmsCode(
              verificationId: "verificationId",
              resendToken: 123,
              phoneNumber: "+55 (38) 99999-9999",
              mode: InsertSmsCodeMode.insertNewPhone,
            ),
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
              Start.routeName: (context) => Start(),
              InsertEmail.routeName: (context) => InsertEmail(
                    userCredential: mockUserCredential,
                  ),
              InsertName.routeName: (context) => InsertName(
                    userCredential: mockUserCredential,
                    userEmail: "example@provider.com",
                  ),
            },
            navigatorObservers: [mockNavigatorObserver],
          ),
        ),
      );
    }

    void testResendCode(
      WidgetTester tester,
      Finder widgetFinder, {
      bool userHasPartnerAccount,
      bool partnerAccountStatusIsApproved,
      bool userHasClientAccount,
    }) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      // InsertSmsCode was pushed
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber triggers verificationCompleted when user is registered
      // and code is verified
      setupFirebaseMocks(
        tester: tester,
        userHasPartnerAccount: userHasPartnerAccount,
        partnerAccountStatusIsApproved: partnerAccountStatusIsApproved,
        userHasClientAccount: userHasClientAccount,
        signInSucceeds: true,
        verifyPhoneNumberCallbackName: "verificationCompleted",
      );

      // expect not to find a warning allowing to resendCode
      // tap on warning to resendCode
      final resendCodeWidgetFinder =
          find.widgetWithText(Warning, "Reenviar o código para meu celular");
      expect(resendCodeWidgetFinder, findsNothing);

      // set remainingSeconds to 0 so resendCode callback is activated
      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;
      insertSmsCodeState.setState(() {
        insertSmsCodeState.remainingSeconds = 0;
      });
      await tester.pump();

      // when remainingSeconds hits 0, find a warning allowing to resendCode
      expect(resendCodeWidgetFinder, findsOneWidget);

      // before tapping the button, there is no Home screen
      expect(widgetFinder, findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap on warning to resendCode
      await tester.tap(find.text("Reenviar o código para meu celular"));
      await tester.pumpAndSettle();

      // expect widget found by widgetFinder to be pushed
      // verify(mockNavigatorObserver.didPush(any, any));
      expect(widgetFinder, findsOneWidget);
      expect(find.byType(InsertSmsCode), findsNothing);
    }

    testWidgets(
        "pushes Home when it triggers verificationCompleted, user has 'approved' partner account",
        (WidgetTester tester) async {
      testResendCode(
        tester,
        find.byType(Home),
        userHasPartnerAccount: true,
        partnerAccountStatusIsApproved: true,
      );
    });

    testWidgets(
        "pushes Documents when it triggers verificationCompleted, user has no 'approved' partner account",
        (WidgetTester tester) async {
      testResendCode(
        tester,
        find.byType(Documents),
        userHasPartnerAccount: true,
        partnerAccountStatusIsApproved: false,
      );
    });

    testWidgets(
        "pushes InsertName when it triggers verificationCompleted, user has client account",
        (WidgetTester tester) async {
      testResendCode(
        tester,
        find.byType(InsertName),
        userHasClientAccount: true,
      );
    });

    testWidgets(
        "pushes InsertEmail when it triggers verificationCompleted, user has no account whatsoever",
        (WidgetTester tester) async {
      testResendCode(
        tester,
        find.byType(InsertEmail),
      );
    });

    testWidgets(
        "displays warning when it triggers verificationCompleted, userIsRegistered and an exception happens",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      // InsertSmsCode was pushed
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber triggers verificationCompleted when user is registered
      // and sign in triggers exception
      FirebaseAuthException e =
          FirebaseAuthException(message: "message", code: "any code");
      setupFirebaseMocks(
        tester: tester,
        userHasClientAccount: true,
        verificationCompletedException: e,
        verificationCompletedOnExceptionCallback: (FirebaseAuthException e) {
          final insertSmsCodeState =
              tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;
          insertSmsCodeState.setState(() {
            insertSmsCodeState.remainingSeconds = 15;
            insertSmsCodeState.timer = insertSmsCodeState.kickOffTimer();
            insertSmsCodeState.warningMessage =
                Warning(message: "Algo deu errado. Tente novamente");
          });
        },
        verifyPhoneNumberCallbackName: "verificationCompleted",
      );

      // expect not to find a warning allowing to resendCode
      // tap on warning to resendCode
      final resendCodeWidgetFinder =
          find.widgetWithText(Warning, "Reenviar o código para meu celular");
      expect(resendCodeWidgetFinder, findsNothing);

      // set remainingSeconds to 0 so resendCode callback is activated
      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;
      insertSmsCodeState.setState(() {
        insertSmsCodeState.remainingSeconds = 0;
      });
      await tester.pump();

      // when remainingSeconds hits 0, find a warning allowing to resendCode
      expect(resendCodeWidgetFinder, findsOneWidget);

      // before tapping the button, there is no 'Algo deu errado' warning
      final somethingWrongWarningFinder =
          find.widgetWithText(Warning, "Algo deu errado. Tente novamente");
      expect(somethingWrongWarningFinder, findsNothing);

      // tap to resendCode
      await tester.tap(find.text("Reenviar o código para meu celular"));
      await tester.pumpAndSettle();

      // after tapping the button, there is 'Algo deu errado' warning
      expect(somethingWrongWarningFinder, findsOneWidget);
    });

    void verificationFailedTest(
      WidgetTester tester, {
      String exceptionCode,
      String expectedWarningMessage,
    }) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

      // verifyPhoneNumber triggers verificationFailed with 'invalid-phone-number' exception
      // verificationFailed calls resendCodeVerificationFailedCallback just like
      // InsertSmsCodeState does
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: exceptionCode,
      );
      setupFirebaseMocks(
        tester: tester,
        verificationFailedException: e,
        verifyPhoneNumberCallbackName: "verificationFailed",
      );

      // expect not to find a warning allowing to resendCode
      // tap on warning to resendCode
      final resendCodeWidgetFinder =
          find.widgetWithText(Warning, "Reenviar o código para meu celular");
      expect(resendCodeWidgetFinder, findsNothing);

      // set remainingSeconds to 0 so resendCode callback is activated
      insertSmsCodeState.setState(() {
        insertSmsCodeState.remainingSeconds = 0;
      });
      await tester.pump();

      // when remainingSeconds hits 0, find a warning allowing to resendCode
      expect(resendCodeWidgetFinder, findsOneWidget);

      // before tapping the button, warning is null
      expect(insertSmsCodeState.warningMessage, isNull);

      // tap to resendCode
      await tester.tap(find.text("Reenviar o código para meu celular"));
      await tester.pumpAndSettle();

      // after tapping the button, warning is not null and has correct mesage
      expect(insertSmsCodeState.warningMessage, isNotNull);
      expect(
          insertSmsCodeState.warningMessage,
          isA<Warning>().having(
            (w) => w.message,
            "message",
            equals(expectedWarningMessage),
          ));
    }

    testWidgets(
        "displays right warning when it triggers verificationFailed with 'invalid-phone-number' exception",
        (WidgetTester tester) async {
      verificationFailedTest(
        tester,
        exceptionCode: "invalid-phone-number",
        expectedWarningMessage:
            "Número de telefone inválido. Por favor, tente outro.",
      );
    });

    testWidgets(
        "displays right warning when it triggers verificationFailed with generic exception",
        (WidgetTester tester) async {
      verificationFailedTest(
        tester,
        exceptionCode: "generic",
        expectedWarningMessage:
            "Ops, algo deu errado. Tente novamente mais tarde.",
      );
    });

    testWidgets("removes warning and resets timer when it triggers codeSent",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

      // verifyPhoneNumber triggers codeSent
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "codeSent",
      );

      // set remainingSeconds to 0 so resendCode callback is activated
      insertSmsCodeState.setState(() {
        insertSmsCodeState.remainingSeconds = 0;
      });
      await tester.pump();

      // before tapping the button, warning is null and timer is off
      expect(insertSmsCodeState.warningMessage, isNull);

      // tap to resendCode
      await tester.tap(find.text("Reenviar o código para meu celular"));
      await tester.pumpAndSettle();

      // after tapping the button, warning is null and timer is reset
      expect(insertSmsCodeState.warningMessage, isNull);
      expect(insertSmsCodeState.remainingSeconds, equals(15));
    });
  });
}

void stateIsEnabled(InsertSmsCodeState insertSmsCodeState, String code) {
  // expect code to show up in controller
  expect(insertSmsCodeState.smsCodeTextEditingController.text, equals(code));
  // expect smsCode to equal entered code
  expect(insertSmsCodeState.smsCode, equals(code));
  // expect not null circularButtonCallback
  expect(insertSmsCodeState.circularButtonCallback, isNotNull);
  // expect enabled circularButtonColor
  expect(insertSmsCodeState.circularButtonColor, equals(AppColor.primaryPink));
  // expect autorenew_sharp icon
  expect(find.byIcon(Icons.autorenew_sharp), findsOneWidget);
}

void stateIsDisabled(
  InsertSmsCodeState insertSmsCodeState,
) {
  //expect null smsCode
  expect(insertSmsCodeState.smsCode, isNull);
  // expect null circularButtonCallback
  expect(insertSmsCodeState.circularButtonCallback, isNull);
  // expect disabled circularButtonCollor
  expect(insertSmsCodeState.circularButtonColor, equals(AppColor.disabled));
  // expect autorenew_sharp icon
  expect(find.byIcon(Icons.autorenew_sharp), findsOneWidget);
}
