import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';

extension AppFirebaseFunctions on FirebaseFunctions {
  Future<BankAccount> createBankAccount(BankAccount bankAccount) async {
    Map<String, String> data = {
      "bank_code": bankAccount.bankCode,
      "agency": bankAccount.agency,
      "account": bankAccount.account,
      "account_dv": bankAccount.accountDv,
      "type": bankAccount.type.getString(),
      "document_number": bankAccount.documentNumber,
      "legal_name": bankAccount.legalName,
    };
    if (bankAccount.agencyDv != null && bankAccount.agencyDv.isNotEmpty) {
      data["agency_dv"] = bankAccount.agencyDv;
    }
    HttpsCallableResult result =
        await this.httpsCallable("payment-create_bank_account").call(data);
    if (result != null && result.data != null) {
      return BankAccount.fromJson(result.data);
    }

    return null;
  }

  Future<Balance> getBalance(String pagarmeRecipientID) async {
    Map<String, String> data = {
      "pagarme_recipient_id": pagarmeRecipientID,
    };
    HttpsCallableResult result =
        await this.httpsCallable("payment-get_balance").call(data);
    if (result != null && result.data != null) {
      return Balance.fromJson(result.data);
    }
    return null;
  }

  Future<Transfer> createTransfer({
    @required String amount,
    @required String pagarmeRecipientID,
  }) async {
    Map<String, String> data = {
      "pagarme_recipient_id": pagarmeRecipientID,
      "amount": amount,
    };
    HttpsCallableResult result =
        await this.httpsCallable("payment-create_transfer").call(data);
    if (result != null && result.data != null) {
      return Transfer.fromJson(result.data);
    }
    return null;
  }

  Future<void> deleteAccount() async {
    await this.httpsCallable("account-delete_partner").call();
  }

  Future<void> connect({
    @required double currentLatitude,
    @required double currentLongitude,
  }) async {
    Map<String, double> data = {
      "current_latitude": toFixed(currentLatitude, 6),
      "current_longitude": toFixed(currentLongitude, 6),
    };
    await this.httpsCallable("partner-connect").call(data);
  }

  Future<void> disconnect() async {
    await this.httpsCallable("partner-disconnect").call();
  }

  Future<void> acceptTrip() async {
    await this.httpsCallable("trip-accept").call();
  }

  Future<Trip> getCurrentTrip() async {
    HttpsCallableResult result =
        await this.httpsCallable("trip-partner_get_current_trip").call();
    if (result != null && result.data != null) {
      return Trip.fromJson(result.data);
    }
    return null;
  }

  Future<Trips> getPastTrips({GetPastTripsArguments args}) async {
    Map<String, int> data = {};
    if (args != null) {
      if (args.pageSize != null) {
        data["page_size"] = args.pageSize;
      }
      if (args.maxRequestTime != null) {
        data["max_request_time"] = args.maxRequestTime;
      }
      if (args.minRequestTime != null) {
        data["min_request_time"] = args.minRequestTime;
      }
    }

    HttpsCallableResult result =
        await this.httpsCallable("trip-partner_get_past_trips").call(data);
    if (result != null && result.data != null) {
      return Trips.fromJson(result.data);
    }
    return null;
  }

  Future<void> cancelTrip() async {
    await this.httpsCallable("trip-partner_cancel").call();
  }

  Future<void> startTrip() async {
    await this.httpsCallable("trip-start").call();
  }

  Future<void> completeTrip(int clientRating) async {
    Map<String, int> data = {"client_rating": clientRating};
    await this.httpsCallable("trip-complete").call(data);
  }
}
