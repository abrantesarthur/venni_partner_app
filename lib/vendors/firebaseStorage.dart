import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as dartIo;

extension AppFirebaseStorage on FirebaseStorage {
  Future<void> pushCrlv({
    @required String partnerID,
    @required PickedFile crlv,
  }) async {
    try {
      await this
          .ref()
          .child("partner-documents")
          .child(partnerID)
          .child("crlv" + path.extension(crlv.path))
          .putFile(dartIo.File(crlv.path));
    } catch (e) {
      throw e;
    }
  }

  Future<void> pushCnh({
    @required String partnerID,
    @required PickedFile cnh,
  }) async {
    try {
      await this
          .ref()
          .child("partner-documents")
          .child(partnerID)
          .child("cnh" + path.extension(cnh.path))
          .putFile(dartIo.File(cnh.path));
    } catch (e) {}
  }

  Future<void> pushPhotoWithCnh({
    @required String partnerID,
    @required PickedFile photoWithCnh,
  }) async {
    try {
      await this
          .ref()
          .child("partner-documents")
          .child(partnerID)
          .child("photoWithCnh" + path.extension(photoWithCnh.path))
          .putFile(dartIo.File(photoWithCnh.path));
    } catch (e) {}
  }

  Future<void> pushProfilePhoto({
    @required String partnerID,
    @required PickedFile profilePhoto,
  }) async {
    try {
      await this
          .ref()
          .child("partner-documents")
          .child(partnerID)
          .child("profilePhoto" + path.extension(profilePhoto.path))
          .putFile(dartIo.File(profilePhoto.path));
    } catch (e) {}
  }
}
