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
  });

  // TODO: test this shit
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
    );
  }
}
