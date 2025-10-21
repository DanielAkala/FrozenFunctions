import SwiftUI
import CoreData
@main
struct FrozenFunctionsiOSApp: App {
    let persistence = PersistenceController.shared
    
    init() {
            let appearance = UITabBarAppearance()
            
            appearance.configureWithOpaqueBackground()
            
            appearance.backgroundColor = UIColor(Styles.Colors.mainColor)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
        }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
    
}

