import SwiftUI
import CoreData
import UserNotifications
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

// MARK: - AppDelegate for Notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        // Initialize Firebase
        FirebaseApp.configure()
        
        
        // Set notification delegate but DON'T request permission here
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        
        return true
    }
    
    // Handle Google Sign-In URL
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

// MARK: - Main App
@main
struct FrozenFunctionsiOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager()
    @State private var isTransitioning = false  // ✅ NEW: Track transition state
    
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
                        // No user - show welcome screen
                        ModernWelcomeView()
                            .environmentObject(authManager)
                            .transition(.opacity)
                    } else if authManager.needsProfileSetup {
                        // ✅ NEW: Google user needs profile setup
                        GoogleProfileSetupView()
                            .environmentObject(authManager)
                            .transition(.opacity)
                    } else {
                        // User authenticated and profile complete
                        ContentView()
                            .environment(\.managedObjectContext, persistence.container.viewContext)
                            .environmentObject(authManager)
                            .transition(.opacity)
                    }
                }
                .opacity(isTransitioning ? 0 : 1)  // ✅ Fade out during transition
                .blur(radius: isTransitioning ? 10 : 0)  // ✅ Blur during transition
            }
            .animation(.easeInOut(duration: 0.15), value: authManager.user?.uid)  // ✅ Faster animation
            .animation(.easeInOut(duration: 0.15), value: authManager.needsProfileSetup)
            .animation(.easeInOut(duration: 0.15), value: isTransitioning)
            .onChange(of: authManager.user?.uid) { oldValue, newValue in
                // ✅ Smooth transition when auth state changes
                if oldValue != newValue {
                    withAnimation(.easeInOut(duration: 0.1)) {  // ✅ Faster transition
                        isTransitioning = true
                    }
                    
                    // Reset transition state after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {  // ✅ Shorter delay
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isTransitioning = false
                        }
                    }
                }
            }
        }
    }
}
