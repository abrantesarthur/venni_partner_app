import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/screens/insertAdditionalInfo.dart';
import 'package:partner_app/screens/insertName.dart';
import 'package:partner_app/widgets/appInputText.dart';
import 'package:partner_app/widgets/circularButton.dart';
import 'package:provider/provider.dart';
import '../mocks.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: InsertAditionalInfo(
        userCredential: mockUserCredential,
        userEmail: "valid@domain.com",
        name: "Fulano",
        surname: "de Tal",
      ),
    ));
  }

  group("state", () {
    testWidgets("starts inactive", (WidgetTester tester) async {
      // add InsertName widget to the UI
      await pumpWidget(tester);

      // expect focus to start on name input
      final nameInputWidget = tester.firstWidget(find.byType(AppInputText));
      expect(
          nameInputWidget,
          isA<AppInputText>()
              .having((i) => i.hintText, "hintText", "000.000.000-00")
              .having((i) => i.autoFocus, "autoFocus", true));
    });
  });

  group("buttonCallback", () {
    testWidgets("pushes InsertAdditionalInfo when pressed",
        (WidgetTester tester) async {
      // add InsertName widget to the UI
      String userEmail = "valid@domain.com";
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<ConnectivityModel>(
              create: (context) => mockConnectivityModel),
        ],
        child: MaterialApp(
          home: InsertName(
            userCredential: mockUserCredential,
            userEmail: userEmail,
          ),
          navigatorObservers: [mockNavigatorObserver],
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == InsertAditionalInfo.routeName) {
              final InsertAdditionalInfoArguments args = settings.arguments;
              return MaterialPageRoute(builder: (context) {
                return InsertAditionalInfo(
                  userCredential: args.userCredential,
                  userEmail: args.userEmail,
                  surname: args.surname,
                  name: args.name,
                );
              });
            }
            return null;
          },
        ),
      ));

      verify(mockNavigatorObserver.didPush(any, any));

      final nameFinder = find.byType(AppInputText).first;
      final surnameFinder = find.byType(AppInputText).last;

      // insert valid name and valid surname
      String name = "Fulano";
      String surname = "de tal";
      await tester.enterText(surnameFinder, surname);
      await tester.enterText(nameFinder, name);
      await tester.pumpAndSettle();

      // before tapping, we have InsertPassword screen
      expect(find.byType(InsertName), findsOneWidget);
      expect(find.byType(InsertAditionalInfo), findsNothing);

      // tap on CircularButton
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping, we are redirected to InsertAditionalInfo screen
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertName), findsNothing);
      expect(find.byType(InsertAditionalInfo), findsOneWidget);

      // InsertAditionalInfo screen receives correct arguments
      final InsertAditionalInfoState insertAditionalInfoState =
          tester.state(find.byType(InsertAditionalInfo));
      expect(insertAditionalInfoState.widget.userCredential,
          equals(mockUserCredential));
      expect(insertAditionalInfoState.widget.userEmail, equals(userEmail));
      expect(insertAditionalInfoState.widget.name, equals(name));
      expect(insertAditionalInfoState.widget.surname, equals(surname));
    });
  });
}
