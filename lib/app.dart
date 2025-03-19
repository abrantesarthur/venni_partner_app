import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/timer.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/screens/anticipate.dart';
import 'package:partner_app/screens/balance.dart';
import 'package:partner_app/screens/bankAccountDetail.dart';
import 'package:partner_app/screens/deleteAccount.dart';
import 'package:partner_app/screens/demand.dart';
import 'package:partner_app/screens/editEmail.dart';
import 'package:partner_app/screens/editPhone.dart';
import 'package:partner_app/screens/help.dart';
import 'package:partner_app/screens/insertNewEmail.dart';
import 'package:partner_app/screens/insertNewPassword.dart';
import 'package:partner_app/screens/insertNewPhone.dart';
import 'package:partner_app/screens/pastTripDetail.dart';
import 'package:partner_app/screens/pastTrips.dart';
import 'package:partner_app/screens/privacy.dart';
import 'package:partner_app/screens/profile.dart';
import 'package:partner_app/screens/rateClient.dart';
import 'package:partner_app/screens/ratings.dart';
import 'package:partner_app/screens/sendBankAccount.dart';
import 'package:partner_app/screens/sendCnh.dart';
import 'package:partner_app/screens/sendCrlv.dart';
import 'package:partner_app/screens/documents.dart';
import 'package:partner_app/screens/home.dart';
import 'package:partner_app/screens/insertAdditionalInfo.dart';
import 'package:partner_app/screens/insertEmail.dart';
import 'package:partner_app/screens/insertName.dart';
import 'package:partner_app/screens/insertPassword.dart';
import 'package:partner_app/screens/insertPhone.dart';
import 'package:partner_app/screens/insertSmsCode.dart';
import 'package:partner_app/screens/sendPhotoWithCnh.dart';
import 'package:partner_app/screens/sendProfilePhoto.dart';
import 'package:partner_app/screens/settings.dart';
import 'package:partner_app/screens/shareLocation.dart';
import 'package:partner_app/screens/splash.dart';
import 'package:partner_app/screens/start.dart';
import 'package:partner_app/screens/transferDetail.dart';
import 'package:partner_app/screens/transfers.dart';
import 'package:partner_app/screens/wallet.dart';
import 'package:partner_app/screens/withdraw.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/services/firebase/database/interfaces.dart';
import 'package:partner_app/services/firebase/firebaseAnalytics.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  // use Future<void>, since we only care about completion, not a result value.
  late Future<void> _initialized;
  late FirebaseService firebase;


  @override
  void initState() {
    _initialized = initialize();
    super.initState();
  }

  @override
  void dispose() {
    firebase.model.googleMaps.dispose();
    super.dispose();
  }


  Future<void> initialize() async {
    firebase = FirebaseService();
    await firebase.initialize();
    await logEvents();

    // throw error if there is no connection, so Start screen can be pushed
    bool hasConnection = await firebase.model.connectivity.checkConnection();
    if (!hasConnection) {
      throw FirebaseAuthException(code: "network-error", message: "No internet connection");
    }
  }

  Future<void> logEvents() async {
    try {
      await Future.wait([
        firebase.analytics.logAppOpen(),
        firebase.analytics.setPartnerUserProperty(),
      ]);
    } catch (_) {
      // Silently handle analytics errors
    }
  }

  // TODO: update code so that it's backend agnostic and replacing the backend is very easy!
  // TODO: move all errors to the same enum
  // TODO: move as much logic as possible to the backend
  // TODO: README How to test locally taking DEV flavor into account. Explain that need to run emulator locally.
  // TODO: Find a way of using xcode flavors so that it's not necessary to manually switch bundle id in xcode when running in dev or prod.
  // TODO: make sure that phone authentication works in android in both development and production mode
  // TODO: add lockScreen variable to all relevant screens
  // TODO: think about callign directions API only in backend
  // TODO: load user position here, instead of home
  // TODO: when deploying the app, register a release certificate fingerprint
  //    in firebase instead of the debug certificate fingerprint
  //    (https://developers.google.com/android/guides/client-auth)
  // TODO: persist authentication state https://firebase.flutter.dev/docs/auth/usage
  // TODO: overflow happens if a "O email já está sendo usado." warning happens
  // TODO:  make sure that user logs out when account is deleted or disactivated in firebase

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialized,
      builder: (
        BuildContext context,
        AsyncSnapshot<void> snapshot,
      ) {
        // Show a loader while app is being initialized
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Splash();
        }

        // Handle errors
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is FirebaseAuthException && 
              error.code == "firebase-initialization-error") {
            print(error);
            return MaterialApp(
              home: Scaffold(
                body: Container(
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      "Algo deu errado\n\nVerifique a sua conexão com a internet e reinicie o app",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: "OpenSans",
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          
          // FIXME: treat other errors
          // Default error handling for other error types
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  "Unknown error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // if no errors, show Home screen or Start screen, depending on whether user is signed in
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<UserModel>(
              create: (context) => firebase.model.user,
            ),
            ChangeNotifierProvider<PartnerModel>(
              create: (context) => firebase.model.partner,
            ),
            ChangeNotifierProvider<ConnectivityModel>(
              create: (context) => firebase.model.connectivity,
            ),
            ChangeNotifierProvider<GoogleMapsModel>(
              create: (context) => firebase.model.googleMaps,
            ),
            ChangeNotifierProvider<TimerModel>(
              create: (context) => firebase.model.timer,
            ),
            ChangeNotifierProvider<TripModel>(
              create: (context) => firebase.model.trip,
            ),
          ],
          builder: (context, child) {
            UserModel user = Provider.of<UserModel>(
              context,
              listen: false,
            );
            PartnerModel partner = Provider.of<PartnerModel>(
              context,
              listen: false,
            );

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(fontFamily: "OpenSans"),
              // push Start screen if user is not registered, his account is not
              // approved, or we failed to download partner data. In this last case
              // it will come a step in which he will be warned to connect to the
              // internet if that's the reason why the download failed. Either way,
              // Home won't be pushed without downloading the data either way later on.
              initialRoute: !user.isUserSignedIn ||
                      partner.accountStatus != AccountStatus.approved ||
                      (snapshot.hasError &&
                          snapshot.error is FirebaseAuthException &&
                          ((snapshot.error as FirebaseAuthException).code == "partner-initialization-error" ||
                           (snapshot.error as FirebaseAuthException).code == "network-error"))
                  ? Start.routeName
                  : Home.routeName,
              // pass appropriate arguments to routes
              onGenerateRoute: (RouteSettings settings) {
                // if Home is pushed
                if (settings.name == Home.routeName) {
                  return MaterialPageRoute(builder: (context) {
                    return Home();
                  });
                }

                // if InsertSmsCode is pushed
                if (settings.name == InsertSmsCode.routeName) {
                  final InsertSmsCodeArguments args = settings.arguments as InsertSmsCodeArguments;
                  return MaterialPageRoute(builder: (context) {
                    return InsertSmsCode(
                      verificationId: args.verificationId,
                      resendToken: args.resendToken,
                      phoneNumber: args.phoneNumber,
                      mode: args.mode,
                    );
                  });
                }

                // if InsertEmail is pushed
                if (settings.name == InsertEmail.routeName) {
                  final InsertEmailArguments args = settings.arguments as InsertEmailArguments;
                  return MaterialPageRoute(builder: (context) {
                    return InsertEmail(
                      userCredential: args.userCredential,
                    );
                  });
                }

                // if InsertName is pushed
                if (settings.name == InsertName.routeName) {
                  final InsertNameArguments args = settings.arguments as InsertNameArguments;
                  return MaterialPageRoute(builder: (context) {
                    return InsertName(
                      userCredential: args.userCredential,
                      userEmail: args.userEmail,
                    );
                  });
                }

                // if InsertAditionalInfo is pushed
                if (settings.name == InsertAditionalInfo.routeName) {
                  final InsertAdditionalInfoArguments args = settings.arguments as InsertAdditionalInfoArguments;
                  return MaterialPageRoute(builder: (context) {
                    return InsertAditionalInfo(
                      userCredential: args.userCredential,
                      userEmail: args.userEmail,
                      name: args.name,
                      surname: args.surname,
                    );
                  });
                }

                // if InsertPassword is pushed
                if (settings.name == InsertPassword.routeName) {
                  final InsertPasswordArguments args = settings.arguments as InsertPasswordArguments;
                  return MaterialPageRoute(builder: (context) {
                    return InsertPassword(
                      userCredential: args.userCredential,
                      userEmail: args.userEmail,
                      name: args.name,
                      surname: args.surname,
                      cpf: args.cpf,
                      gender: args.gender,
                    );
                  });
                }

                // if Documents is pushed
                if (settings.name == Documents.routeName) {
                  final DocumentsArguments args = settings.arguments as DocumentsArguments;
                  return MaterialPageRoute(builder: (context) {
                    return Documents(
                      firebase: args.firebase,
                      partner: args.partner,
                    );
                  });
                }

                // if SendBankAccount is pushed
                if (settings.name == SendBankAccount.routeName) {
                  final SendBankAccountArguments args = settings.arguments as SendBankAccountArguments;
                  return MaterialPageRoute(builder: (context) {
                    return SendBankAccount(mode: args.mode);
                  });
                }

                // if Wallet is pushed
                if (settings.name == Wallet.routeName) {
                  final WalletArguments args = settings.arguments as WalletArguments;
                  return MaterialPageRoute(builder: (context) {
                    return Wallet(
                      firebase: args.firebase,
                      partner: args.partner,
                    );
                  });
                }

                // if Withdraw is pushed
                if (settings.name == Withdraw.routeName) {
                  final WithdrawArguments args = settings.arguments as WithdrawArguments;
                  return MaterialPageRoute(builder: (context) {
                    return Withdraw(
                      availableAmount: args.availableAmount,
                    );
                  });
                }

                // if Anticipate is pushed
                if (settings.name == Anticipate.routeName) {
                  final AnticipateArguments args = settings.arguments as AnticipateArguments;
                  return MaterialPageRoute(builder: (context) {
                    return Anticipate(
                      waitingAmount: args.waitingAmount,
                    );
                  });
                }

                // if ShareLocation is pushed
                if (settings.name == ShareLocation.routeName) {
                  final ShareLocationArguments args = settings.arguments as ShareLocationArguments;
                  return MaterialPageRoute(builder: (context) {
                    return ShareLocation(
                      routeToPush: args.routeToPush,
                      routeArguments: args.routeArguments,
                    );
                  });
                }

                // if Profile is pushed
                if (settings.name == Profile.routeName) {
                  final ProfileArguments args = settings.arguments as ProfileArguments;
                  return MaterialPageRoute(builder: (context) {
                    return Profile(
                      firebase: args.firebase,
                      partner: args.partner,
                    );
                  });
                }

                // if PastTrips is pushed
                if (settings.name == PastTrips.routeName) {
                  return MaterialPageRoute(builder: (context) {
                    return PastTrips();
                  });
                }

                // if Ratings is pushed
                if (settings.name == Ratings.routeName) {
                  return MaterialPageRoute(builder: (context) {
                    return Ratings();
                  });
                }

                // if PastTripDetail is pushed
                if (settings.name == PastTripDetail.routeName) {
                  final PastTripDetailArguments args = settings.arguments as PastTripDetailArguments;
                  return MaterialPageRoute(builder: (context) {
                    return PastTripDetail(
                      firebase: args.firebase,
                      pastTrip: args.pastTrip,
                    );
                  });
                }

                // if TransfersRoute is pushed
                if (settings.name == TransfersRoute.routeName) {
                  final TransfersRouteArguments args = settings.arguments as TransfersRouteArguments;
                  return MaterialPageRoute(builder: (context) {
                    return TransfersRoute(
                      firebase: args.firebase,
                      connectivity: args.connectivity,
                    );
                  });
                }

                // if TransferDetail is pushed
                if (settings.name == TransferDetail.routeName) {
                  final TransferDetailArguments args = settings.arguments as TransferDetailArguments;
                  return MaterialPageRoute(builder: (context) {
                    return TransferDetail(transfer: args.transfer);
                  });
                }

                // if Demand is pushed
                if (settings.name == Demand.routeName) {
                  final DemandArguments args = settings.arguments as DemandArguments;
                  return MaterialPageRoute(builder: (context) {
                    return Demand(firebase: args.firebase);
                  });
                }

                assert(false, 'Need to implement ${settings.name}');
                // Return a valid route instead of null for null safety
                return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Route not found'))));
              },
              routes: {
                Home.routeName: (context) => Home(),
                Start.routeName: (context) => Start(),
                InsertPhone.routeName: (context) => InsertPhone(),
                SendCrlv.routeName: (context) => SendCrlv(),
                SendCnh.routeName: (context) => SendCnh(),
                SendPhotoWithCnh.routeName: (context) => SendPhotoWithCnh(),
                SendProfilePhoto.routeName: (context) => SendProfilePhoto(),
                Settings.routeName: (context) => Settings(),
                EditPhone.routeName: (context) => EditPhone(),
                InsertNewPhone.routeName: (context) => InsertNewPhone(),
                EditEmail.routeName: (context) => EditEmail(),
                InsertNewEmail.routeName: (context) => InsertNewEmail(),
                InsertNewPassword.routeName: (context) => InsertNewPassword(),
                BankAccountDetail.routeName: (context) => BankAccountDetail(),
                Privacy.routeName: (context) => Privacy(),
                DeleteAccount.routeName: (context) => DeleteAccount(),
                RateClient.routeName: (context) => RateClient(),
                Help.routeName: (context) => Help(),
                BalanceRoute.routeName: (context) => BalanceRoute(),
              },
            );
          },
        );
      },
    );
  }
}
