import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/config/config.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/screens/splash.dart';
import 'package:partner_app/screens/start.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _initialized = false;
  bool _error = false;
  FirebaseModel firebaseModel;
  ConnectivityModel connectivity;
  // GoogleMapsModel googleMaps;
  FirebaseAuth firebaseAuth;
  FirebaseDatabase firebaseDatabase;
  FirebaseStorage firebaseStorage;
  FirebaseFunctions firebaseFunctions;

  @override
  void initState() {
    initializeApp();
    super.initState();
  }

  // @override
  // void dispose() {
  //   if (googleMaps != null) {
  //     googleMaps.dispose();
  //   }
  //   super.dispose();
  // }

  Future<void> initializeApp() async {
    // TODO: load user info or think about how to store in device (like credit card, photo, trip-request etc)
    // TODO: decide whether to set firebase.database.setPersistenceEnabled(true)
    await initializeFlutterFire();
  }

  // Define an async function to initialize FlutterFire
  Future<void> initializeFlutterFire() async {
    try {
      /*
        By default, initializeApp references the FirebaseOptions object that
        read the configuration from GoogleService-Info.plist on iOS and
        google-services.json on Android. Which such files we end up picking
        depends on which value we pass to the --flavor flag of futter run 
        reference: https://firebase.google.com/docs/projects/multiprojects */
      if (Firebase.apps.length == 0) {
        await Firebase.initializeApp();
      }

      // // insantiate authentication, database, and storage
      firebaseAuth = FirebaseAuth.instance;
      firebaseDatabase = FirebaseDatabase.instance;
      firebaseStorage = FirebaseStorage.instance;
      firebaseFunctions = FirebaseFunctions.instance;

      // check if cloud functions are being emulated locally
      if (AppConfig.env.values.emulateCloudFunctions) {
        firebaseFunctions.useFunctionsEmulator(
            origin: AppConfig.env.values.cloudFunctionsBaseURL);
      }

      // set default authentication language as brazilian portuguese
      await firebaseAuth.setLanguageCode("pt_br");

      setState(() {
        _initialized = true;
        _error = false;
      });
    } catch (e) {
      print(e);
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  // TODO: README How to test locally taking DEV flavor into account. Explain that need to run emulator locally.
  // TODO: Find a way of using xcode flavors so that it's not necessary to manually switch bundle id in xcode when running in dev or prod.
  // TODO: make sure that phone authentication works in android in both development and production mode
  // TODO: add lockScreen variable to all relevant screens
  // TODO: get google api key from the environment in AppDelegate.swift
  // TODO: think about callign directions API only in backend
  // TODO: load user position here, instead of home
  // TODO: make sure client cannot write to database (cloud functions do that)
  // TODO: change the database rules to not allow anyone to edit it
  // TODO: when deploying the app, register a release certificate fingerprint
  //    in firebase instead of the debug certificate fingerprint
  //    (https://developers.google.com/android/guides/client-auth)
  // TODO: persist authentication state https://firebase.flutter.dev/docs/auth/usage
  // TODO: change navigation transitions
  // TODO: do integration testing
  // TODO: review entire user registration flow
  // TODO: overflow happens if a "O email já está sendo usado." warning happens
  // TODO:  make sure that user logs out when account is deleted or disactivated in firebase
  // TODO: decide on which logos to use
  // TODO: implement prod flavor https://medium.com/@animeshjain/build-flavors-in-flutter-android-and-ios-with-different-firebase-projects-per-flavor-27c5c5dac10b

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return MaterialApp(
        home: Scaffold(
          body: Container(
            color: Colors.white,
            child: Center(
              child: Text(
                "Algo deu errado :/\nReinicie o App.",
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

    // Show a loader until FlutterFire is initialized
    if (_initialized) {
      // initialize firebaseModel. This will add a listener for user changes.
      firebaseModel = FirebaseModel(
        firebaseAuth: firebaseAuth,
        firebaseDatabase: firebaseDatabase,
        firebaseStorage: firebaseStorage,
        firebaseFunctions: firebaseFunctions,
      );

      // // initialize models
      // tripModel = TripModel();
      // user = UserModel();
      // googleMaps = GoogleMapsModel();
      // pilot = PilotModel();
      connectivity = ConnectivityModel();
    } else {
      return Splash();
    }

    // if everything is setup, show Home screen or Start screen, depending
    // on whether user is signed in
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
            create: (context) => firebaseModel,
          ),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => connectivity,
          ),
        ], // pass user model down
        builder: (context, child) {
          FirebaseModel firebase = Provider.of<FirebaseModel>(
            context,
            listen: false,
          );

          return MaterialApp(
            theme: ThemeData(fontFamily: "OpenSans"),
            // start screen depends on whether user is registered
            initialRoute:
                firebase.isRegistered ? Start.routeName : Start.routeName,
            // pass appropriate arguments to routes
            onGenerateRoute: (RouteSettings settings) {
              // if Home is pushed
              // if (settings.name == Home.routeName) {
              //   final HomeArguments args = settings.arguments;
              //   return MaterialPageRoute(builder: (context) {
              //     return Home(
              //       firebase: args.firebase,
              //       trip: args.trip,
              //       user: args.user,
              //       googleMaps: args.googleMaps,
              //       connectivity: args.connectivity,
              //     );
              //   });
              // }

              assert(false, 'Need to implement ${settings.name}');
              return null;
            },
            routes: {
              // Home.routeName: (context) => Home(
              //       firebase: firebaseModel,
              //       trip: tripModel,
              //       user: user,
              //       googleMaps: googleMaps,
              //       connectivity: connectivity,
              //     ),
              Start.routeName: (context) => Start(),
            },
          );
        });
  }
}
