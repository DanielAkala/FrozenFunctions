import SwiftUI
import CoreData
import UserNotifications
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        FirebaseApp.configure()

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct FrozenFunctionsiOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager()
    @State private var isTransitioning = false 
    
    let persistence = PersistenceController.shared
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Styles.Colors.secondaryColor)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if authManager.user == nil {
                        ModernWelcomeView()
                            .environmentObject(authManager)
                            .transition(.opacity)
                    } else if authManager.needsProfileSetup {
                        GoogleProfileSetupView()
                            .environmentObject(authManager)
                            .transition(.opacity)
                    } else {
                        ContentView()
                            .environment(\.managedObjectContext, persistence.container.viewContext)
                            .environmentObject(authManager)
                            .transition(.opacity)
                    }
                }
                .opacity(isTransitioning ? 0 : 1)  
                .blur(radius: isTransitioning ? 10 : 0)  
            }
            .animation(.easeInOut(duration: 0.15), value: authManager.user?.uid) 
            .animation(.easeInOut(duration: 0.15), value: authManager.needsProfileSetup)
            .animation(.easeInOut(duration: 0.15), value: isTransitioning)
            .onChange(of: authManager.user?.uid) { oldValue, newValue in
                if oldValue != newValue {
                    withAnimation(.easeInOut(duration: 0.1)) { 
                        isTransitioning = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {  
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isTransitioning = false
                        }
                    }
                }
            }
        }
    }
}
