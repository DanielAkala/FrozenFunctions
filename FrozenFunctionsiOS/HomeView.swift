import SwiftUI
import UserNotifications

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddItem = false
    @State private var showingProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()
                
                VStack(spacing: 12) {
                    Image(systemName: "snowflake")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(Styles.Colors.accentColor)
                    
                    Text("Your fridge is empty 🧊")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Styles.Colors.accentColor)
                    
                    HStack(spacing: 0) {
                        Text("To Add Items please tap the plus ")
                            .font(.title3)
                            .foregroundColor(Styles.Colors.accentColor)
                        
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(Styles.Colors.accentColor)
                    }
                    
                    Text("icon in the top right corner")
                        .font(.title3)
                        .foregroundColor(Styles.Colors.accentColor)
                }
            }
            .navigationTitle("FrozenFunctions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView().environment(\.managedObjectContext, viewContext)
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}


#Preview {
    HomeView()
}
