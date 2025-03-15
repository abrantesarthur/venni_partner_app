import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/models/partner.dart';
import 'package:partner_app/vendors/firebaseDatabase/interfaces.dart';
import 'package:provider/provider.dart';

const String _TIMESTAMP = "timestamp";
const String _PARTNER_IDLE_INTERVAL = "partner_idle_interval";
const String _TRIP_DURATION = "trip_duration";
const String _CLIENT_WAITING_TIME = "client_waiting_time";
const String _RATE = "rate";

extension AppFirebaseAnalytics on FirebaseAnalytics {
  Future<void> logLogout() {
    return this.logEvent(
      name: "logout",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<void> logPartnerGoOnline() {
    return this.logEvent(
      name: "partner_go_online",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<void> logPartnerGoOffline() {
    return this.logEvent(
      name: "partner_go_offline",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<void> logPartnerRequested() {
    return this.logEvent(name: "partner_requested", parameters: {
      _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  Future<void> logPartnerAvailable() {
    return this.logEvent(name: "partner_available", parameters: {
      _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  // partnerIdleInterval should be in milliseconds
  Future<void> logPartnerBusy({required int partnerIdleInterval}) {
    return this.logEvent(name: "partner_busy", parameters: {
      _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      _PARTNER_IDLE_INTERVAL: (partnerIdleInterval / 1000).round().toString(),
    });
  }

  // tripDuration should be in ms
  Future<void> logPartnerCompleteTrip({required int tripDuration}) {
    return this.logEvent(name: "partner_complete_trip", parameters: {
      _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      _TRIP_DURATION: (tripDuration / 1000).round().toString(),
    });
  }

  Future<void> logPartnerIgnoreRequest() {
    return this.logEvent(name: "partner_ignore_request", parameters: {
      _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  // clientWaitingTime should be in ms
  Future<void> logPartnerStartTrip({required int clientWaitingTime}) {
    return this.logEvent(name: "partner_start_trip", parameters: {
      _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      _CLIENT_WAITING_TIME: (clientWaitingTime / 1000).round().toString(),
    });
  }

  Future<void> logPartnerRateClient(int rate) {
    return this.logEvent(
      name: "partner_rate_client",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
        _RATE: rate.toString(),
      },
    );
  }

  Future<void> setPartnerUserProperty() {
    return this.setUserProperty(name: "user_type", value: "partner");
  }

  Future<void> logEventOnPartnerStatus({
    required BuildContext context,
    required PartnerStatus newStatus,
    required oldStatus,
  }) async {
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);

    // log event and reset availableSince if partner goes online
    if (oldStatus == PartnerStatus.unavailable &&
        newStatus == PartnerStatus.available) {
      partner.availableSince = DateTime.now().millisecondsSinceEpoch;
      await this.logPartnerGoOnline();
    }

    // Reset availableSince if partner finishes a trip. The
    // actual event is logged in the completeTrip function, so that we can
    // calculate trip's duration properly. After all, partner going from busy
    // to available may simply mean they canceled the trip, as opposed to complete it.
    if (oldStatus == PartnerStatus.busy &&
        newStatus == PartnerStatus.available) {
      partner.availableSince = DateTime.now().millisecondsSinceEpoch;
    }

    // log event if partner goes offline
    if (oldStatus == PartnerStatus.available &&
        newStatus == PartnerStatus.unavailable) {
      await this.logPartnerGoOffline();
    }

    // log event if partner is requested
    if (newStatus == PartnerStatus.requested) {
      await this.logPartnerRequested();
    }

    // log event if partner is available
    if (newStatus == PartnerStatus.available) {
      await this.logPartnerAvailable();
    }

    // if partner gets busy, reset busySince, calculate idleInterval and log event
    if (newStatus == PartnerStatus.busy) {
      partner.busySince = DateTime.now().millisecondsSinceEpoch;
      int idleInterval =
          DateTime.now().millisecondsSinceEpoch - partner.availableSince;
      await this.logPartnerBusy(
        partnerIdleInterval: idleInterval,
      );
    }

    return Future.value();
  }
}
