import 'package:cloud_functions/cloud_functions.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';

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
        return BankAccount.fromJson(result.data);
      }
    } catch (e) {
      throw e;
    }
    return null;
  }
}
