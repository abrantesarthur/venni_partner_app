import 'package:flutter/material.dart';
import 'package:partner_app/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncher {
  static Future<void> openWhatsapp(
    BuildContext context,
    String phoneNumber,
  ) async {
    String _whatsappUrl = "https://wa.me/" + phoneNumber;
    if (await canLaunch(_whatsappUrl)) {
      await launch(_whatsappUrl);
    } else {
      showOkDialog(
        context: context,
        title: "Falha ao abrir whatsapp",
        content: "Tente novamente.",
      );
    }
  }

  static Future<void> openPhone(
    BuildContext context,
    String phoneNumber,
  ) async {
    String _phoneUrl = "tel:" + phoneNumber;
    if (await canLaunch(_phoneUrl)) {
      await launch(_phoneUrl);
    } else {
      showOkDialog(
        context: context,
        title: "Falha ao ligar para cliente",
        content: "Tente novamente.",
      );
    }
  }
}
