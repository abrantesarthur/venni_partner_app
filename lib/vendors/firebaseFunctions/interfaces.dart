import 'package:flutter/material.dart';

class BalanceProperty {
  int amount; // in cents

  BalanceProperty({@required this.amount});

  factory BalanceProperty.fromJson(Map json) {
    if (json == null) {
      return null;
    }
    return BalanceProperty(amount: json["amount"]);
  }
}

class Balance {
  final BalanceProperty waitingFunds;
  final BalanceProperty available;
  final BalanceProperty transfered;

  Balance({
    @required this.waitingFunds,
    @required this.available,
    @required this.transfered,
  });

  factory Balance.fromJson(Map json) {
    return json == null
        ? null
        : Balance(
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
  static TransferType fromString(String s) {
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
  static TransferStatus fromString(String s) {
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
}

class Transfer {
  int id;
  int amount;
  TransferType type;
  TransferStatus status;
  int fee;
  int fundingDate;
  int fundingEstimatedDate;
  int transactionID;

  Transfer({
    @required this.id,
    @required this.amount,
    @required this.type,
    @required this.status,
    @required this.fee,
    @required this.fundingDate,
    @required this.fundingEstimatedDate,
    @required this.transactionID,
  });

  factory Transfer.fromJson(Map json) {
    if (json == null) {
      return null;
    }

    TransferType type = TransferTypeExtension.fromString(json["type"]);
    TransferStatus status = TransferStatusExtension.fromString(json["status"]);

    return Transfer(
      id: json["id"],
      amount: json["amount"],
      type: type,
      status: status,
      fee: json["fee"],
      fundingDate: json["funding_date"],
      fundingEstimatedDate: json["funding_estimated_date"],
      transactionID: json["transaction_id"],
    );
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
  static TripStatus fromString(String s) {
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
  static PaymentMethod fromString(String s) {
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
  int pageSize;
  int maxRequestTime;
  int minRequestTime;

  GetPastTripsArguments({
    this.pageSize,
    this.maxRequestTime,
    this.minRequestTime,
  });
}

class Trips {
  final List<Trip> items;

  Trips({@required this.items});

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
    @required this.score,
    @required this.cleanlinessWentWell,
    @required this.safetyWentWell,
    @required this.waitingTimeWentWell,
    @required this.feedback,
  });

  factory PartnerRating.fromJson(Map json) {
    return json == null
        ? null
        : PartnerRating(
            score: json["score"],
            cleanlinessWentWell: json["cleanliness_went_well"],
            safetyWentWell: json["safety_went_well"],
            waitingTimeWentWell: json["waiting_time_went_well"],
            feedback: json["feedback"],
          );
  }
}

class Trip {
  String clientID;
  TripStatus tripStatus;
  String originPlaceID;
  String destinationPlaceID;
  double originLat;
  double originLng;
  double destinationLat;
  double destinationLng;
  int farePrice;
  int distanceMeters;
  String distanceText;
  int durationSeconds;
  String durationText;
  String clientToDestinationEncodedPoints;
  int requestTime;
  String originAddress;
  String destinationAddress;
  PaymentMethod paymentMethod;
  String clientName; // added to the response by partnerGetCurrentTrip
  String clientPhone; // added to response by partnerGetCurrentTrip
  PartnerRating partnerRating;

  Trip({
    @required this.clientID,
    @required this.tripStatus,
    @required this.originPlaceID,
    @required this.destinationPlaceID,
    @required this.originLat,
    @required this.originLng,
    @required this.destinationLat,
    @required this.destinationLng,
    @required this.farePrice,
    @required this.distanceMeters,
    @required this.distanceText,
    @required this.durationSeconds,
    @required this.durationText,
    @required this.clientToDestinationEncodedPoints,
    @required this.requestTime,
    @required this.originAddress,
    @required this.destinationAddress,
    @required this.paymentMethod,
    @required this.clientName,
    @required this.clientPhone,
    @required this.partnerRating,
  });

  factory Trip.fromJson(Map json) {
    if (json == null) {
      return null;
    }

    int distanceMeters = json["distance_meters"] == null
        ? null
        : int.parse(json["distance_meters"]);
    int durationSeconds = json["duration_seconds"] == null
        ? null
        : int.parse(json["duration_seconds"]);
    int requestTime =
        json["request_time"] == null ? null : int.parse(json["request_time"]);
    PaymentMethod paymentMethod =
        PaymentMethodExtension.fromString(json["payment_method"]);
    double originLat =
        json["origin_lat"] == null ? null : double.parse(json["origin_lat"]);
    double originLng =
        json["origin_lng"] == null ? null : double.parse(json["origin_lng"]);
    double destinationLat = json["destination_lat"] == null
        ? null
        : double.parse(json["destination_lat"]);
    double destinationLng = json["destination_lng"] == null
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
    );
  }
}
