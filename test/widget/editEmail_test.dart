import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/screens/editEmail.dart';
import 'package:partner_app/widgets/warning.dart';
import 'package:provider/provider.dart';

import '../mocks.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>(
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
          home: EditEmail(),
        ),
      ),
    );
  }

  testWidgets("display right messages if email is verified", (
    WidgetTester tester,
  ) async {
    // set mocks so email is verified
    when(mockUser.email).thenReturn("test@provider.com");
    when(mockUser.emailVerified).thenReturn(true);

    // add widget to the UI
    await pumpWidget(tester);

    // expect 'Email verificado' text
    final textFinder = find.byType(Text);
    final textWidget = tester.widget(textFinder.at(2));
    expect(textWidget,
        isA<Text>().having((t) => t.data, "data", equals("Email verificado!")));
  });

  testWidgets("displays right messages if email is not verified", (
    WidgetTester tester,
  ) async {
    // set mocks so email is not verified
    when(mockUser.email).thenReturn("test@provider.com");
    when(mockUser.emailVerified).thenReturn(false);

    // add widget to the UI
    await pumpWidget(tester);

    // expect right texts
    final textFinder = find.byType(Text);
    final textWidget = tester.widget(textFinder.at(2));
    expect(
        textWidget,
        isA<Text>().having(
            (t) => t.data,
            "data",
            equals(
              "Seu email ainda não foi verificado. Não recebeu o link de verificação?",
            )));
    // expect right warning
    final warningFinder = find.byType(Warning);
    final warningWidget = tester.widget(warningFinder);
    expect(
        warningWidget,
        isA<Warning>().having(
            (w) => w.message,
            "data",
            equals(
              "Reenviar email de verificação",
            )));
  });

  testWidgets("send email verification correctly", (
    WidgetTester tester,
  ) async {
    // set mocks so email is not verified
    when(mockUser.email).thenReturn("test@provider.com");
    when(mockUser.emailVerified).thenReturn(false);

    // add widget to the UI
    await pumpWidget(tester);

    // before tapping to send email, codeSent is false and no 'email enviado' is displayed
    EditEmailState editEmailState = tester.state(find.byType(EditEmail));
    final textFinder = find.byType(Text);
    expect(editEmailState.codeSent, isFalse);
    expect(
        tester.widget(textFinder.at(2)),
        isA<Text>().having(
            (t) => t.data,
            "data",
            equals(
              "Seu email ainda não foi verificado. Não recebeu o link de verificação?",
            )));

    // tap to send email verificatoin
    final warningFinder = find.byType(Warning);
    await tester.tap(warningFinder);
    await tester.pumpAndSettle();

    // expect code sent to be true and 'email enviado' to be true
    expect(editEmailState.codeSent, isTrue);
    expect(
        tester.widget(textFinder.at(2)),
        isA<Text>().having(
            (t) => t.data,
            "data",
            equals(
              "Email enviado. Cheque o seu email.",
            )));
  });

  testWidgets("show warning if fail to send email verification", (
    WidgetTester tester,
  ) async {
    // set mocks so email is not verified and sending email fails
    when(mockUser.email).thenReturn("test@provider.com");
    when(mockUser.emailVerified).thenReturn(false);
    when(mockUser.sendEmailVerification()).thenAnswer((_) {
      throw FirebaseAuthException(message: "message", code: "code");
    });

    // add widget to the UI
    await pumpWidget(tester);

    // before tapping to send email, codeSent is false and no 'email enviado' is displayed
    EditEmailState editEmailState = tester.state(find.byType(EditEmail));
    final textFinder = find.byType(Text);
    expect(editEmailState.codeSent, isFalse);
    expect(
        tester.widget(textFinder.at(2)),
        isA<Text>().having(
            (t) => t.data,
            "data",
            equals(
              "Seu email ainda não foi verificado. Não recebeu o link de verificação?",
            )));

    // tap to send email verificatoin
    final warningFinder = find.byType(Warning);
    await tester.tap(warningFinder);
    await tester.pumpAndSettle();

    // expect code sent to be false and warning message
    expect(editEmailState.codeSent, isFalse);
    final warningWidget = tester.widget(warningFinder);
    expect(
        warningWidget,
        isA<Warning>().having(
            (w) => w.message,
            "data",
            equals(
              "Falha ao enviar email. Altere o email ou tente novamente mais tarde.",
            )));
  });
}
