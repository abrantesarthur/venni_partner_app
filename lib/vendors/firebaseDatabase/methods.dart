import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';

extension AppFirebaseDatabase on FirebaseDatabase {
  Future<PartnerInterface> getPartnerFromID(String pilotID) async {
    try {
      DataSnapshot snapshot =
          await this.reference().child("partners").child(pilotID).once();
      return PartnerInterface.fromJson(snapshot.value);
    } catch (e) {
      throw (e);
    }
  }

  Future<void> createPartner(PartnerInterface partner) async {
    try {
      await this
          .reference()
          .child("partners")
          .child(partner.id)
          .set(partner.toJson());
    } catch (e) {
      throw e;
    }
  }

  Future<void> deletePartner(String id) async {
    try {
      await this.reference().child("partners").child(id).remove();
    } catch (e) {
      throw e;
    }
  }

  Future<void> setSubmittedCnh({
    @required partnerID,
    @required bool value,
  }) async {
    try {
      await this
          .reference()
          .child("partners")
          .child(partnerID)
          .child("submitted_documents")
          .child("cnh")
          .set(value);
    } catch (e) {
      throw e;
    }
  }

  Future<void> setSubmittedCrlv({
    @required partnerID,
    @required bool value,
  }) async {
    try {
      await this
          .reference()
          .child("partners")
          .child(partnerID)
          .child("submitted_documents")
          .child("crlv")
          .set(value);
    } catch (e) {
      throw e;
    }
  }

  Future<void> setSubmittedPhotoWithCnh({
    @required partnerID,
    @required bool value,
  }) async {
    try {
      await this
          .reference()
          .child("partners")
          .child(partnerID)
          .child("submitted_documents")
          .child("photo_with_cnh")
          .set(value);
    } catch (e) {
      throw e;
    }
  }

  Future<void> setSubmittedProfilePhoto({
    @required partnerID,
    @required bool value,
  }) async {
    try {
      await this
          .reference()
          .child("partners")
          .child(partnerID)
          .child("submitted_documents")
          .child("profile_photo")
          .set(value);
    } catch (e) {
      throw e;
    }
  }

  Future<void> setSubmittedBankAccount({
    @required partnerID,
    @required bool value,
  }) async {
    try {
      await this
          .reference()
          .child("partners")
          .child(partnerID)
          .child("submitted_documents")
          .child("bank_account")
          .set(value);
    } catch (e) {
      throw e;
    }
  }

  Future<void> setBankAccount({
    @required partnerID,
    @required BankAccount bankAccount,
  }) async {
    try {
      await this
          .reference()
          .child("partners")
          .child(partnerID)
          .child("bank_account")
          .set(bankAccount.toJson());
    } catch (e) {
      throw e;
    }
  }

  // onAccountStatusUpdate subscribes onData to handle changes in the
  // account status of partner with uid partnerID
  StreamSubscription onAccountStatusUpdate(
    String partnerID,
    void Function(Event) onData,
  ) {
    return this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("account_status")
        .onValue
        .listen(onData);
  }

  // onAccountStatusUpdate subscribes onData to handle changes in the
  // account status of partner with uid partnerID
  StreamSubscription onSubmittedDocumentsUpdate(
    String partnerID,
    void Function(Event) onData,
  ) {
    return this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("submitted_documents")
        .onValue
        .listen(onData);
  }
}
