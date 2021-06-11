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
