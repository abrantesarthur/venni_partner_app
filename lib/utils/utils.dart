// TODO: test
import 'dart:math';
import 'dart:ui'
    as ui; // imported as ui to prevent conflict between ui.Image and the Image widget
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:partner_app/styles.dart';
import 'package:partner_app/widgets/okDialog.dart';

extension CPFExtension on String {
  // expects format xxxxxxxxxxx
  bool isValidCPF() {
    if (this == null || this.length != 11 || this._allDigitsAreTheSame()) {
      return false;
    }

    int sum = 0;
    // multiply first 9 digits by decreasing sequence from 10 to 2
    for (var i = 0; i < 9; i++) {
      sum += int.parse(this[i]) * (10 - i);
    }

    // calculate remaining. Default to 0 if it is 10 or 11.
    int remaining = (sum * 10) % 11;
    remaining = (remaining == 10 || remaining == 11) ? 0 : remaining;

    // remaining must equal 10th digit
    if (remaining != int.parse(this[9])) {
      return false;
    }

    // multiply first 10 digits by decreasing sequence from 11 to 2

    sum = 0;
    for (var i = 0; i < 10; i++) {
      sum += int.parse(this[i]) * (11 - i);
    }

    // calculate remaining. Default to 0 if it is 10 or 11.

    remaining = (sum * 10) % 11;
    remaining = (remaining == 10 || remaining == 11) ? 0 : remaining;

    // remaining must equal 11th digit
    if (remaining != int.parse(this[10])) {
      return false;
    }

    return true;
  }

  // get cpf in format xxx.xxx.xxx-xx and return in format xxxxxxxxxxx
  String getCleanedCPF() {
    if (this == null || this.length != 14) {
      return "";
    }
    return this.substring(0, 3) +
        this.substring(4, 7) +
        this.substring(8, 11) +
        this.substring(12);
  }

  bool _allDigitsAreTheSame() {
    bool value = true;
    for (var i = 0, j = 1; i < this.length - 1; i++, j++) {
      if (this[i] != this[j]) {
        value = false;
        break;
      }
    }
    return value;
  }
}

extension ExpirationDateExtension on String {
  // expirationDate has MM/YY format
  String getCleanedExpirationDate() {
    if (this == null || this.length != 5) {
      return "";
    }
    return this.substring(0, 2) + this.substring(3);
  }

  bool isValidExpirationDate() {
    if (this.length != 4) {
      return false;
    }

    int month = int.parse(this.substring(0, 2));
    int year = int.parse(this.substring(2));
    int currYear = int.parse(DateTime.now().year.toString().substring(2, 4));
    int currMonth = DateTime.now().month;

    bool expirationMonthIsValid = month >= 1 && month <= 12;
    bool expirationYearIsValid = year == currYear
        ? month >= currMonth
        : year < currYear
            ? false
            : true;
    return expirationMonthIsValid && expirationYearIsValid;
  }
}

extension EmailExtension on String {
  bool isValid() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

extension PasswordExtension on String {
  bool containsLetter() {
    return RegExp(r'[a-zA-Z]+').hasMatch(this);
  }

  bool containsDigit() {
    return RegExp(r'\d+').hasMatch(this);
  }
}

extension PhoneNumberExtension on String {
  String withCountryCode() {
    return this
        .replaceRange(3, 5, "")
        .replaceRange(5, 7, "")
        .replaceRange(10, 11, "");
  }

  String withoutCountryCode() {
    return this
        .replaceRange(0, 3, "")
        .replaceRange(0, 0, "(")
        .replaceRange(3, 3, ") ")
        .replaceRange(10, 10, "-");
  }

// isValidPhoneNumber returns true if phone has format (##) ##### ####
  bool isValidPhoneNumber() {
    if (this == null) {
      return false;
    }
    String pattern = r'^\([\d]{2}\) [\d]{5}-[\d]{4}$';
    RegExp regExp = new RegExp(pattern);
    if (regExp.hasMatch(this)) {
      return true;
    }
    return false;
  }
}

extension AppBitmapDescriptor on BitmapDescriptor {
  static Future<BitmapDescriptor> fromSvg(
    BuildContext context,
    String assetName, {
    double width = 16,
    double height = 16,
  }) async {
    // Read SVG file as String
    String svgString =
        await DefaultAssetBundle.of(context).loadString(assetName);
    // Create DrawableRoot from SVG String
    DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, null);

    // toPicture() and toImage() don't seem to be pixel ratio aware, so we calculate the actual sizes here
    MediaQueryData queryData = MediaQuery.of(context);
    double devicePixelRatio = queryData.devicePixelRatio;

    // Convert to ui.Picture
    ui.Picture picture = svgDrawableRoot.toPicture(
        size: Size(width * devicePixelRatio, height * devicePixelRatio));

    // Convert to ui.Image. toImage() takes width and height as parameters
    // you need to find the best size to suit your needs and take into account the
    // screen DPI
    ui.Image image = await picture.toImage(50, 50);
    ByteData bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }

  static final int _markerSize = 64;
  static final _fillCircleOffset = _markerSize / 2;
  static final _fillCircleRadius = _markerSize / 2;
  static final _iconSize = sqrt(pow(_markerSize, 2) / 2);
  static final rectDiagonal = sqrt(2 * pow(_markerSize, 2));
  static final circleDistanceToCorners = (rectDiagonal - _markerSize) / 2;
  static final _iconOffset = sqrt(pow(circleDistanceToCorners, 2) / 2);

  static Future<BitmapDescriptor> fromIconData(
    IconData iconData,
  ) async {
    // instantiate the canvas
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // paint white icon with pink fill circle around it
    _paintCircleFill(canvas, AppColor.primaryPink);
    _paintIcon(canvas, iconData, Colors.white);

    // encode the whole thing to PNG data, so that the Marker can read it.
    final picture = pictureRecorder.endRecording();
    final image =
        await picture.toImage(_markerSize.round(), _markerSize.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    // create a BitmapDescriptor from our PNG data and instantiate the Marker with it:
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }

  static void _paintIcon(Canvas canvas, IconData iconData, Color iconColor) {
    // create textPainter to paint icon on canvas
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // let textPainter do its work
    textPainter.text = TextSpan(
      // textPainter needs text to paint, so we express icon as string
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        letterSpacing: 0,
        fontSize: _iconSize,
        fontFamily: iconData.fontFamily,
        color: iconColor,
      ),
    );
    textPainter.layout();

    // paint the icon on canvas
    textPainter.paint(canvas, Offset(_iconOffset, _iconOffset));
  }

  // Paints the icon background
  static void _paintCircleFill(Canvas canvas, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(
        Offset(_fillCircleOffset, _fillCircleOffset), _fillCircleRadius, paint);
  }
}

// TEXTINPUTFORMATTERS

// mask: whatever is not 'x' is considered a separator
class MaskedInputFormatter extends TextInputFormatter {
  final String mask;
  List<int> separatorIndexes;

  MaskedInputFormatter({@required this.mask}) {
    separatorIndexes = [];
    for (var i = 0; i < mask.length; i++) {
      if (mask[i] != "x") {
        separatorIndexes.add(i);
      }
    }
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var newText = StringBuffer();
    for (int i = 0, maskIndex = 0; i < newValue.text.length; i++, maskIndex++) {
      if (separatorIndexes.contains(maskIndex)) {
        newText.write(mask[maskIndex]);
        maskIndex++;
      }
      newText.write(newValue.text[i]);
    }

    return newValue.copyWith(
      text: newText.toString(),
      selection: new TextSelection.collapsed(offset: newText.toString().length),
    );
  }
}

Future<T> showOkDialog<T>(
  BuildContext context,
  String title,
  String content,
) async {
  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return OkDialog(
          title: title,
          content: content,
        );
      });
}
