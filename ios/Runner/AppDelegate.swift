import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // extract googleMapsApiKey from dartEnvironmentVariables

    // // read DartEnvironmentVariables from Info.plist
    // var dartEnvironmentVariables: String = (Bundle.main.infoDictionary?["DartEnvironmentVariables"] as! String) ?? ""
    // // use ',' as a serapator to convert dartEnvironmentVariables string into array
    // let dartEnvironmentVariablesArray = dartEnvironmentVariables.components(separatedBy: ",")
    // // look for entry in dartEnvironmentVariablesArray containing 'GOOGLE_MAPS_API_KEY' string
    // var googleMapsApiKeyEntry : String = ""
    // for entry in dartEnvironmentVariablesArray {
    //   if entry.contains("IOS_GOOGLE_MAPS_API_KEY") {
    //     googleMapsApiKeyEntry = entry
    //     break
    //   }
    // }
    // // use '%3D' (i.e., '=' sign) as a serapator to convert googleMapsApiKeyEntry string into tuple
    // var googleMapsApiKeyNameAndValue = googleMapsApiKeyEntry.components(separatedBy: "%3D")
    // // googleMapsApiKey is the value of the googleMapsApiKeyEntry key x value pair
    // var googleMapsApiKey: String = ""
    // if(googleMapsApiKeyNameAndValue.count > 1) {
    //   googleMapsApiKey = googleMapsApiKeyNameAndValue[1]
    // }
    // FIXME: remove hardcoded API keys
    GMSServices.provideAPIKey("AIzaSyCK58KogR8m_I_unlhint9mwQkAy-_Ft3g")

    GeneratedPluginRegistrant.register(with: self)
    BackgroundLocationTrackerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}