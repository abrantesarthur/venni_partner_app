import 'package:partner_app/services/firebase/database/interfaces.dart';

class BalanceProperty {
  int? amount; // in cents

  BalanceProperty({required this.amount});

  factory BalanceProperty.fromJson(Map? json) {
    return BalanceProperty(amount: json?["amount"]);
  }
}

class Balance {
  final BalanceProperty? waitingFunds;
  final BalanceProperty? available;
  final BalanceProperty? transfered;

  Balance({
    this.waitingFunds,
    this.available,
    this.transfered,
  });

  factory Balance.fromJson(Map json) {
    return Balance(
      waitingFunds: BalanceProperty.fromJson(json["waiting_funds"]),
      available: BalanceProperty.fromJson(json["available"]),
      transfered: BalanceProperty.fromJson(json["transfered"]),
    );
  }
}

enum TransferType {
  ted,
  doc,
  creditoEmConta,
}

extension TransferTypeExtension on TransferType {
  static TransferType? fromString(String s) {
    switch (s) {
      case "ted":
        return TransferType.ted;
      case "doc":
        return TransferType.doc;
      case "credito_em_conta":
        return TransferType.creditoEmConta;
      default:
        return null;
    }
  }
}

enum TransferStatus {
  pendingTransfer,
  transferred,
  failed,
  processing,
  canceled,
}

extension TransferStatusExtension on TransferStatus {
  static TransferStatus? fromString(String s) {
    switch (s) {
      case "pending_transfer":
        return TransferStatus.pendingTransfer;
      case "transferred":
        return TransferStatus.transferred;
      case "failed":
        return TransferStatus.failed;
      case "processing":
        return TransferStatus.processing;
      case "canceled":
        return TransferStatus.canceled;
      default:
        return null;
    }
  }

  String getString() {
    switch (this) {
      case TransferStatus.pendingTransfer:
        return "pendente";
      case TransferStatus.transferred:
        return "concluída";
      case TransferStatus.failed:
        return "falhou";
      case TransferStatus.processing:
        return "processando";
      case TransferStatus.canceled:
        return "cancelada";
      default:
        return "";
    }
  }
}

class Transfer {
  int? id;
  int? amount; // after fees
  TransferType? type;
  TransferStatus? status;
  int? fee;
  DateTime? fundingDate; // TODO: maybe it's a string
  DateTime? fundingEstimatedDate; // TODO: maybe it's a string
  DateTime? dateCreated; //  TODO: maybe it's a string
  BankAccount? bankAccount;

  Transfer({
    this.id,
    this.amount,
    this.type,
    this.status,
    this.fee,
    this.fundingDate,
    this.fundingEstimatedDate,
    this.dateCreated,
    this.bankAccount,
  });

  factory Transfer.fromJson(Map? json) {
    return Transfer(
      id: json?["id"],
      amount: json?["amount"],
      type: TransferTypeExtension.fromString(json?["type"]),
      status: TransferStatusExtension.fromString(json?["status"]),
      fee: json?["fee"],
      fundingDate: json?["funding_date"] == null
          ? null
          : DateTime.parse(json!["funding_date"]),
      fundingEstimatedDate: json?["funding_estimated_date"] == null
          ? null
          : DateTime.parse(json!["funding_estimated_date"]),
      dateCreated: json?["date_created"] == null
          ? null
          : DateTime.parse(json!["date_created"]),
      bankAccount: BankAccount.fromJson(json?["bank_account"]),
    );
  }
}

class Transfers {
  List<Transfer> items;

  Transfers({required this.items});

  factory Transfers.fromJson(List<dynamic> json) {
    List<Transfer> transfers = json.map((t) => Transfer.fromJson(t)).toList();
    return Transfers(items: transfers);
  }
}

enum TripStatus {
  waitingConfirmation,
  waitingPayment,
  waitingPartner,
  lookingForPartner,
  noPartnersAvailable,
  inProgress,
  completed,
  cancelledByPartner,
  cancelledByClient,
  paymentFailed,
}

extension TripStatusExtension on TripStatus {
  static TripStatus? fromString(String s) {
    switch (s) {
      case "waiting-confirmation":
        return TripStatus.waitingConfirmation;
      case "waiting-payment":
        return TripStatus.waitingPayment;
      case "waiting-partner":
        return TripStatus.waitingPartner;
      case "looking-for-partner":
        return TripStatus.lookingForPartner;
      case "in-progress":
        return TripStatus.inProgress;
      case "completed":
        return TripStatus.completed;
      case "cancelled-by-partner":
        return TripStatus.cancelledByPartner;
      case "cancelled-by-client":
        return TripStatus.cancelledByClient;
      case "payment-failed":
        return TripStatus.paymentFailed;
      default:
        return null;
    }
  }
}

enum PaymentMethod {
  cash,
  creditCard,
}

extension PaymentMethodExtension on PaymentMethod {
  static PaymentMethod? fromString(String s) {
    switch (s) {
      case "cash":
        return PaymentMethod.cash;
      case "credit_card":
        return PaymentMethod.creditCard;
      default:
        return null;
    }
  }
}

class GetPastTripsArguments {
  int? pageSize;
  int? maxRequestTime;
  int? minRequestTime;

  GetPastTripsArguments({
    this.pageSize,
    this.maxRequestTime,
    this.minRequestTime,
  });
}

class GetTransfersArguments {
  int count;
  int page;
  String pagarmeRecipientID;

  GetTransfersArguments({
    required this.count,
    required this.page,
    required this.pagarmeRecipientID,
  });
}

class Trips {
  final List<Trip> items;

  Trips({required this.items});

  factory Trips.fromJson(List<dynamic> json) {
    List<Trip> pastTrips = json.map((pt) => Trip.fromJson(pt)).toList();
    return Trips(items: pastTrips);
  }
}

class PartnerRating {
  int score;
  bool cleanlinessWentWell;
  bool safetyWentWell;
  bool waitingTimeWentWell;
  String feedback;

  PartnerRating({
    required this.score,
    required this.cleanlinessWentWell,
    required this.safetyWentWell,
    required this.waitingTimeWentWell,
    required this.feedback,
  });

  factory PartnerRating.fromJson(Map json) {
    return PartnerRating(
            score: json["score"],
            cleanlinessWentWell: json["cleanliness_went_well"],
            safetyWentWell: json["safety_went_well"],
            waitingTimeWentWell: json["waiting_time_went_well"],
            feedback: json["feedback"],
          );
  }
}

class Payment {
  bool success;
  int venniCommission;
  int previousOwedCommission;
  int paidOwedCommission;
  int currentOwedCommission;
  int? partnerAmountReceived;

  Payment({
    required this.success,
    required this.venniCommission,
    required this.previousOwedCommission,
    required this.paidOwedCommission,
    required this.currentOwedCommission,
    required this.partnerAmountReceived,
  });

  factory Payment.fromJson(Map json) {
    return Payment(
            success: json["success"],
            venniCommission: json["venni_commission"],
            previousOwedCommission: json["previous_owed_commission"],
            paidOwedCommission: json["paid_owed_commission"],
            currentOwedCommission: json["current_owed_commission"],
            partnerAmountReceived: json["partner_amount_received"],
          );
  }
}

class Trip {
  String clientID;
  TripStatus? tripStatus;
  String originPlaceID;
  String destinationPlaceID;
  double? originLat;
  double? originLng;
  double? destinationLat;
  double? destinationLng;
  int farePrice;
  int? distanceMeters;
  String distanceText;
  int? durationSeconds;
  String durationText;
  String clientToDestinationEncodedPoints;
  int? requestTime;
  String originAddress;
  String destinationAddress;
  PaymentMethod? paymentMethod;
  String clientName; // added to the response by partnerGetCurrentTrip
  String clientPhone; // added to response by partnerGetCurrentTrip
  PartnerRating partnerRating;
  Payment payment; // added when trip is paid and if with credit card

  Trip({
    required this.clientID,
    required this.tripStatus,
    required this.originPlaceID,
    required this.destinationPlaceID,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.farePrice,
    required this.distanceMeters,
    required this.distanceText,
    required this.durationSeconds,
    required this.durationText,
    required this.clientToDestinationEncodedPoints,
    required this.requestTime,
    required this.originAddress,
    required this.destinationAddress,
    required this.paymentMethod,
    required this.clientName,
    required this.clientPhone,
    required this.partnerRating,
    required this.payment,
  });

  factory Trip.fromJson(Map json) {
    int? distanceMeters = json["distance_meters"] == null
        ? null
        : int.parse(json["distance_meters"]);
    int? durationSeconds = json["duration_seconds"] == null
        ? null
        : int.parse(json["duration_seconds"]);
    int? requestTime =
        json["request_time"] == null ? null : int.parse(json["request_time"]);
    PaymentMethod? paymentMethod =
        PaymentMethodExtension.fromString(json["payment_method"]);
    double? originLat =
        json["origin_lat"] == null ? null : double.parse(json["origin_lat"]);
    double? originLng =
        json["origin_lng"] == null ? null : double.parse(json["origin_lng"]);
    double? destinationLat = json["destination_lat"] == null
        ? null
        : double.parse(json["destination_lat"]);
    double? destinationLng = json["destination_lng"] == null
        ? null
        : double.parse(json["destination_lng"]);

    return Trip(
      clientID: json["uid"],
      tripStatus: TripStatusExtension.fromString(json["trip_status"]),
      originPlaceID: json["origin_place_id"],
      destinationPlaceID: json["destination_place_id"],
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      farePrice: json["fare_price"],
      distanceMeters: distanceMeters,
      distanceText: json["distance_text"],
      durationSeconds: durationSeconds,
      durationText: json["duration_text"],
      clientToDestinationEncodedPoints: json["encoded_points"],
      requestTime: requestTime,
      originAddress: json["origin_address"],
      destinationAddress: json["destination_address"],
      paymentMethod: paymentMethod,
      clientName: json["client_name"],
      clientPhone: json["client_phone"],
      partnerRating: PartnerRating.fromJson(json["partner_rating"]),
      payment: Payment.fromJson(json["payment"]),
    );
  }
}

enum Demand {
  LOW,
  MEDIUM,
  HIGH,
  VERYHIGH,
}

extension DemandExtension on Demand {
  static Demand? fromString(String s) {
    switch (s) {
      case "low":
        return Demand.LOW;
      case "medium":
        return Demand.MEDIUM;
      case "high":
        return Demand.HIGH;
      case "very_high":
        return Demand.VERYHIGH;
      default:
        return null;
    }
  }
}

// TODO: test
class ZoneDemand {
  String zoneName;
  Demand demand;
  double maxLat;
  double minLat;
  double maxLng;
  double minLng;

  ZoneDemand({
    required this.zoneName,
    required this.demand,
    required this.maxLat,
    required this.minLat,
    required this.maxLng,
    required this.minLng,
  });

  factory ZoneDemand.fromJson(Map? json) {
    return ZoneDemand(
      zoneName: json?["zone_name"] ?? "",
      demand: DemandExtension.fromString(json?["demand"]) ?? Demand.LOW,
      maxLat: json?["max_lat"] ?? 0 + .0,
      minLat: json?["min_lat"] ?? 0 + .0,
      maxLng: json?["max_lng"] ?? 0 + .0,
      minLng: json?["min_lng"] ?? 0 + .0,
    );
  }
}

class DemandByZone {
  Map<String, ZoneDemand> values;

  DemandByZone({required this.values});

  factory DemandByZone.fromJson(Map<String, dynamic>? json) {
    Map<String, ZoneDemand> values = {};

    json?.keys.forEach((key) {
      values[key] = ZoneDemand.fromJson(json[key]);
    });

    return DemandByZone(values: values);
  }
}

class ApprovedPartners {
  List<ApprovedPartner> items;

  ApprovedPartners({required this.items});

  factory ApprovedPartners.fromJson(List<dynamic> list) {
    List<ApprovedPartner> partners =
        list.map((p) => ApprovedPartner.fromJson(p)).toList();
    return ApprovedPartners(items: partners);
  }
}

class ApprovedPartner {
  PartnerStatus? status;
  double? currentLatitude;
  double? currentLongitude;

  ApprovedPartner({
    required this.status,
    required this.currentLatitude,
    required this.currentLongitude,
  });

  factory ApprovedPartner.fromJson(Map? json) {
    return ApprovedPartner(
      status: PartnerStatusExtension.fromString(json?["partner_status"]),
      currentLatitude: json?["partner_latitude"] == null
          ? null
          : double.parse(json?["partner_latitude"]),
      currentLongitude: json?["partner_longitude"] == null
          ? null
          : double.parse(json?["partner_longitude"]),
    );
  }
}
