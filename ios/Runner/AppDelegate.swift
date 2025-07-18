import Flutter
import UIKit
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurar Firebase
    FirebaseApp.configure()
    
    // Configurar notificaciones
    UNUserNotificationCenter.current().delegate = self
    
    // Solicitar permisos de notificación
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound],
      completionHandler: { granted, error in
        if granted {
          print("Permisos de notificación concedidos")
        } else {
          print("Permisos de notificación denegados")
        }
      }
    )
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Manejar notificaciones cuando la app está en primer plano
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Mostrar notificación incluso cuando la app está en primer plano
    completionHandler([.alert, .badge, .sound])
  }
}
