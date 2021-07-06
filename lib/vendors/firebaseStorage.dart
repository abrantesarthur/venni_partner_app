import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partner_app/models/partner.dart';
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

  // TODO: cache downloaded images
  Future<ProfileImage> getPartnerProfilePicture(String id) async {
    if (id == null) {
      return null;
    }
    ListResult results;
    try {
      results = await this.ref().child("partner-documents").child(id).list();
      if (results != null && results.items.length > 0) {
        Reference profilePhotoRef;
        results.items.forEach((item) {
          if (item.fullPath.contains("profilePhoto")) {
            profilePhotoRef = item;
          }
        });
        if (profilePhotoRef != null) {
          String imageURL = await profilePhotoRef.getDownloadURL();
          return ProfileImage(
            file: NetworkImage(imageURL),
            name: results.items[0].name,
          );
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<ProfileImage> getClientProfilePicture(String id) async {
    if (id == null || id.isEmpty) {
      return null;
    }
    ListResult results;
    try {
      results = await this.ref().child("client-photos").child(id).list();
      if (results != null && results.items.length > 0) {
        Reference profilePhotoRef;
        results.items.forEach((item) {
          if (item.fullPath.contains("profile")) {
            profilePhotoRef = item;
          }
        });
        if (profilePhotoRef != null) {
          String imageURL = await profilePhotoRef.getDownloadURL();
          return ProfileImage(
            file: NetworkImage(imageURL),
            name: results.items[0].name,
          );
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
