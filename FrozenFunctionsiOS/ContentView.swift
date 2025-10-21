import SwiftUI
import CoreData
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddItem = false
    @State private var showingProfile = false

    var body: some View {

        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                        .foregroundStyle(.tint)
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                        .foregroundStyle(.tint)
            }
        }
    }
}

#Preview {
    ContentView()
}
