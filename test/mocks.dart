import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:partner_app/models/firebase.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}

class MockFirebaseModel extends Mock implements FirebaseModel {}

class MockDatabaseReference extends Mock implements DatabaseReference {}

class MockDataSnapshot extends Mock implements DataSnapshot {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockPartnerModel extends Mock implements PartnerModel {}

class MockPartnerInterface extends Mock implements PartnerInterface {}

class MockConnectivityModel extends Mock implements ConnectivityModel {}

MockFirebaseModel mockFirebaseModel = MockFirebaseModel();
MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
MockFirebaseDatabase mockFirebaseDatabase = MockFirebaseDatabase();
MockNavigatorObserver mockNavigatorObserver = MockNavigatorObserver();
MockUserCredential mockUserCredential = MockUserCredential();
MockUser mockUser = MockUser();
MockPartnerModel mockPartnerModel = MockPartnerModel();
MockPartnerInterface mockPartnerInterface = MockPartnerInterface();
MockConnectivityModel mockConnectivityModel = MockConnectivityModel();
MockDataSnapshot mockDataSnapshot = MockDataSnapshot();
MockDatabaseReference mockDatabaseReference = MockDatabaseReference();
