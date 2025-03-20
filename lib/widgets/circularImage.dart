import 'package:flutter/material.dart';

class CircularImage extends StatelessWidget {
  final ImageProvider<Object>? imageFile;
  final double? size;

  CircularImage({required this.imageFile, this.size});
  // TODO: use screenWidth instead of screenHeight

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: size ?? screenHeight / 7,
      height: size ?? screenHeight / 7,
      decoration: new BoxDecoration(
        shape: BoxShape.circle,
        image: new DecorationImage(
          fit: BoxFit.cover,
          image: imageFile == null
              ? AssetImage("images/user_icon.png")
              : imageFile!,
        ),
      ),
    );
  }
}
