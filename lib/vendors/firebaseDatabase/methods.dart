import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/services/firebase/database/interfaces.dart';

// FIXME: move to FirebaseServices
extension AppFirebaseDatabase on FirebaseDatabase {
  Future<PartnerInterface?> getPartnerFromID(String? pilotID) async {
    if (pilotID == null || pilotID.isEmpty) {
      return null;
    }
    DatabaseEvent event =
        await this.ref().child("partners").child(pilotID).once();
    // FIXME: double check that casting as Map is safe
    return PartnerInterface.fromJson(event.snapshot.value as Map);
  }

  Future<void> createPartner(PartnerInterface partner) async {
    if(partner.id == null) {
      throw Exception("Cannot create partner when its id is null");
    }
    await this
        .reference()
        .child("partners")
        .child(partner.id!)
        .set(partner.toJson());
  }

  Future<void> deletePartner(String id) async {
    await this.reference().child("partners").child(id).remove();
  }

  Future<void> setPhoneNumber({
    required String partnerID,
    required String phoneNumber,
  }) async {
    await this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("phone_number")
        .set(phoneNumber);
  }

  Future<void> setSubmittedCnh({
    required partnerID,
    required bool value,
  }) async {
    await this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("submitted_documents")
        .child("cnh")
        .set(value);
  }

  Future<void> setSubmittedCrlv({
    required partnerID,
    required bool value,
  }) async {
    await this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("submitted_documents")
        .child("crlv")
        .set(value);
  }

  Future<void> setSubmittedPhotoWithCnh({
    required partnerID,
    required bool value,
  }) async {
    await this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("submitted_documents")
        .child("photo_with_cnh")
        .set(value);
  }

  Future<void> setSubmittedProfilePhoto({
    required partnerID,
    required bool value,
  }) async {
    await this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("submitted_documents")
        .child("profile_photo")
        .set(value);
  }

  Future<void> setSubmittedBankAccount({
    required partnerID,
    required bool value,
  }) async {
    await this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("submitted_documents")
        .child("bank_account")
        .set(value);
  }

  Future<void> setBankAccount({
    required partnerID,
    required BankAccount bankAccount,
  }) async {
    await this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("bank_account")
        .set(bankAccount.toJson());
  }

  Future<void> setPartnerStatus({
    required partnerID,
    required PartnerStatus partnerStatus,
  }) async {
    await this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("status")
        .set(partnerStatus.getString());
  }

  Future<void> updatePartnerPosition({
    required partnerID,
    required double latitude,
    required double longitude,
  }) async {
    // round latitude and longitude to at most 6 decimal places
    latitude = toFixed(latitude, 6);
    longitude = toFixed(longitude, 6);
    await this.reference().child("partners").child(partnerID).update({
      "current_latitude": latitude.toString(),
      "current_longitude": longitude.toString(),
    });
  }

  // onAccountStatusUpdate subscribes onData to handle changes in the
  // account status of partner with uid partnerID
  StreamSubscription onAccountStatusUpdate(
    String partnerID,
    void Function(DatabaseEvent) onData,
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
    void Function(DatabaseEvent) onData,
  ) {
    return this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("submitted_documents")
        .onValue
        .listen(onData);
  }

  // onPartnerStatusUpdate subscribes onData to handle changes in the status
  // of the partner with uid partnerID
  StreamSubscription onPartnerStatusUpdate(
    String partnerID,
    void Function(DatabaseEvent) onData,
  ) {
    return this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("status")
        .onValue
        .listen(onData);
  }

  StreamSubscription onTripStatusUpdate(
    String clientID,
    void Function(DatabaseEvent) onData,
  ) {
    return this
        .reference()
        .child("trip-requests")
        .child(clientID)
        .child("trip_status")
        .onValue
        .listen(onData);
  }

  StreamSubscription onAccountStatusupdate(
    String partnerID,
    void Function(DatabaseEvent) onData,
  ) {
    return this
        .reference()
        .child("partners")
        .child(partnerID)
        .child("account_status")
        .onValue
        .listen(onData);
  }

  Future<void> setPartnerIsNear(String clientID, bool value) async {
    return await this
        .reference()
        .child("trip-requests")
        .child(clientID)
        .child("partner_is_near")
        .set(value);
  }

  // updateFCMToken updates the user's firebase cloud messaging token so they
  // can receive targeted notifications from the backend
  Future<void> updateFCMToken({required String uid, required String token}) async {
    return await this
        .ref()
        .child("partners")
        .child(uid)
        .update({"fcm_token": token});
  }

  Future<void> submitDeleteReasons({
    required Map<DeleteReason, bool> reasons,
    required String uid,
  }) async {
    // iterate over reasons, adding them to database
    reasons.keys.forEach((key) async {
      String reasonString;

      // if user didn't select this reason, don't add it to database
      if (reasons[key] == false) {
        return;
      }

      switch (key) {
        case DeleteReason.badAppExperience:
          reasonString = "bad-app-experience";
          break;
        case DeleteReason.badTripExperience:
          reasonString = "bad-trip-experience";
          break;
        case DeleteReason.doesntUseService:
          reasonString = "doesnt-use-service";
          break;
        case DeleteReason.hasAnotherAccount:
          reasonString = "has-another-account";
          break;
        case DeleteReason.another:
          reasonString = "something-else";
          break;
      }

      try {
        await this
            .ref()
            .child("partner-delete-reasons")
            .child(reasonString)
            .child(uid)
            .set({
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {}
      return;
    });
  }
}
