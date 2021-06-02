import 'package:flutter/material.dart';
import 'package:partner_app/models/connectivity.dart';
import 'package:provider/provider.dart';

class Documents extends StatefulWidget {
  static const routeName = "Documents";
  @override
  DocumentsState createState() => DocumentsState();
}

class DocumentsState extends State<Documents> with WidgetsBindingObserver {
  bool _hasConnection;

  @override
  Widget build(BuildContext context) {
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    return Scaffold(
      body: Stack(
        children: [Center(child: Text("documents"))],
      ),
    );
  }
}
