import SwiftUI
import CoreData

@main
struct FrozenFunctionsiOSApp: App {
    let persistence = PersistenceController.shared
    
    //Fixes TabView background color change issue
    init() {
        let appearance = UITabBarAppearance()
        
        appearance.configureWithOpaqueBackground()
        
        appearance.backgroundColor = UIColor(Styles.Colors.secondaryColor)
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
