import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/user.dart';
import 'package:partner_app/models/googleMaps.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/models/timer.dart';
import 'package:partner_app/models/trip.dart';
import 'package:partner_app/services/firebase/database/interfaces.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}

class MockFirebaseModel extends Mock implements UserModel {}

class MockDatabaseReference extends Mock implements DatabaseReference {}

class MockDataSnapshot extends Mock implements DataSnapshot {}

class MockEvent extends Mock implements Stream<Event> {}

class MockStreamSubscription extends Mock implements StreamSubscription<Event> {
}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockPartnerModel extends Mock implements PartnerModel {}

class MockTripModel extends Mock implements TripModel {}

class MockGoogleMapsModel extends Mock implements GoogleMapsModel {}

class MockPartnerInterface extends Mock implements PartnerInterface {}

class MockConnectivityModel extends Mock implements ConnectivityModel {}

class MockTimerModel extends Mock implements TimerModel {}

MockFirebaseModel mockFirebaseModel = MockFirebaseModel();
MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
MockFirebaseDatabase mockFirebaseDatabase = MockFirebaseDatabase();
MockNavigatorObserver mockNavigatorObserver = MockNavigatorObserver();
MockUserCredential mockUserCredential = MockUserCredential();
MockUser mockUser = MockUser();
MockPartnerModel mockPartnerModel = MockPartnerModel();
MockTripModel mockTripModel = MockTripModel();
MockGoogleMapsModel mockGoogleMapsModel = MockGoogleMapsModel();
MockTimerModel mockTimerModel = MockTimerModel();
MockPartnerInterface mockPartnerInterface = MockPartnerInterface();
MockConnectivityModel mockConnectivityModel = MockConnectivityModel();
MockDataSnapshot mockDataSnapshot = MockDataSnapshot();
MockDatabaseReference mockDatabaseReference = MockDatabaseReference();
MockEvent mockEvent = MockEvent();
MockStreamSubscription mockStreamSubscription = MockStreamSubscription();

void main() {}
