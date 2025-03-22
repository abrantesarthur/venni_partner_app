import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/screens/insertEmail.dart';
import 'package:partner_app/screens/insertName.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';
import '../mocks.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockUserModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
  });

  group("state ", () {
    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserModel>(
                create: (context) => mockUserModel)
          ],
          builder: (context, child) => MaterialApp(
            initialRoute: InsertEmail.routeName,
            routes: {
              InsertEmail.routeName: (context) =>
                  InsertEmail(userCredential: mockUserCredential),
            },
          ),
        ),
      );
    }

    testWidgets("inits as desactivated", (WidgetTester tester) async {
      // add InsertEmail widget to the UI
      await pumpWidget(tester);

      // expect disabled state
      final insertEmailState =
          tester.state(find.byType(InsertEmail)) as InsertEmailState;
      expect(insertEmailState.circularButtonCallback, isNull);
      expect(insertEmailState.circularButtonColor, AppColor.disabled);
      // expect autoFocus
      final inputText = tester.firstWidget(find.byType(AppInputText));
      expect(inputText,
          isA<AppInputText>().having((i) => i.autoFocus, "autoFocus", isTrue));
    });

    testWidgets("is desactivated when user types invalid email",
        (WidgetTester tester) async {
      // add InsertEmail widget to the UI
      await pumpWidget(tester);

      // user types invalid email
      await tester.enterText(find.byType(AppInputText), "test@domain");
      await tester.pumpAndSettle();

      // expect disabled state
      final insertEmailState =
          tester.state(find.byType(InsertEmail)) as InsertEmailState;
      expect(insertEmailState.circularButtonCallback, isNull);
      expect(insertEmailState.circularButtonColor, AppColor.disabled);
    });

    testWidgets("is activated when user types valid email",
        (WidgetTester tester) async {
      // add InsertEmail widget to the UI
      await pumpWidget(tester);

      // user types invalid email
      await tester.enterText(find.byType(AppInputText), "test@domain.com");
      await tester.pumpAndSettle();

      // expect disabled state
      final insertEmailState =
          tester.state(find.byType(InsertEmail)) as InsertEmailState;
      expect(insertEmailState.circularButtonCallback, isNotNull);
      expect(insertEmailState.circularButtonColor, AppColor.primaryPink);
    });
  });

  group("buttonCallback ", () {
    Future<void> pumpWidget(
      WidgetTester tester,
      String phoneNumber,
    ) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>(
              create: (context) => mockUserModel)
        ],
        child: MaterialApp(
          home: InsertEmail(
            userCredential: mockUserCredential,
          ),
          onGenerateRoute: (RouteSettings settings) {
            final InsertNameArguments args = settings.arguments as InsertNameArguments;
            return MaterialPageRoute(builder: (context) {
              return InsertName(
                userCredential: args.userCredential,
                userEmail: args.userEmail,
              );
            });
          },
          navigatorObservers: [mockNavigatorObserver],
        ),
      ));
    }

    testWidgets("pushes InsertName route when email is available",
        (WidgetTester tester) async {
      // add InsertEmail widget to the UI
      String phoneNumber = "+55 (38) 99999 9999";
      await pumpWidget(tester, phoneNumber);

      verify(mockNavigatorObserver.didPush(any, any));

      // when trying to loggin, receive 'user-not-found', meaning email is available
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: "user-not-found",
      );
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed("email"),
        password: anyNamed("password"),
      )).thenAnswer((_) => throw e);

      // type valid email
      String userEmail = "valid@domain.com";
      await tester.enterText(find.byType(AppInputText), userEmail);
      await tester.pumpAndSettle();

      // expect valid state
      final insertEmailState =
          tester.state(find.byType(InsertEmail)) as InsertEmailState;
      expect(insertEmailState.circularButtonCallback, isNotNull);
      expect(insertEmailState.circularButtonColor, AppColor.primaryPink);

      // before tapping button we are still in InsertEmail route
      expect(find.byType(InsertEmail), findsOneWidget);
      expect(find.byType(InsertName), findsNothing);

      // tap circularButton
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // expect InsertName to be pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertEmail), findsNothing);
      expect(find.byType(InsertName), findsOneWidget);

      // expect InsertName route to have received right arguments
      final insertNameState =
          tester.state(find.byType(InsertName)) as InsertNameState;
      expect(insertNameState.widget.userCredential, equals(mockUserCredential));
      expect(insertNameState.widget.userEmail, equals(userEmail));
    });

    testWidgets("displays right warning when email is unavailable",
        (WidgetTester tester) async {
      // add InsertEmail widget to the UI
      String phoneNumber = "+55 (38) 99999 9999";
      await pumpWidget(tester, phoneNumber);

      verify(mockNavigatorObserver.didPush(any, any));

      // when trying to loggin, receive 'wrong-password', meaning email is unavailable
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: "wrong-password",
      );
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed("email"),
        password: anyNamed("password"),
      )).thenAnswer((_) => throw e);

      // type valid email
      String userEmail = "valid@domain.com";
      await tester.enterText(find.byType(AppInputText), userEmail);
      await tester.pumpAndSettle();

      // expect valid state
      final insertEmailState =
          tester.state(find.byType(InsertEmail)) as InsertEmailState;
      expect(insertEmailState.circularButtonCallback, isNotNull);
      expect(insertEmailState.circularButtonColor, AppColor.primaryPink);

      // before tapping button, there is no warning
      expect(
          find.widgetWithText(
            Warning,
            "O email já está sendo usado. Tente outro.",
          ),
          findsNothing);

      // tap circularButton
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // expect to receive a warning
      expect(
          find.widgetWithText(
            Warning,
            "O email já está sendo usado. Tente outro.",
          ),
          findsOneWidget);
    });

    testWidgets("displays right warning when email is unavailable II",
        (WidgetTester tester) async {
      // add InsertEmail widget to the UI
      String phoneNumber = "+55 (38) 99999 9999";
      await pumpWidget(tester, phoneNumber);

      verify(mockNavigatorObserver.didPush(any, any));

      // when trying to loggin, succeed
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed("email"),
        password: anyNamed("password"),
      )).thenAnswer((_) async => Future.value(mockUserCredential));

      // type an email the frontend interprets as valid
      String userEmail = "valid@domain.com";
      await tester.enterText(find.byType(AppInputText), userEmail);
      await tester.pumpAndSettle();

      // expect valid state
      final insertEmailState =
          tester.state(find.byType(InsertEmail)) as InsertEmailState;
      expect(insertEmailState.circularButtonCallback, isNotNull);
      expect(insertEmailState.circularButtonColor, AppColor.primaryPink);

      // before tapping button, there is no warning
      expect(
          find.widgetWithText(
            Warning,
            "O email já está sendo usado. Tente outro.",
          ),
          findsNothing);

      // tap circularButton
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // expect to receive a warning
      expect(
          find.widgetWithText(
            Warning,
            "O email já está sendo usado. Tente outro.",
          ),
          findsOneWidget);
    });

    testWidgets("displays right warning when firebase detects invalid email",
        (WidgetTester tester) async {
      // add InsertEmail widget to the UI
      String phoneNumber = "+55 (38) 99999 9999";
      await pumpWidget(tester, phoneNumber);

      verify(mockNavigatorObserver.didPush(any, any));

      // when trying to loggin, receive 'invalid-email'
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: "invalid-email",
      );
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed("email"),
        password: anyNamed("password"),
      )).thenAnswer((_) => throw e);

      // type an email the frontend interprets as valid
      String userEmail = "valid@domain.com";
      await tester.enterText(find.byType(AppInputText), userEmail);
      await tester.pumpAndSettle();

      // expect valid state
      final insertEmailState =
          tester.state(find.byType(InsertEmail)) as InsertEmailState;
      expect(insertEmailState.circularButtonCallback, isNotNull);
      expect(insertEmailState.circularButtonColor, AppColor.primaryPink);

      // before tapping button, there is no warning
      expect(
          find.widgetWithText(
            Warning,
            "Email inválido. Tente outro.",
          ),
          findsNothing);

      // tap circularButton
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // expect to receive a warning
      expect(
          find.widgetWithText(
            Warning,
            "Email inválido. Tente outro.",
          ),
          findsOneWidget);
    });

    testWidgets(
        "displays right warning when email can't be used for other reasons",
        (WidgetTester tester) async {
      // add InsertEmail widget to the UI
      String phoneNumber = "+55 (38) 99999 9999";
      await pumpWidget(tester, phoneNumber);

      verify(mockNavigatorObserver.didPush(any, any));

      // when trying to loggin, receive 'invalid-email'
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: "any-other-code",
      );
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed("email"),
        password: anyNamed("password"),
      )).thenAnswer((_) => throw e);

      // type an email the frontend interprets as valid
      String userEmail = "valid@domain.com";
      await tester.enterText(find.byType(AppInputText), userEmail);
      await tester.pumpAndSettle();

      // expect valid state
      final insertEmailState =
          tester.state(find.byType(InsertEmail)) as InsertEmailState;
      expect(insertEmailState.circularButtonCallback, isNotNull);
      expect(insertEmailState.circularButtonColor, AppColor.primaryPink);

      // before tapping button, there is no warning
      expect(
          find.widgetWithText(
            Warning,
            "O email não pode ser usado. Tente outro.",
          ),
          findsNothing);

      // tap circularButton
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // expect to receive a warning
      expect(
          find.widgetWithText(
            Warning,
            "O email não pode ser usado. Tente outro.",
          ),
          findsOneWidget);
    });
  });
}
