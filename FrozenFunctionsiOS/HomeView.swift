/*import SwiftUI
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
}*/

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddItem = false

    // Fetch saved FoodItems, sorted by soonest expiration first
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItem.expirationDate, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<FoodItem>

    var body: some View {
        NavigationStack {
            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()

                Group {
                    // ───── Empty state ─────
                    if items.isEmpty {
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

                            HStack(spacing: 4) {
                                Text("Tap")
                                Image(systemName: "plus")
                                Text("to add items")
                            }
                            .font(.title3)
                            .foregroundColor(Styles.Colors.accentColor)
                        }
                    }
                    // ───── List of saved items ─────
                    else {
                        List {
                            ForEach(items) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Unnamed Item")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    HStack {
                                        Text("Qty: \(item.quantity)")
                                        Spacer()
                                        Text("Expires: \(formatDate(item.expirationDate))")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.subheadline)
                                }
                                .listRowBackground(Styles.Colors.secondaryColor)
                            }
                            .onDelete(perform: deleteItems)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("FrozenFunctions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
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
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Helper functions
    private func deleteItems(at offsets: IndexSet) {
        offsets.map { items[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting item: \(error.localizedDescription)")
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
