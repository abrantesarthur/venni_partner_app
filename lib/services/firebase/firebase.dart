import 'package:partner_app/config/config.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart' show FirebaseDatabase;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart' show UserModel;
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/timer.dart';
import 'package:partner_app/models/trip.dart';

// FIXME: move to its own package
class FirebaseModel {
  late FirebaseService firebase;
  late UserModel user;
  late PartnerModel partner;
  late GoogleMapsModel googleMaps;
  late ConnectivityModel connectivity;
  late TimerModel timer;
  late TripModel trip;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;


  FirebaseModel(this.firebase);

  // FIXME: does this need to be a Future? Check if UserModel, etc. need to be initialized
  Future<void> initialize() async {
    user = UserModel(this.firebase);
    partner = PartnerModel(this.firebase);
    // download partner data so we can know their 'account_status' and decide
    // whether to push Home or Start
    try {
      await partner.initialize();
    } catch(e) {
      throw FirebaseAuthException(code: "partner-initialization-error", message: e.toString());
    }
    googleMaps = GoogleMapsModel(this.firebase);
    connectivity = ConnectivityModel(this.firebase);
    await connectivity.initialize();
    timer = TimerModel();
    trip = TripModel(this.firebase);
    await trip.initialize();
    _isInitialized = true;
  }
}

class FirebaseService {
  // Firebase services
  late FirebaseAuth auth;
  late FirebaseDatabase database;
  late FirebaseStorage storage;
  late FirebaseFunctions functions;
  late FirebaseMessaging messaging;
  late FirebaseAnalytics analytics;
  late FirebaseModel model;


  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;


  // Singleton pattern (there is a single FirebaseService shared throughout the app)
  FirebaseService._internal();
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  Future<void> initialize() async {
    try {
      await _initializeServices();
    } catch(e) {
      // FIXME: move all error codes to the same file and enum
      throw FirebaseAuthException(code: "firebase-initialization-error", message: e.toString());
    }

    await _initializeModels();

    
    // mark initialization as finished
    _isInitialized = true;
  }

  Future<void> _initializeModels() async {
    model = FirebaseModel(this);
    await model.initialize();
  }


  Future<void> _initializeServices() async {
    // TODO: decide whether to set firebase.database.setPersistenceEnabled(true)
    /*
      By default, Firebase.initializeApp references the FirebaseOptions object
      that read the configuration from GoogleService-Info.plist on iOS and
      google-services.json on Android. Which of these files we end up picking
      depends on which value we pass to the --flavor flag of 'futter run'

      reference: https://firebase.google.com/docs/projects/multiprojects
    */
    if(Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // get firebase service instances
    auth = FirebaseAuth.instance;
    database = FirebaseDatabase.instance;
    storage = FirebaseStorage.instance;
    functions = FirebaseFunctions.instance;
    messaging = FirebaseMessaging.instance;
    analytics = FirebaseAnalytics.instance;


    // check if cloud functions are being emulated locally
    if (AppConfig.env.values.emulateCloudFunctions) {
      functions.useFunctionsEmulator(
        AppConfig.env.values.cloudFunctionsBaseURL,
        AppConfig.env.values.cloudFunctionsPort,
      );
    }

    // set default authentication language as brazilian portuguese
    await auth.setLanguageCode("pt_br");
  }

}