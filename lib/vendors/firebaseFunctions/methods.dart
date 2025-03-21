import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/services/firebase/firebase.dart';
import 'package:partner_app/services/firebase/firebaseAnalytics.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:partner_app/services/firebase/database/interfaces.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';

extension AppFirebaseFunctions on FirebaseFunctions {
  Future<BankAccount?> createBankAccount(BankAccount bankAccount) async {
    Map<String, String> data = {
      "bank_code": bankAccount.bankCode,
      "agencia": bankAccount.agencia,
      "conta": bankAccount.conta,
      "type": bankAccount.type.getString(),
      "document_number": bankAccount.documentNumber,
      "legal_name": bankAccount.legalName,
    };
    if (bankAccount.agenciaDv != null && bankAccount.agenciaDv!.isNotEmpty) {
      data["agencia_dv"] = bankAccount.agenciaDv!;
    }
    if (bankAccount.contaDv != null && bankAccount.contaDv!.isNotEmpty) {
      data["conta_dv"] = bankAccount.contaDv!;
    }
    HttpsCallableResult result =
        await this.httpsCallable("payment-create_bank_account").call(data);
    if (result.data != null) {
      return BankAccount.fromJson(result.data);
    }

    return null;
  }

  Future<Balance?> getBalance(String pagarmeRecipientID) async {
    Map<String, String> data = {
      "pagarme_recipient_id": pagarmeRecipientID,
    };
    HttpsCallableResult result =
        await this.httpsCallable("payment-get_balance").call(data);
    if (result.data != null) {
      return Balance.fromJson(result.data);
    }
    return null;
  }

  Future<Transfer?> createTransfer({
    required String amount,
    required String pagarmeRecipientID,
  }) async {
    Map<String, String> data = {
      "pagarme_recipient_id": pagarmeRecipientID,
      "amount": amount,
    };
    HttpsCallableResult result =
        await this.httpsCallable("payment-create_transfer").call(data);
    if (result.data != null) {
      return Transfer.fromJson(result.data);
    }
    return null;
  }

  Future<void> deleteAccount() async {
    await this.httpsCallable("account-delete_partner").call();
  }

  Future<void> connect({
    required double currentLatitude,
    required double currentLongitude,
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

  Future<Trip?> getCurrentTrip() async {
    HttpsCallableResult result =
        await this.httpsCallable("trip-partner_get_current_trip").call();
    if (result.data != null) {
      return Trip.fromJson(result.data);
    }
    return null;
  }

  Future<Trips> getPastTrips({GetPastTripsArguments? args}) async {
    Map<String, int> data = {};
    if (args != null) {
      if (args.pageSize != null) {
        data["page_size"] = args.pageSize!;
      }
      if (args.maxRequestTime != null) {
        data["max_request_time"] = args.maxRequestTime!;
      }
      if (args.minRequestTime != null) {
        data["min_request_time"] = args.minRequestTime!;
      }
    }

    HttpsCallableResult result =
        await this.httpsCallable("trip-partner_get_past_trips").call(data);
    if (result.data != null) {
      return Trips.fromJson(result.data);
    }
    return Trips(items: []);
  }

  Future<void> cancelTrip() async {
    await this.httpsCallable("trip-partner_cancel").call();
  }

  Future<bool> startTrip(BuildContext context) async {
    final firebase = FirebaseService();

    try {
      await this.httpsCallable("trip-start").call();
      // calculate client waiting time and log event
      int clientWaitingTime =
          DateTime.now().millisecondsSinceEpoch - (firebase.model.trip.requestTime ?? 0);
      try {
        firebase.analytics.logPartnerStartTrip(
          clientWaitingTime: clientWaitingTime,
        );
      return true;
      } catch (_) {
        return false;
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> completeTrip({
    required BuildContext context,
    required int clientRating,
  }) async {
    final firebase = FirebaseService();

    Map<String, int> data = {"client_rating": clientRating};
    try {
      await this.httpsCallable("trip-complete").call(data);
      // FIXME: busySince seems weird. It's also initialized with DateTime.now().
      int tripDuration =
          DateTime.now().millisecondsSinceEpoch - firebase.model.partner.busySince;
      try {
        await Future.wait([
          firebase.analytics.logPartnerCompleteTrip(
            tripDuration: tripDuration,
          ),
          firebase.analytics.logPartnerRateClient(clientRating)
        ]);
      } catch (_) {}
    } catch (e) {
      throw e;
    }
  }

  Future<Transfers?> getTransfers(GetTransfersArguments args) async {
    Map<String, dynamic> data = {};
    data["count"] = args.count;
    data["page"] = args.page;
    data["pagarme_recipient_id"] = args.pagarmeRecipientID;
    HttpsCallableResult result =
        await this.httpsCallable("payment-get_transfers").call(data);
    if (result.data != null) {
      return Transfers.fromJson(result.data);
    }

    return null;
  }

  Future<DemandByZone?> getDemandByZone() async {
    HttpsCallableResult result =
        await this.httpsCallable("demand_by_zone-get").call();
    if (result.data != null) {
      return DemandByZone.fromJson(result.data);
    }
    return null;
  }

  Future<ApprovedPartners?> getApprovedPartners() async {
    HttpsCallableResult result =
        await this.httpsCallable("partner-get_approved").call();
    if (result.data != null) {
      return ApprovedPartners.fromJson(result.data);
    }

    return null;
  }
}
