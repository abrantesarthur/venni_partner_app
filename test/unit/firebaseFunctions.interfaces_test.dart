import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/vendors/firebaseFunctions/interfaces.dart';

void main() {
  group("Trip", () {
    test("fromJson with empty argument", () {
      Trip t = Trip.fromJson({});
      expect(t, isNotNull);
      expect(t.clientID, isNull);
      expect(t.tripStatus, isNull);
      expect(t.originPlaceID, isNull);
      expect(t.destinationPlaceID, isNull);
      expect(t.farePrice, isNull);
      expect(t.distanceMeters, isNull);
      expect(t.distanceText, isNull);
      expect(t.durationSeconds, isNull);
      expect(t.durationText, isNull);
      expect(t.clientToDestinationEncodedPoints, isNull);
      expect(t.requestTime, isNull);
      expect(t.originAddress, isNull);
      expect(t.destinationAddress, isNull);
      expect(t.paymentMethod, isNull);
      expect(t.clientName, isNull);
      expect(t.clientPhone, isNull);
      expect(t.originLat, isNull);
      expect(t.originLng, isNull);
      expect(t.destinationLat, isNull);
      expect(t.destinationLng, isNull);
    });

    test("fromJson with valid argument", () {
      Map<String, dynamic> json = {
        "uid": "uid",
        "trip_status": "waiting-confirmation",
        "origin_place_id": "origin_place_id",
        "destination_place_id": "destination_place_id",
        "fare_price": 100,
        "distance_meters": "100",
        "distance_text": "Cem metros",
        "duration_seconds": "60",
        "duration_text": "Um minuto",
        "encoded_points": "encoded_points",
        "request_time": "123456789",
        "origin_address": "origin_address",
        "destination_address": "destination_address",
        "payment_method": "credit_card",
        "client_name": "client_name",
        "client_phone": "client_phone",
        "origin_lat": "11.111111",
        "origin_lng": "22.222222",
        "destination_lat": "33.333333",
        "destination_lng": "44.444444",
      };
      Trip t = Trip.fromJson(json);
      expect(t, isNotNull);
      expect(t.clientID, equals("uid"));
      expect(t.tripStatus, equals(TripStatus.waitingConfirmation));
      expect(t.originPlaceID, equals("origin_place_id"));
      expect(t.destinationPlaceID, equals("destination_place_id"));
      expect(t.farePrice, equals(100));
      expect(t.distanceMeters, equals(100));
      expect(t.distanceText, equals("Cem metros"));
      expect(t.durationSeconds, equals(60));
      expect(t.durationText, equals("Um minuto"));
      expect(t.clientToDestinationEncodedPoints, equals("encoded_points"));
      expect(t.requestTime, equals(123456789));
      expect(t.originAddress, equals("origin_address"));
      expect(t.destinationAddress, equals("destination_address"));
      expect(t.paymentMethod, equals(PaymentMethod.creditCard));
      expect(t.clientName, equals("client_name"));
      expect(t.clientPhone, equals("client_phone"));
      expect(t.originLat, equals(11.111111));
      expect(t.originLng, equals(22.222222));
      expect(t.destinationLat, equals(33.333333));
      expect(t.destinationLng, equals(44.444444));
    });
  });

  group("PaymentMethod", () {
    test("fromString with null argument", () {
      PaymentMethod? pm = PaymentMethodExtension.fromString(null);
      expect(pm, isNull);
    });
    test("fromString with empty string", () {
      PaymentMethod? pm = PaymentMethodExtension.fromString("");
      expect(pm, isNull);
    });

    test("fromString with invalid string", () {
      PaymentMethod? pm = PaymentMethodExtension.fromString("invalid");
      expect(pm, isNull);
    });

    test("fromString with 'cash' argument", () {
      PaymentMethod? pm = PaymentMethodExtension.fromString("cash");
      expect(pm, equals(PaymentMethod.cash));
    });

    test("fromString with 'credit_card' argument", () {
      PaymentMethod? pm = PaymentMethodExtension.fromString("credit_card");
      expect(pm, equals(PaymentMethod.creditCard));
    });
  });
  group("TripStatus", () {
    test("fromString with null argument", () {
      TripStatus? ts = TripStatusExtension.fromString(null);
      expect(ts, isNull);
    });
    test("fromString with empty string", () {
      TripStatus? ts = TripStatusExtension.fromString("");
      expect(ts, isNull);
    });

    test("fromString with invalid string", () {
      TripStatus? ts = TripStatusExtension.fromString("invalid");
      expect(ts, isNull);
    });

    test("fromString with valid argument", () {
      TripStatus? ts = TripStatusExtension.fromString("waiting-confirmation");
      expect(ts, equals(TripStatus.waitingConfirmation));
      ts = TripStatusExtension.fromString("waiting-payment");
      expect(ts, equals(TripStatus.waitingPayment));
      ts = TripStatusExtension.fromString("waiting-partner");
      expect(ts, equals(TripStatus.waitingPartner));
      ts = TripStatusExtension.fromString("looking-for-partner");
      expect(ts, equals(TripStatus.lookingForPartner));
      ts = TripStatusExtension.fromString("in-progress");
      expect(ts, equals(TripStatus.inProgress));
      ts = TripStatusExtension.fromString("completed");
      expect(ts, equals(TripStatus.completed));
      ts = TripStatusExtension.fromString("cancelled-by-partner");
      expect(ts, equals(TripStatus.cancelledByPartner));
      ts = TripStatusExtension.fromString("cancelled-by-client");
      expect(ts, equals(TripStatus.cancelledByClient));
      ts = TripStatusExtension.fromString("payment-failed");
      expect(ts, equals(TripStatus.paymentFailed));
    });
  });
}
