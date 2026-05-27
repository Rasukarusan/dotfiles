import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var notifTitle = ""
    var notifSubtitle = ""
    var notifMessage = ""
    var hasNotification = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !hasNotification {
            NSWorkspace.shared.launchApplication(
                withBundleIdentifier: "com.googlecode.iterm2",
                options: [],
                additionalEventParamDescriptor: nil,
                launchIdentifier: nil
            )
            DispatchQueue.main.async { NSApp.terminate(nil) }
            return
        }

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                self.sendNotification()
            } else {
                DispatchQueue.main.async { NSApp.terminate(nil) }
            }
        }
    }

    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = notifTitle
        if !notifSubtitle.isEmpty { content.subtitle = notifSubtitle }
        content.body = notifMessage

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

let args = CommandLine.arguments
var title = "Claude Code"
var subtitle = ""
var message = ""
var hasArgs = false

var i = 1
while i < args.count {
    let arg = args[i]
    i += 1
    guard i < args.count else { break }
    switch arg {
    case "-title":    title = args[i]; hasArgs = true
    case "-subtitle": subtitle = args[i]; hasArgs = true
    case "-message":  message = args[i]; hasArgs = true
    default: continue
    }
    i += 1
}

let appDelegate = AppDelegate()
appDelegate.notifTitle = title
appDelegate.notifSubtitle = subtitle
appDelegate.notifMessage = message
appDelegate.hasNotification = hasArgs

let app = NSApplication.shared
app.delegate = appDelegate
app.setActivationPolicy(.accessory)
app.run()
