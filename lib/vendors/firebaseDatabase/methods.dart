import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';

extension AppFirebaseDatabase on FirebaseDatabase {
  Future<PartnerInterface> getPilotFromID(String pilotID) async {
    try {
      DataSnapshot snapshot =
          await this.reference().child("partners").child(pilotID).once();
      print(snapshot.value);
      return PartnerInterface.fromJson(snapshot.value);
    } catch (_) {}
    return null;
  }

  // TODO: test this
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

  Future<void> setSubmittedBankInfo({
    @required partnerID,
    @required bool value,
  }) async {
    try {
      await this
          .reference()
          .child("partners")
          .child(partnerID)
          .child("submitted_documents")
          .child("bank_info")
          .set(value);
    } catch (e) {
      throw e;
    }
  }
}
