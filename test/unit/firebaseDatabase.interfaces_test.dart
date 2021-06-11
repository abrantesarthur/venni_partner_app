import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';

void main() {
  group("PartnerStatus", () {
    test("fromString with null string", () {
      PartnerStatus ps = PartnerStatusExtension.fromString(null);
      expect(ps, isNull);
    });

    test("fromString with empty string", () {
      PartnerStatus ps = PartnerStatusExtension.fromString("");
      expect(ps, isNull);
    });

    test("fromString with valid string", () {
      PartnerStatus ps = PartnerStatusExtension.fromString("available");
      expect(ps, equals(PartnerStatus.available));
      ps = PartnerStatusExtension.fromString("unavailable");
      expect(ps, equals(PartnerStatus.unavailable));
      ps = PartnerStatusExtension.fromString("busy");
      expect(ps, equals(PartnerStatus.busy));
      ps = PartnerStatusExtension.fromString("requested");
      expect(ps, equals(PartnerStatus.requested));
    });

    test("getString", () {
      PartnerStatus ps = PartnerStatus.available;
      expect(ps.getString(), equals("available"));
      ps = PartnerStatus.unavailable;
      expect(ps.getString(), equals("unavailable"));
      ps = PartnerStatus.busy;
      expect(ps.getString(), equals("busy"));
      ps = PartnerStatus.requested;
      expect(ps.getString(), equals("requested"));
    });
  });

  group("AccountStatus", () {
    test("fromString with null string", () {
      AccountStatus acs = AccountStatusExtension.fromString(null);
      expect(acs, isNull);
    });

    test("fromString with empty string", () {
      AccountStatus acs = AccountStatusExtension.fromString("");
      expect(acs, isNull);
    });

    test("fromString with valid string", () {
      AccountStatus acs =
          AccountStatusExtension.fromString("pending_documents");
      expect(acs, equals(AccountStatus.pendingDocuments));
      acs = AccountStatusExtension.fromString("pending_approval");
      expect(acs, equals(AccountStatus.pendingApproval));
      acs = AccountStatusExtension.fromString("granted_interview");
      expect(acs, equals(AccountStatus.grantedInterview));
      acs = AccountStatusExtension.fromString("approved");
      expect(acs, equals(AccountStatus.approved));
      acs = AccountStatusExtension.fromString("denied_approval");
      expect(acs, equals(AccountStatus.deniedApproval));
      acs = AccountStatusExtension.fromString("locked");
      expect(acs, equals(AccountStatus.locked));
    });

    test("getString", () {
      AccountStatus acs = AccountStatus.pendingApproval;
      expect(acs.getString(), equals("pending_approval"));
      acs = AccountStatus.pendingDocuments;
      expect(acs.getString(), equals("pending_documents"));
      acs = AccountStatus.grantedInterview;
      expect(acs.getString(), equals("granted_interview"));
      acs = AccountStatus.approved;
      expect(acs.getString(), equals("approved"));
      acs = AccountStatus.deniedApproval;
      expect(acs.getString(), equals("denied_approval"));
      acs = AccountStatus.locked;
      expect(acs.getString(), equals("locked"));
    });
  });

  group("Vehicle", () {
    test("fromJson with null json", () {
      Vehicle v = Vehicle.fromJson(null);
      expect(v, isNull);
    });

    test("fromJson with empty json", () {
      Vehicle v = Vehicle.fromJson({});
      expect(v, isNotNull);
      expect(v.brand, isNull);
      expect(v.year, isNull);
      expect(v.model, isNull);
      expect(v.plate, isNull);
    });
    test("fromJson with valid json", () {
      Vehicle v = Vehicle.fromJson({
        "brand": "brand",
        "year": 2020,
        "model": "model",
        "plate": "plate",
      });
      expect(v, isNotNull);
      expect(v.brand, equals("brand"));
      expect(v.year, equals(2020));
      expect(v.model, equals("model"));
      expect(v.plate, equals("plate"));
    });
  });

  group("Gender", () {
    test("fromString with null string", () {
      Gender g = GenderExtension.fromString(null);
      expect(g, isNull);
    });

    test("fromString with empty string", () {
      Gender g = GenderExtension.fromString("");
      expect(g, isNull);
    });

    test("fromString with valid string", () {
      Gender g = GenderExtension.fromString("masculino");
      expect(g, equals(Gender.masculino));
      g = GenderExtension.fromString("feminino");
      expect(g, equals(Gender.feminino));
      g = GenderExtension.fromString("outro");
      expect(g, equals(Gender.outro));
    });

    test("getString", () {
      Gender g = Gender.masculino;
      expect(g.getString(), equals("masculino"));
      g = Gender.feminino;
      expect(g.getString(), equals("feminino"));
      g = Gender.outro;
      expect(g.getString(), equals("outro"));
    });
  });

  group("SubmittedDocuments", () {
    test("fromJson with null json", () {
      SubmittedDocuments sd = SubmittedDocuments.fromJson(null);
      expect(sd, isNull);
    });

    test("fromJson with empty json", () {
      SubmittedDocuments sd = SubmittedDocuments.fromJson({});
      expect(sd, isNotNull);
      expect(sd.cnh, isFalse);
      expect(sd.crlv, isFalse);
      expect(sd.photoWithCnh, isFalse);
      expect(sd.profilePhoto, isFalse);
      expect(sd.bankAccount, isFalse);
    });
    test("fromJson with valid json", () {
      SubmittedDocuments sd = SubmittedDocuments.fromJson({
        "cnh": true,
        "crlv": true,
        "photo_with_cnh": true,
        "profile_photo": true,
        "bank_account": true,
      });
      expect(sd, isNotNull);
      expect(sd.cnh, isTrue);
      expect(sd.crlv, isTrue);
      expect(sd.photoWithCnh, isTrue);
      expect(sd.profilePhoto, isTrue);
      expect(sd.bankAccount, isTrue);
    });
  });

  group("Banks", () {
    test("getCode", () {
      Banks b = Banks.BancoDoBrasil;
      expect(b.getCode(), equals("001"));
      b = Banks.Santander;
      expect(b.getCode(), equals("033"));
      b = Banks.Caixa;
      expect(b.getCode(), equals("104"));
      b = Banks.Bradesco;
      expect(b.getCode(), equals("237"));
      b = Banks.Itau;
      expect(b.getCode(), equals("341"));
      b = Banks.Hsbc;
      expect(b.getCode(), equals("399"));
    });
  });

  group("BankAccountType", () {
    test("fromString with null string", () {
      BankAccountType bat = BankAccountTypeExtension.fromString(null);
      expect(bat, isNull);
    });

    test("fromString with empty string", () {
      BankAccountType bat = BankAccountTypeExtension.fromString("");
      expect(bat, isNull);
    });

    test("fromString with valid string", () {
      BankAccountType bat =
          BankAccountTypeExtension.fromString("conta_corrente");
      expect(bat, equals(BankAccountType.conta_corrente));
      bat = BankAccountTypeExtension.fromString("conta_poupanca");
      expect(bat, equals(BankAccountType.conta_poupanca));
      bat = BankAccountTypeExtension.fromString("conta_corrente_conjunta");
      expect(bat, equals(BankAccountType.conta_corrente_conjunta));
      bat = BankAccountTypeExtension.fromString("conta_poupanca_conjunta");
      expect(bat, equals(BankAccountType.conta_poupanca_conjunta));
    });

    test("getString", () {
      BankAccountType bat = BankAccountType.conta_corrente;
      expect(bat.getString(), equals("mascuconta_correntelino"));
      bat = BankAccountType.conta_poupanca;
      expect(bat.getString(), equals("conta_poupanca"));
      bat = BankAccountType.conta_corrente_conjunta;
      expect(bat.getString(), equals("conta_corrente_conjunta"));
      bat = BankAccountType.conta_poupanca_conjunta;
      expect(bat.getString(), equals("conta_poupanca_conjunta"));
    });
  });

  group("PartnerInterface", () {
    test("fromJson with null json", () {
      PartnerInterface pi = PartnerInterface.fromJson(null);
      expect(pi, isNull);
    });

    test("fromJson with emtpy json", () {
      PartnerInterface pi = PartnerInterface.fromJson({});
      expect(pi, isNotNull);
      expect(pi.id, isNull);
      expect(pi.name, isNull);
      expect(pi.lastName, isNull);
      expect(pi.cpf, isNull);
      expect(pi.gender, isNull);
      expect(pi.memberSince, isNull);
      expect(pi.phoneNumber, isNull);
      expect(pi.rating, isNull);
      expect(pi.totalTrips, isNull);
      expect(pi.pagarmeReceiverID, isNull);
      expect(pi.partnerStatus, isNull);
      expect(pi.accountStatus, isNull);
      expect(pi.denialReason, isNull);
      expect(pi.lockReason, isNull);
      expect(pi.currentClientID, isNull);
      expect(pi.currentLatitude, isNull);
      expect(pi.currentLongitude, isNull);
      expect(pi.currentZone, isNull);
      expect(pi.idleSince, isNull);
      expect(pi.vehicle, isNull);
      expect(pi.submittedDocuments, isNull);
      expect(pi.bankAccount, isNull);
    });

    test("fromJson with regular json", () {
      String now = "111111111111";
      PartnerInterface pi = PartnerInterface.fromJson({
        "uid": "id",
        "name": "name",
        "last_name": "last_name",
        "cpf": "cpf",
        "gender": "masculino",
        "member_since": now,
        "phone_number": "+5538999999999",
        "rating": "5.0",
        "total_trips": "100",
        "pagarme_receiver_id": "pagarme_receiver_id",
        "partner_status": "available",
        "account_status": "pending_documents",
        "denial_reason": "denial_reason",
        "current_client_id": "current_client_id",
        "current_latitude": "11.1111",
        "current_longitude": "22.2222",
        "current_zone": "AA",
        "idle_since": now,
        "vehicle": {
          "brand": "honda",
          "year": 2020,
          "model": "CG150",
          "plate": "AAA0000"
        },
        "submitted_documents": {
          "cnh": true,
          "crlv": true,
          "photo_with_cnh": true,
          "profile_photo": true,
          "bank_account": true,
        },
        "bank_account": {
          "bank_code": "000",
          "agency": "0000",
          "agency_dv": "0",
          "account": "00000",
          "account_dv": "0",
          "type": "conta_corrente",
          "legal_name": "Fulano de Tal",
        }
      });

      expect(pi.id, equals("id"));
      expect(pi.name, equals("name"));
      expect(pi.lastName, equals("last_name"));
      expect(pi.cpf, equals("cpf"));
      expect(pi.gender, equals(Gender.masculino));
      expect(pi.memberSince, equals(int.parse(now)));
      expect(pi.phoneNumber, equals("+5538999999999"));
      expect(pi.rating, equals(5.0));
      expect(pi.totalTrips, equals(100));
      expect(pi.pagarmeReceiverID, equals("pagarme_receiver_id"));
      expect(pi.partnerStatus, equals(PartnerStatus.available));
      expect(pi.accountStatus, equals(AccountStatus.pendingDocuments));
      expect(pi.denialReason, equals("denial_reason"));
      expect(pi.currentClientID, equals("current_client_id"));
      expect(pi.currentLatitude, equals(11.1111));
      expect(pi.currentLongitude, equals(22.2222));
      expect(pi.currentZone, equals("AA"));
      expect(pi.idleSince, equals(111111111111));
      expect(pi.vehicle.brand, equals("honda"));
      expect(pi.vehicle.year, equals(2020));
      expect(pi.vehicle.model, equals("CG150"));
      expect(pi.vehicle.plate, equals("AAA0000"));
      expect(pi.submittedDocuments.cnh, equals(true));
      expect(pi.submittedDocuments.crlv, equals(true));
      expect(pi.submittedDocuments.photoWithCnh, equals(true));
      expect(pi.submittedDocuments.profilePhoto, equals(true));
      expect(pi.submittedDocuments.bankAccount, equals(true));
      expect(pi.bankAccount.bankCode, equals("000"));
      expect(pi.bankAccount.agency, equals("0000"));
      expect(pi.bankAccount.agencyDv, equals("0"));
      expect(pi.bankAccount.account, equals("00000"));
      expect(pi.bankAccount.accountDv, equals("0"));
      expect(pi.bankAccount.type, equals(BankAccountType.conta_corrente));
      expect(pi.bankAccount.legalName, equals("Fulano de Tal"));
    });
  });
}
// test gender, partner_status, account_status. Everything else really
