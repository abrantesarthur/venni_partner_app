import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/editPhone.dart';
import 'package:partner_app/screens/insertNewPhone.dart';
import 'package:partner_app/screens/insertSmsCode.dart';
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
  testWidgets("phone is succesfully edited", (WidgetTester tester) async {
    // set mocks. phone number starts as +5538999999999
    String oldNumber = "+5538888888888";
    String newNumber = "+5538999999999";
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.phoneNumber).thenReturn(oldNumber);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
    when(mockUser.updatePhoneNumber(any)).thenAnswer((_) {
      // update phone number to +5538999999999
      when(mockUser.phoneNumber).thenReturn(newNumber);
      return Future.value();
    });

    // add EditPhone to the UI
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<PartnerModel>(
              create: (context) => mockPartnerModel),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => mockConnectivityModel,
          )
        ],
        builder: (context, child) => MaterialApp(
          home: EditPhone(),
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
          routes: {
            InsertNewPhone.routeName: (context) => InsertNewPhone(),
          },
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );

    // verify that EditPhone was pushed
    final editPhoneFinder = find.byType(EditPhone);
    final insertNewPhoneFinder = find.byType(InsertNewPhone);
    final insertSmsCodeFinder = find.byType(InsertSmsCode);
    verify(mockNavigatorObserver.didPush(any, any));
    expect(insertNewPhoneFinder, findsNothing);
    expect(editPhoneFinder, findsOneWidget);
    expect(insertSmsCodeFinder, findsNothing);

    // verify that old number is displayed
    final textFinder = find.byType(Text);
    final textWidget = tester.firstWidget(textFinder.at(1));
    expect(
        textWidget,
        isA<Text>().having(
            (t) => t.data,
            "data",
            equals(
              oldNumber.withoutCountryCode(),
            )));

    // tap on Atualizar Telefone
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    // verify that InsertNewPhone was pushed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(insertNewPhoneFinder, findsOneWidget);
    expect(editPhoneFinder, findsNothing);

    InsertNewPhoneState insertNewPhoneState =
        tester.state(find.byType(InsertNewPhone));

    // codeSentCallback is called when verifyPhone is triggered
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
      {
        insertNewPhoneState.codeSentCallback(
          insertNewPhoneState.context,
          "verificationId123",
          123,
        );
      }
    });

    // insert new phone number to InputPhone
    await tester.enterText(find.byType(InputPhone), newNumber.substring(3));
    await tester.pumpAndSettle();

    // tap Redefinir Button
    final appButtonFinder = find.byType(AppButton);
    expect(appButtonFinder, findsOneWidget);
    await tester.tap(appButtonFinder);
    await tester.pumpAndSettle();

    // verify that InsertSmsCode was pushed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(insertSmsCodeFinder, findsOneWidget);
    expect(insertNewPhoneFinder, findsNothing);
    expect(editPhoneFinder, findsNothing);

    // insert valid sms code
    await tester.enterText(find.byType(AppInputText), "123456");
    await tester.pump();

    // tap button
    await tester.tap(find.byType(CircularButton));
    await tester.pumpAndSettle();

    // verify that we navigated back
    verify(mockNavigatorObserver.didPop(any, any));
    expect(insertSmsCodeFinder, findsNothing);
    expect(insertNewPhoneFinder, findsOneWidget);
    expect(editPhoneFinder, findsNothing);

    // expect success message
    final warningFinder = find.byType(Warning);
    expect(warningFinder, findsOneWidget);
    final warningWidget = tester.firstWidget(warningFinder);
    expect(
        warningWidget,
        isA<Warning>().having(
            (w) => w.message,
            "message",
            contains("Número alterado com sucesso para " +
                newNumber.withoutCountryCode())));

    // navigate back once more
    await tester.tap(find.byType(ArrowBackButton));
    await tester.pumpAndSettle();

    // verify that we navigated back
    verify(mockNavigatorObserver.didPop(any, any));
    expect(insertSmsCodeFinder, findsNothing);
    expect(insertNewPhoneFinder, findsNothing);
    expect(editPhoneFinder, findsOneWidget);

    // expect phone text to be successfully updated
    EditPhoneState editPhoneState = tester.state(find.byType(EditPhone));
    FirebaseModel firebase =
        Provider.of<FirebaseModel>(editPhoneState.context, listen: false);
    expect(firebase.auth.currentUser.phoneNumber.withoutCountryCode(),
        equals("(38) 99999-9999"));
  });
}
