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
}

enum AccountStatus {
  pendingDocuments,
  pendingApproval,
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
      case "pending_approval":
        return AccountStatus.pendingApproval;
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

extension GenderExtesion on Gender {
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
}

class SubmittedDocuments {
  final bool cnh;
  final bool crlv;
  final bool photoWithCnh;
  final bool profilePhoto;
  final bool bankInfo;

  SubmittedDocuments({
    @required this.cnh,
    @required this.crlv,
    @required this.photoWithCnh,
    @required this.profilePhoto,
    @required this.bankInfo,
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
            bankInfo: json["bank_info"] == null ? false : json["bank_info"],
          );
  }
}

enum BankAccountType {
  conta_corrente,
  conta_poupanca,
  conta_corrente_conjunta,
  conta_poupanca_conjunta,
}

class BankAccount {
  final String bankCode; // 3 chars max, all numbers
  final String agency; // 4 chars max, all numbers
  final String agencyDv; // optional
  final String account;
  final String accountDv;
  final BankAccountType type;
  final String documentNumber;
  final String legalName;

  BankAccount({
    @required this.bankCode,
    @required this.agency,
    @required this.agencyDv,
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
            bankCode: json["bank_code"],
            agency: json["agency"],
            agencyDv: json["agency_dv"],
            account: json["account"],
            accountDv: json["account_dv"],
            type: json["type"],
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
    // TODO: make sure this is correct
    if (this.type != null) {
      map["type"] = this.type.toString().substring(15);
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
  final String pagarmeReceiverID;
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
    @required this.pagarmeReceiverID,
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
  });

  // TODO: test the shit out of this
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
      gender: GenderExtesion.fromString(json["gender"]),
      memberSince: memberSince,
      phoneNumber: json["phone_number"],
      rating: rating,
      totalTrips: totalTrips,
      pagarmeReceiverID: json["pagarme_receiver_id"],
      partnerStatus: PartnerStatusExtension.fromString(json["partner_status"]),
      accountStatus: AccountStatusExtension.fromString(json["account_status"]),
      denialReason: json["denial_reason"],
      lockReason: json["lock_reason"],
      currentClientID: json["current_client_id"],
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
      currentZone: json["currentZone"],
      idleSince: idleSince,
      vehicle: Vehicle.fromJson(json["vehicle"]),
      submittedDocuments: submittedDocuments,
      bankAccount: bankAccount,
    );
  }

  // TODO: test
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
      json["gender"] = this.gender.toString().substring(7);
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
    if (this.pagarmeReceiverID != null) {
      json["pagarme_receiver_id"] = this.pagarmeReceiverID;
    }
    if (this.partnerStatus != null) {
      json["partner_status"] = this.partnerStatus.toString().substring(14);
    }
    if (this.accountStatus != null) {
      json["account_status"] = this.accountStatus.toString().substring(14);
    }
    if (this.denialReason != null) {
      json["denial_reason"] = this.denialReason;
    }
    if (this.lockReason != null) {
      json["lock_reason"] = this.lockReason;
    }
    if (this.currentClientID != null) {
      json["current_client_id"] = this.currentClientID;
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
        "bank_info": this.submittedDocuments.bankInfo == null
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
        "type": this.bankAccount.type.toString().substring(15),
        "document_number": this.bankAccount.documentNumber,
        "legal_name": this.bankAccount.legalName,
      };
    }
    return json;
  }
}
