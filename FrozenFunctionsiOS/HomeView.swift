import SwiftUI
import UserNotifications

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddItem = false
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Image(systemName: "snowflake")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue.opacity(0.4))
                Text("Your fridge is empty 🧊 ")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                
                Text("Tap ➕ to start adding items.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .navigationTitle("FrozenFunctions")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingAddItem = true }) {
                                Label("Add", systemImage: "plus")
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddItem) {
                        AddItemView()
                            .environment(\.managedObjectContext, viewContext)
                    }
            }
        }
    }
}
