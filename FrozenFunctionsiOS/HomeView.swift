//import SwiftUI
//import CoreData
//
//struct HomeView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    @State private var showingAddItem = false
//
//    // Fetch saved FoodItems, sorted by soonest expiration first
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \FoodItem.expirationDate, ascending: true)],
//        animation: .default
//    )
//    private var items: FetchedResults<FoodItem>
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Styles.Colors.mainColor.ignoresSafeArea()
//
//                Group {
//                    // ───── Empty state ─────
//                    if items.isEmpty {
//                        VStack(spacing: 12) {
//                            Image(systemName: "snowflake")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 100, height: 100)
//                                .foregroundColor(Styles.Colors.accentColor)
//
//                            Text("Your fridge is empty 🧊")
//                                .font(.title3)
//                                .multilineTextAlignment(.center)
//                                .foregroundColor(Styles.Colors.accentColor)
//
//                            HStack(spacing: 4) {
//                                Text("Tap")
//                                Image(systemName: "plus")
//                                Text("to add items")
//                            }
//                            .font(.subheadline)
//                            .foregroundColor(Styles.Colors.thirdColor)
//                        }
//                    } else {
//                        // ───── List ─────
//                        List {
//                            ForEach(items) { item in
//                                VStack(alignment: .leading) {
//                                    Text(item.name ?? "Unknown Item")
//                                        .font(.headline)
//                                        .foregroundColor(Styles.Colors.accentColor)
//                                    HStack {
//                                        Text("Qty: \(item.quantity)")
//                                            .font(.subheadline)
//                                        Text("| Expires: \(formatDate(item.expirationDate))")
//                                            .font(.subheadline)
//                                    }
//                                    .foregroundColor(Styles.Colors.thirdColor)
//                                }
//                            }
//                            .onDelete(perform: deleteItems)
//                        }
//                        .scrollContentBackground(.hidden)
//                        .listRowSeparator(.hidden)
//                        .colorScheme(.dark)
//                    }
//                }
//            }
//            .navigationTitle("FrozenFunctions")
//            .navigationBarTitleDisplayMode(.inline)
//            
//            // ----------------- Original Toolbar Buttons -----------------
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    // Restored standard EditButton
//                    EditButton()
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    // Restored standard Add Button
//                    Button(action: { showingAddItem = true }) {
//                        Label("Add", systemImage: "plus")
//                    }
//                }
//            }
//            .sheet(isPresented: $showingAddItem) {
//                AddItemView()
//                    .environment(\.managedObjectContext, viewContext)
//            }
//            .toolbarBackground(.visible, for: .navigationBar)
//            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
//            .toolbarColorScheme(.dark, for: .navigationBar)
//        }
//    }
//
//    // MARK: - Helper functions
//    private func deleteItems(at offsets: IndexSet) {
//        offsets.map { items[$0] }.forEach(viewContext.delete)
//        do {
//            try viewContext.save()
//        } catch {
//            print("Error deleting item: \(error.localizedDescription)")
//        }
//    }
//
//    private func formatDate(_ date: Date?) -> String {
//        guard let date = date else { return "N/A" }
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        return formatter.string(from: date)
//    }
//}

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
                                        .foregroundColor(Styles.Colors.accentColor)

                                    HStack {
                                        Text("Qty: \(item.quantity)")
                                            .foregroundColor(Styles.Colors.accentColor)
                                        Spacer()
                                        Text("Expires: \(formatDate(item.expirationDate))")
                                            .foregroundColor(Styles.Colors.accentColor)
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
            .navigationBarTitleDisplayMode(.inline)
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
