import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:partner_app/styles.dart';
import 'package:vibration/vibration.dart';

enum NotificationType {
  tripRequest,
}

class Notifications {
  Notifications._internal();
  static final Notifications _notifications = Notifications._internal();
  factory Notifications() {
    return _notifications;
  }

  Timer? _tripRequestTimer;

  void init({
    required String channelKey,
    required String channelName,
    required String channelDescription,
  }) {
    AwesomeNotifications().initialize('resource://drawable/notification_icon', [
      NotificationChannel(
        channelKey: channelKey,
        channelName: channelName,
        channelDescription: channelDescription,
        defaultColor: AppColor.primaryPink,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        playSound: true,
        soundSource: "resource://raw/trip_request_notification",
        enableVibration: true,
      )
    ]);

    // stop triggering notification when user taps on it
    AwesomeNotifications().actionStream.listen((ReceivedAction _) {
      if (_tripRequestTimer != null) {
        _tripRequestTimer!.cancel();
      }
    });

    // stop triggering notification when user dismisses it
    AwesomeNotifications().dismissedStream.listen((ReceivedAction event) {
      if (_tripRequestTimer != null) {
        _tripRequestTimer!.cancel();
      }
    });
  }

  // stopTriggering stops triggering any existing notification
  void stopTriggering(NotificationType type) {
    if (type == NotificationType.tripRequest && _tripRequestTimer != null) {
      _tripRequestTimer!.cancel();
    }
  }

  // triggers a notification. If repeatingPeriod is not null, it repeatedly triggers
  // the notification with the specified period
  void trigger({
    NotificationType type = NotificationType.tripRequest,
    Duration? repeatingPeriod,
  }) {
    _trigger(type);
    if (repeatingPeriod != null) {
      if (type == NotificationType.tripRequest) {
        _tripRequestTimer =
            Timer.periodic(repeatingPeriod, (_) => _trigger(type));
        Future.delayed(Duration(seconds: 15), () => _tripRequestTimer!.cancel());
      }
    }
  }

  void _trigger(NotificationType type) {
    if (type == NotificationType.tripRequest) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: "trip_request_channel",
          title: "Novo Pedido",
          body: "Pressione 'aceitar' para fazer a corrida",
          displayOnForeground: false,
          displayOnBackground: true,
          notificationLayout: NotificationLayout.BigText,
        ),
      );
      Vibration.vibrate();
    }
  }
}
