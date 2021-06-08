import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/yesNoDialog.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _askPermission(
  BuildContext context,
  String description,
) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return YesNoDialog(
          title: description,
          onPressedYes: () async {
            await openAppSettings();
            Navigator.pop(context);
          });
    },
  );
}

Future<PickedFile> pickImageFromGallery(BuildContext context) async {
  // try to get image
  try {
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
    );
    return pickedFile;
  } catch (e) {
    // ask user to update permission in app settings
    await _askPermission(
      context,
      "Permitir Acesso às Fotos",
    );
  }
  return null;
}

Future<PickedFile> pickImageFromCamera(BuildContext context) async {
  // request permission
  PermissionStatus status = await Permission.camera.request();

  // if permission was denied
  if (status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted ||
      status == PermissionStatus.denied) {
    // ask user to update permission in app settings
    await _askPermission(
      context,
      "Permitir Acesso à Câmera",
    );
    return null;
  }

  // if permission was greanted
  if (status == PermissionStatus.granted) {
    // get image
    return await ImagePicker().getImage(
      source: ImageSource.camera,
    );
  }

  return null;
}

Future<PickedFile> pickImage(BuildContext context) async {
  return await showDialog<PickedFile>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Escolher Foto"),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Divider(color: Colors.black, thickness: 0.1),
              ListTile(
                onTap: () async {
                  // get image from gallery
                  PickedFile img = await pickImageFromGallery(context);
                  Navigator.pop(context, img);
                },
                title: Text("Galeria"),
                leading: Icon(
                  Icons.photo_album,
                  color: AppColor.primaryPink,
                ),
              ),
              Divider(color: Colors.black, thickness: 0.1),
              ListTile(
                onTap: () async {
                  // get image from camera
                  PickedFile img = await pickImageFromCamera(context);
                  Navigator.pop(context, img);
                },
                title: Text("Câmera"),
                leading: Icon(
                  Icons.camera_alt,
                  color: AppColor.primaryPink,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
