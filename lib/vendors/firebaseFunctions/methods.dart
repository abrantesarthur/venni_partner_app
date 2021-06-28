import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
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

    try {
      HttpsCallableResult result =
          await this.httpsCallable("payment-create_bank_account").call(data);
      if (result != null && result.data != null) {
        print(result.data);
        return BankAccount.fromJson(result.data);
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<Balance> getBalance(String pagarmeRecipientID) async {
    Map<String, String> data = {
      "pagarme_recipient_id": pagarmeRecipientID,
    };
    try {
      HttpsCallableResult result =
          await this.httpsCallable("payment-get_balance").call(data);
      if (result != null && result.data != null) {
        print(result.data);
        return Balance.fromJson(result.data);
      }
    } catch (e) {
      print(e);
      throw e;
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
    try {
      HttpsCallableResult result =
          await this.httpsCallable("payment-create_transfer").call(data);
      if (result != null && result.data != null) {
        print(result.data);
        return Transfer.fromJson(result.data);
      }
    } catch (e) {
      print(e);
      throw e;
    }
    return null;
  }

  Future<void> deleteAccount() async {
    try {
      await this.httpsCallable("account-delete_partner").call();
    } catch (e) {
      throw e;
    }
  }

  Future<void> connect({
    @required double currentLatitude,
    @required double currentLongitude,
  }) async {
    Map<String, double> data = {
      "current_latitude": currentLatitude,
      "current_longitude": currentLongitude,
    };
    try {
      await this.httpsCallable("partner-connect").call(data);
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<void> disconnect() async {
    try {
      await this.httpsCallable("partner-disconnect").call();
    } catch (e) {
      throw e;
    }
    return null;
  }
}
