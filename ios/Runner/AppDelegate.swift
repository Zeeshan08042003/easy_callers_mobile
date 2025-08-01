import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

    var callStartTime: Date?
    var methodChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller = window.rootViewController as! FlutterViewController
        methodChannel = FlutterMethodChannel(name: "com.easy_callers/call",
                                             binaryMessenger: controller.binaryMessenger)

        methodChannel?.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }

            if call.method == "startCall" {
                if let number = call.arguments as? String {
                    self.callStartTime = Date()
                    self.makeCall(to: number)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Phone number required", details: nil))
                }

            } else if call.method == "whatsappChat" {
                if let args = call.arguments as? [String: Any],
                   let number = args["number"] as? String {
                    let message = args["message"] as? String ?? "Hello"
                    self.openWhatsAppChat(with: number, message: message)
                    result("WhatsApp chat opened")
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Phone number required", details: nil))
                }
            }
        }
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Phone Call
    func makeCall(to number: String) {
        if let url = URL(string: "tel://\(number)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // Called when app comes back to foreground
  override func applicationWillEnterForeground(_ application: UIApplication) {
      if let startTime = callStartTime {
          let endTime = Date()
          let rawDuration = endTime.timeIntervalSince(startTime)
          let adjustedDuration = max(0, rawDuration - 5) // Subtract 5 seconds buffer
          let seconds = Int(adjustedDuration)

          let formatted = formatDuration(seconds: seconds)

//           if seconds >= 30 && seconds <= 35 {
//               methodChannel?.invokeMethod("callEnded", arguments: "Call not connected")
//           } else if seconds == 50 {
//               methodChannel?.invokeMethod("callEnded", arguments: "Call not connected")
//           } else {
//               methodChannel?.invokeMethod("callEnded", arguments: formatted)
//           }
              methodChannel?.invokeMethod("callEnded", arguments: formatted)

          callStartTime = nil
      }
  }



    // MARK: - Format Duration
    func formatDuration(seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }

    // MARK: - WhatsApp Chat
    func openWhatsAppChat(with phoneNumber: String, message: String = "Hello") {
        let cleaned = phoneNumber
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Hello"
        if let url = URL(string: "https://wa.me/\(cleaned)?text=\(encodedMessage)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                print("WhatsApp not installed")
            }
        }
    }
}
