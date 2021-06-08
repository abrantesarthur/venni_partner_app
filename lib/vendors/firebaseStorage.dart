import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as dartIo;

extension AppFirebaseStorage on FirebaseStorage {
  void sendCrlv({
    @required String partnerID,
    @required PickedFile crlv,
  }) {
    try {
      this
          .ref()
          .child("partner-documents")
          .child(partnerID)
          .child("crlv" + path.extension(crlv.path))
          .putFile(dartIo.File(crlv.path));
    } catch (e) {}
  }
}
