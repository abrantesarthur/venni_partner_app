import 'package:flutter/material.dart';

enum PartnerStatus {
  unavailable,
  available,
  busy,
  requested,
}

extension PartnerStatusExtension on PartnerStatus {
  static PartnerStatus fromString(String s) {
    if (s == null) {
      return null;
    }
    switch (s) {
      case "unavailable":
        return PartnerStatus.unavailable;
      case "available":
        return PartnerStatus.available;
      case "busy":
        return PartnerStatus.busy;
      case "requested":
        return PartnerStatus.requested;
      default:
        return null;
    }
  }

  String getString() {
    return this.toString().substring(14);
  }
}

enum AccountStatus {
  pendingDocuments,
  pendingReview,
  grantedInterview,
  approved,
  deniedApproval,
  locked,
}

extension AccountStatusExtension on AccountStatus {
  static AccountStatus fromString(String s) {
    if (s == null) {
      return null;
    }
    switch (s) {
      case "pending_documents":
        return AccountStatus.pendingDocuments;
      case "pending_review":
        return AccountStatus.pendingReview;
      case "granted_interview":
        return AccountStatus.grantedInterview;
      case "approved":
        return AccountStatus.approved;
      case "denied_approval":
        return AccountStatus.deniedApproval;
      case "locked":
        return AccountStatus.locked;
      default:
        return null;
    }
  }

  String getString() {
    switch (this) {
      case AccountStatus.pendingDocuments:
        return "pending_documents";
      case AccountStatus.pendingReview:
        return "pending_review";
      case AccountStatus.grantedInterview:
        return "granted_interview";
      case AccountStatus.approved:
        return "approved";
      case AccountStatus.deniedApproval:
        return "denied_approval";
      case AccountStatus.locked:
        return "locked";
      default:
        return "";
    }
  }
}

class Vehicle {
  String brand;
  String model;
  int year;
  String plate;

  Vehicle({
    @required this.brand,
    @required this.model,
    @required this.year,
    @required this.plate,
  });

  factory Vehicle.fromJson(Map<dynamic, dynamic> json) {
    return json != null
        ? Vehicle(
            brand: json["brand"],
            model: json["model"],
            year: json["year"],
            plate: json["plate"])
        : null;
  }
}

enum Gender { masculino, feminino, outro }

extension GenderExtension on Gender {
  static Gender fromString(String s) {
    if (s == null) {
      return null;
    }
    switch (s) {
      case "masculino":
        return Gender.masculino;
      case "feminino":
        return Gender.feminino;
      case "outro":
        return Gender.outro;
      default:
        return null;
    }
  }

  String getString() {
    return this.toString().substring(7);
  }
}

class SubmittedDocuments {
  final bool cnh;
  final bool crlv;
  final bool photoWithCnh;
  final bool profilePhoto;
  final bool bankAccount;

  SubmittedDocuments({
    @required this.cnh,
    @required this.crlv,
    @required this.photoWithCnh,
    @required this.profilePhoto,
    @required this.bankAccount,
  });

  factory SubmittedDocuments.fromJson(Map json) {
    return json == null
        ? null
        : SubmittedDocuments(
            cnh: json["cnh"] == null ? false : json["cnh"],
            crlv: json["crlv"] == null ? false : json["crlv"],
            photoWithCnh:
                json["photo_with_cnh"] == null ? false : json["photo_with_cnh"],
            profilePhoto:
                json["profile_photo"] == null ? false : json["profile_photo"],
            bankAccount:
                json["bank_account"] == null ? false : json["bank_account"],
          );
  }
}

enum Banks {
  BancoDoBrasil,
  Santander,
  Caixa,
  Bradesco,
  Itau,
  Hsbc,
}

extension BanksExtension on Banks {
  String getCode() {
    return bankTypeToNameMap[this].substring(0, 3);
  }
}

Map<String, String> bankCodeToNameMap = {
  "001": "001 - Banco do Brasil",
  "033": "033 - Santander",
  "104": "104 - Caixa",
  "237": "237 - Bradesco",
  "341": "341 - Itaú",
  "399": "399 - HSBC",
};

Map<Banks, String> bankTypeToNameMap = {
  Banks.BancoDoBrasil: "001 - Banco do Brasil",
  Banks.Santander: "033 - Santander",
  Banks.Caixa: "104 - Caixa",
  Banks.Bradesco: "237 - Bradesco",
  Banks.Itau: "341 - Itaú",
  Banks.Hsbc: "399 - HSBC",
};

enum BankAccountType {
  conta_corrente,
  conta_poupanca,
  conta_corrente_conjunta,
  conta_poupanca_conjunta,
}

extension BankAccountTypeExtension on BankAccountType {
  String getString({bool format}) {
    if (format != null && format) {
      switch (this) {
        case BankAccountType.conta_corrente:
          return "corrente";
        case BankAccountType.conta_poupanca:
          return "poupança";
        case BankAccountType.conta_corrente_conjunta:
          return "corrente conjunta";
        case BankAccountType.conta_poupanca_conjunta:
          return "poupança conjunta";
        default:
          return "";
      }
    } else {
      return this.toString().substring(16);
    }
  }

  static BankAccountType fromString(String s) {
    switch (s) {
      case "conta_corrente":
        return BankAccountType.conta_corrente;
      case "conta_poupanca":
        return BankAccountType.conta_poupanca;
      case "conta_corrente_conjunta":
        return BankAccountType.conta_corrente_conjunta;
      case "conta_poupanca_conjunta":
        return BankAccountType.conta_poupanca_conjunta;
      default:
        return null;
    }
  }
}

Map<BankAccountType, String> accountTypeMap = {
  BankAccountType.conta_corrente: "Corrente",
  BankAccountType.conta_poupanca: "Poupança",
  BankAccountType.conta_corrente_conjunta: "Corrente Conjunta",
  BankAccountType.conta_poupanca_conjunta: "Poupança Conjunta",
};

class BankAccount {
  final int id;
  final String bankCode; // 3 chars max, all numbers
  final String agency; // 4 chars max, all numbers
  final String agencyDv; // optional
  final String account;
  final String accountDv;
  final BankAccountType type;
  final String documentNumber;
  final String legalName;

  BankAccount({
    this.id,
    @required this.bankCode,
    @required this.agency,
    this.agencyDv,
    @required this.account,
    @required this.accountDv,
    @required this.type,
    @required this.documentNumber,
    @required this.legalName,
  });

  factory BankAccount.fromJson(Map json) {
    return json == null
        ? null
        : BankAccount(
            id: json["id"],
            bankCode: json["bank_code"],
            agency: json["agency"],
            agencyDv: json["agency_dv"],
            account: json["account"],
            accountDv: json["account_dv"],
            type: BankAccountTypeExtension.fromString(json["type"]),
            documentNumber: json["document_number"],
            legalName: json["legal_name"],
          );
  }

  Map<String, String> toJson() {
    Map<String, String> map = {};
    if (this.bankCode != null) {
      map["bank_code"] = this.bankCode;
    }
    if (this.agency != null) {
      map["agency"] = this.agency;
    }
    if (this.agencyDv != null) {
      map["agency_dv"] = this.agencyDv;
    }
    if (this.account != null) {
      map["account"] = this.account;
    }
    if (this.accountDv != null) {
      map["account_dv"] = this.accountDv;
    }
    if (this.type != null) {
      map["type"] = this.type.getString();
    }
    if (this.documentNumber != null) {
      map["document_number"] = this.documentNumber;
    }
    if (this.legalName != null) {
      map["legal_name"] = this.legalName;
    }
    return map;
  }
}

class PartnerInterface {
  final String id;
  final String name;
  final String lastName;
  final String cpf;
  final Gender gender;
  final int memberSince;
  final String phoneNumber;
  final double rating;
  final int totalTrips;
  final String pagarmeRecipientID;
  final PartnerStatus partnerStatus;
  final AccountStatus accountStatus;
  final String denialReason;
  final String lockReason;
  final String currentClientID;
  final num currentLatitude;
  final num currentLongitude;
  final String currentZone;
  final num idleSince;
  final Vehicle vehicle;
  final SubmittedDocuments submittedDocuments;
  final BankAccount bankAccount;
  final int amountOwed;

  PartnerInterface({
    @required this.id,
    @required this.name,
    @required this.lastName,
    @required this.cpf,
    @required this.gender,
    @required this.memberSince,
    @required this.phoneNumber,
    @required this.rating,
    @required this.totalTrips,
    @required this.pagarmeRecipientID,
    @required this.partnerStatus,
    @required this.accountStatus,
    @required this.denialReason,
    @required this.lockReason,
    @required this.currentClientID,
    @required this.currentLatitude,
    @required this.currentLongitude,
    @required this.currentZone,
    @required this.idleSince,
    @required this.vehicle,
    @required this.submittedDocuments,
    @required this.bankAccount,
    @required this.amountOwed,
  });

  factory PartnerInterface.fromJson(Map json) {
    if (json == null) {
      return null;
    }

    int memberSince =
        json["member_since"] != null ? int.parse(json["member_since"]) : null;
    double rating =
        json["rating"] != null ? double.parse(json["rating"]) : null;
    int totalTrips =
        json["total_trips"] != null ? int.parse(json["total_trips"]) : null;
    num currentLatitude = json["current_latitude"] == null
        ? null
        : double.parse(json["current_latitude"]);
    num currentLongitude = json["current_longitude"] == null
        ? null
        : double.parse(json["current_longitude"]);
    num idleSince =
        json["idle_since"] == null ? null : int.parse(json["idle_since"]);
    SubmittedDocuments submittedDocuments =
        SubmittedDocuments.fromJson(json["submitted_documents"]);
    BankAccount bankAccount = BankAccount.fromJson(json["bank_account"]);

    return PartnerInterface(
      id: json["uid"],
      name: json["name"],
      lastName: json["last_name"],
      cpf: json["cpf"],
      gender: GenderExtension.fromString(json["gender"]),
      memberSince: memberSince,
      phoneNumber: json["phone_number"],
      rating: rating,
      totalTrips: totalTrips,
      pagarmeRecipientID: json["pagarme_recipient_id"],
      partnerStatus: PartnerStatusExtension.fromString(json["status"]),
      accountStatus: AccountStatusExtension.fromString(json["account_status"]),
      denialReason: json["denial_reason"],
      lockReason: json["lock_reason"],
      currentClientID: json["current_client_uid"],
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
      currentZone: json["current_zone"],
      idleSince: idleSince,
      vehicle: Vehicle.fromJson(json["vehicle"]),
      submittedDocuments: submittedDocuments,
      bankAccount: bankAccount,
      amountOwed: json["amount_owed"],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (this.id != null) {
      json["uid"] = this.id;
    }
    if (this.name != null) {
      json["name"] = this.name;
    }
    if (this.lastName != null) {
      json["last_name"] = this.lastName;
    }
    if (this.cpf != null) {
      json["cpf"] = this.cpf;
    }
    if (this.gender != null) {
      json["gender"] = this.gender.getString();
    }
    if (this.memberSince != null) {
      json["member_since"] = this.memberSince.toString();
    }
    if (this.phoneNumber != null) {
      json["phone_number"] = this.phoneNumber;
    }
    if (this.rating != null) {
      json["rating"] = this.rating.toString();
    }
    if (this.totalTrips != null) {
      json["total_trips"] = this.totalTrips.toString();
    }
    if (this.pagarmeRecipientID != null) {
      json["pagarme_recipient_id"] = this.pagarmeRecipientID;
    }
    if (this.partnerStatus != null) {
      json["status"] = this.partnerStatus.getString();
    }
    if (this.accountStatus != null) {
      json["account_status"] = this.accountStatus.getString();
    }
    if (this.denialReason != null) {
      json["denial_reason"] = this.denialReason;
    }
    if (this.lockReason != null) {
      json["lock_reason"] = this.lockReason;
    }
    if (this.currentClientID != null) {
      json["current_client_uid"] = this.currentClientID;
    }
    if (this.currentLatitude != null) {
      json["current_latitude"] = this.currentLatitude.toString();
    }
    if (this.currentLongitude != null) {
      json["current_longitude"] = this.currentLongitude.toString();
    }
    if (this.currentZone != null) {
      json["current_zone"] = this.currentZone;
    }
    if (this.idleSince != null) {
      json["idleSince"] = this.idleSince.toString();
    }
    if (this.vehicle != null) {
      json["vehicle"] = {
        "brand": this.vehicle.brand,
        "model": this.vehicle.model,
        "year": this.vehicle.year,
        "plate": this.vehicle.plate,
      };
    }
    if (this.submittedDocuments != null) {
      json["submitted_documents"] = {
        "cnh": this.submittedDocuments.cnh == null
            ? false
            : this.submittedDocuments.cnh,
        "crlv": this.submittedDocuments.crlv == null
            ? false
            : this.submittedDocuments.crlv,
        "photo_with_cnh": this.submittedDocuments.photoWithCnh == null
            ? false
            : this.submittedDocuments.photoWithCnh,
        "profile_photo": this.submittedDocuments.profilePhoto == null
            ? false
            : this.submittedDocuments.profilePhoto,
        "bank_account": this.submittedDocuments.bankAccount == null
            ? false
            : this.submittedDocuments.profilePhoto,
      };
    }
    if (this.bankAccount != null) {
      json["bank_account"] = {
        "bank_code": this.bankAccount.bankCode,
        "agency": this.bankAccount.agency,
        "agency_dv": this.bankAccount.agencyDv,
        "account": this.bankAccount.account,
        "account_dv": this.bankAccount.accountDv,
        "type": this.bankAccount.type.getString(),
        "document_number": this.bankAccount.documentNumber,
        "legal_name": this.bankAccount.legalName,
      };
    }
    return json;
  }
}

enum DeleteReason {
  badTripExperience,
  badAppExperience,
  hasAnotherAccount,
  doesntUseService,
  another,
}
