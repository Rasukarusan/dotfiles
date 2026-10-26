import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var notifTitle = ""
    var notifSubtitle = ""
    var notifMessage = ""
    var notifPane = ""
    var hasNotification = false

    // 通知クリックで起動されたとき、didReceive より前に delegate を設定しておく必要がある
    func applicationWillFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !hasNotification {
            // 通知クリックなら didReceive が来る。来なければ iTerm を前面に出すだけ
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.activateTerminal()
                NSApp.terminate(nil)
            }
            return
        }

        let center = UNUserNotificationCenter.current()
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
        if !notifPane.isEmpty { content.userInfo = ["pane": notifPane] }

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

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let pane = response.notification.request.content.userInfo["pane"] as? String {
            focusTmuxPane(pane)
        }
        activateTerminal()
        completionHandler()
        DispatchQueue.main.async { NSApp.terminate(nil) }
    }

    func activateTerminal() {
        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: "com.googlecode.iterm2",
            options: [],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
    }

    func focusTmuxPane(_ pane: String) {
        let home = NSHomeDirectory()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "\(home)/dotfiles/bin/tmux-focus-pane")
        process.arguments = [pane]
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "\(home)/dotfiles/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        process.environment = env
        try? process.run()
        process.waitUntilExit()
    }
}

let args = CommandLine.arguments
var title = "Claude Code"
var subtitle = ""
var message = ""
var pane = ""
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
    case "-pane":     pane = args[i]
    default: continue
    }
    i += 1
}

let appDelegate = AppDelegate()
appDelegate.notifTitle = title
appDelegate.notifSubtitle = subtitle
appDelegate.notifMessage = message
appDelegate.notifPane = pane
appDelegate.hasNotification = hasArgs

let app = NSApplication.shared
app.delegate = appDelegate
app.setActivationPolicy(.accessory)
app.run()
