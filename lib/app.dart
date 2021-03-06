import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/config/config.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
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
import 'package:partner_app/screens/insertAditionalInfo.dart';
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
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseAnalytics.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  FirebaseModel firebaseModel;
  PartnerModel partnerModel;
  ConnectivityModel connectivity;
  GoogleMapsModel googleMaps;
  TimerModel timer;
  TripModel trip;
  FirebaseAuth firebaseAuth;
  FirebaseDatabase firebaseDatabase;
  FirebaseStorage firebaseStorage;
  FirebaseFunctions firebaseFunctions;
  FirebaseMessaging firebaseMessaging;
  FirebaseAnalytics firebaseAnalytics;
  Future<void> initializationFinished;

  @override
  void initState() {
    initializationFinished = initializeApp();
    super.initState();
  }

  @override
  void dispose() {
    if (googleMaps != null) {
      googleMaps.dispose();
    }
    super.dispose();
  }

  Future<void> initializeApp() async {
    try {
      await initializeFlutterFire();
    } catch (e) {
      print(e);
      throw FirebaseAuthException(code: "firebase-initialization-error");
    }
    initializeModels();
    await logEvents();

    // throw error if there is no connection, so Start screen can be pushed
    bool hasConnection = await connectivity.checkConnection();
    if (!hasConnection) {
      throw FirebaseAuthException(code: "network-error");
    }

    // download partner data so we can know their 'account_status' and decide
    // whether to push Home or Start
    try {
      await initializePartner();
    } catch (e) {
      throw FirebaseAuthException(code: "partner-initialization-error");
    }
  }

  // Define an async function to initialize FlutterFire
  Future<void> initializeFlutterFire() async {
    // TODO: decide whether to set firebase.database.setPersistenceEnabled(true)

    /*
        By default, initializeApp references the FirebaseOptions object that
        read the configuration from GoogleService-Info.plist on iOS and
        google-services.json on Android. Which such files we end up picking
        depends on which value we pass to the --flavor flag of futter run 
        reference: https://firebase.google.com/docs/projects/multiprojects */
    if (Firebase.apps.length == 0) {
      await Firebase.initializeApp();
    }

    // insantiate authentication, database, and storage
    firebaseAuth = FirebaseAuth.instance;
    firebaseDatabase = FirebaseDatabase.instance;
    firebaseStorage = FirebaseStorage.instance;
    firebaseFunctions = FirebaseFunctions.instance;
    firebaseMessaging = FirebaseMessaging.instance;
    firebaseAnalytics = FirebaseAnalytics();

    // check if cloud functions are being emulated locally
    if (AppConfig.env.values.emulateCloudFunctions) {
      firebaseFunctions.useFunctionsEmulator(
        origin: AppConfig.env.values.cloudFunctionsBaseURL,
      );
    }

    // set default authentication language as brazilian portuguese
    await firebaseAuth.setLanguageCode("pt_br");
  }

  void initializeModels() {
    // initialize firebaseModel. This will add a listener for user changes.
    firebaseModel = FirebaseModel(
      firebaseAuth: firebaseAuth,
      firebaseDatabase: firebaseDatabase,
      firebaseStorage: firebaseStorage,
      firebaseFunctions: firebaseFunctions,
      firebaseMessaging: firebaseMessaging,
      firebaseAnalytics: firebaseAnalytics,
    );

    // initialize models
    partnerModel = PartnerModel();
    googleMaps = GoogleMapsModel();
    connectivity = ConnectivityModel();
    timer = TimerModel();
    trip = TripModel();
  }

  Future<void> logEvents() async {
    try {
      await Future.wait([
        firebaseAnalytics.logAppOpen(),
        firebaseAnalytics.setPartnerUserProperty(),
      ]);
    } catch (_) {}
  }

  Future<void> initializePartner() async {
    // download partner data
    await partnerModel.downloadData(firebaseModel, notify: false);
    // if partner has active trip request, download it as well
    if (partnerModel.partnerStatus == PartnerStatus.busy) {
      await trip.downloadData(firebaseModel, notify: false);
    }
  }

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
  // TODO: overflow happens if a "O email j?? est?? sendo usado." warning happens
  // TODO:  make sure that user logs out when account is deleted or disactivated in firebase

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializationFinished,
      builder: (
        BuildContext context,
        AsyncSnapshot<void> snapshot,
      ) {
        // Show a loader while app is being initialized
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Splash();
        }

        FirebaseAuthException error = snapshot.error;
        if (snapshot.hasError &&
            error.code == "firebase-initialization-error") {
          print(error);
          return MaterialApp(
            home: Scaffold(
              body: Container(
                color: Colors.white,
                child: Center(
                  child: Text(
                    "Algo deu errado\n\nVerifique a sua conex??o com a internet e reinicie o app",
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

        // if everything is setup, show Home screen or Start screen, depending
        // on whether user is signed in
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<FirebaseModel>(
              create: (context) => firebaseModel,
            ),
            ChangeNotifierProvider<PartnerModel>(
              create: (context) => partnerModel,
            ),
            ChangeNotifierProvider<ConnectivityModel>(
              create: (context) => connectivity,
            ),
            ChangeNotifierProvider<GoogleMapsModel>(
              create: (context) => googleMaps,
            ),
            ChangeNotifierProvider<TimerModel>(
              create: (context) => timer,
            ),
            ChangeNotifierProvider<TripModel>(
              create: (context) => trip,
            ),
          ], // pass user model down
          builder: (context, child) {
            FirebaseModel firebase = Provider.of<FirebaseModel>(
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
              // internet if that's the reason why the download failed. Moreover,
              // Home won't be pushed without downloading the data either way later on.
              initialRoute: !firebase.isRegistered ||
                      partner.accountStatus != AccountStatus.approved ||
                      (snapshot.hasError &&
                          (error.code == "partner-initialization-error" ||
                              error.code == "network-error"))
                  ? Start.routeName
                  : Home.routeName,
              // pass appropriate arguments to routes
              onGenerateRoute: (RouteSettings settings) {
                // if Home is pushed
                if (settings.name == Home.routeName) {
                  final HomeArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return Home(
                      firebase: args.firebase,
                      partner: args.partner,
                      googleMaps: args.googleMaps,
                      timer: args.timer,
                      trip: args.trip,
                      connectivity: args.connectivity,
                    );
                  });
                }

                // if InsertSmsCode is pushed
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

                // if InsertEmail is pushed
                if (settings.name == InsertEmail.routeName) {
                  final InsertEmailArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return InsertEmail(
                      userCredential: args.userCredential,
                    );
                  });
                }

                // if InsertName is pushed
                if (settings.name == InsertName.routeName) {
                  final InsertNameArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return InsertName(
                      userCredential: args.userCredential,
                      userEmail: args.userEmail,
                    );
                  });
                }

                // if InsertAditionalInfo is pushed
                if (settings.name == InsertAditionalInfo.routeName) {
                  final InsertAditionalInfoArguments args = settings.arguments;
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
                  final InsertPasswordArguments args = settings.arguments;
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
                  final DocumentsArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return Documents(
                      firebase: args.firebase,
                      partner: args.partner,
                    );
                  });
                }

                // if SendBankAccount is pushed
                if (settings.name == SendBankAccount.routeName) {
                  final SendBankAccountArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return SendBankAccount(mode: args.mode);
                  });
                }

                // if Wallet is pushed
                if (settings.name == Wallet.routeName) {
                  final WalletArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return Wallet(
                      firebase: args.firebase,
                      partner: args.partner,
                    );
                  });
                }

                // if Withdraw is pushed
                if (settings.name == Withdraw.routeName) {
                  final WithdrawArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return Withdraw(
                      availableAmount: args.availableAmount,
                    );
                  });
                }

                // if Anticipate is pushed
                if (settings.name == Anticipate.routeName) {
                  final AnticipateArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return Anticipate(
                      waitingAmount: args.waitingAmount,
                    );
                  });
                }

                // if ShareLocation is pushed
                if (settings.name == ShareLocation.routeName) {
                  final ShareLocationArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return ShareLocation(
                      routeToPush: args.routeToPush,
                      routeArguments: args.routeArguments,
                    );
                  });
                }

                // if Profile is pushed
                if (settings.name == Profile.routeName) {
                  final ProfileArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return Profile(
                      firebase: args.firebase,
                      partner: args.partner,
                    );
                  });
                }

                // if PastTrips is pushed
                if (settings.name == PastTrips.routeName) {
                  final PastTripsArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return PastTrips(
                      firebase: args.firebase,
                      connectivity: args.connectivity,
                    );
                  });
                }

                // if Ratings is pushed
                if (settings.name == Ratings.routeName) {
                  final RatingsArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return Ratings(
                      firebase: args.firebase,
                      connectivity: args.connectivity,
                      partner: args.partner,
                    );
                  });
                }

                // if PastTripDetail is pushed
                if (settings.name == PastTripDetail.routeName) {
                  final PastTripDetailArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return PastTripDetail(
                      firebase: args.firebase,
                      pastTrip: args.pastTrip,
                    );
                  });
                }

                // if TransfersRoute is pushed
                if (settings.name == TransfersRoute.routeName) {
                  final TransfersRouteArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return TransfersRoute(
                      firebase: args.firebase,
                      connectivity: args.connectivity,
                    );
                  });
                }

                // if TransferDetail is pushed
                if (settings.name == TransferDetail.routeName) {
                  final TransferDetailArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return TransferDetail(transfer: args.transfer);
                  });
                }

                // if Demand is pushed
                if (settings.name == Demand.routeName) {
                  final DemandArguments args = settings.arguments;
                  return MaterialPageRoute(builder: (context) {
                    return Demand(firebase: args.firebase);
                  });
                }

                assert(false, 'Need to implement ${settings.name}');
                return null;
              },
              routes: {
                Home.routeName: (context) => Home(
                    firebase: firebaseModel,
                    partner: partnerModel,
                    googleMaps: googleMaps,
                    timer: timer,
                    trip: trip,
                    connectivity: connectivity),
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
