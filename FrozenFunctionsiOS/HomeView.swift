import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingAddItem = false
    @State private var itemToEdit: FoodItem?
    @State private var isEditMode = false
    @State private var showExpiredAlert = false
    @State private var hasShownExpiredAlert = false

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
                    } else {
                        List {
                            ForEach(items) { item in
                                HStack(spacing: 0) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(item.name ?? "Unnamed Item")
                                                .font(.headline)
                                                .foregroundColor(Styles.Colors.accentColor)
                                                .padding(.horizontal, 24)
                                            
                                            if isExpired(item.expirationDate) {
                                                Text("Expired")
                                                    .font(.caption2)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.red)
                                                    .cornerRadius(6)
                                            } else if isExpiringSoon(item.expirationDate) {
                                                Text("Use Soon")
                                                    .font(.caption2)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.orange)
                                                    .cornerRadius(6)
                                            }
                                            
                                            Spacer()
                                        }
                                        HStack {
                                            Text("Qty: \(item.quantity) \(item.unit ?? "Items")")
                                                .foregroundColor(Styles.Colors.accentColor)
                                                .padding(.horizontal, 24)

                                            Spacer()
                                            Text("Expires: \(formatDate(item.expirationDate))")
                                                .foregroundColor(Styles.Colors.accentColor)
                                                .padding(.horizontal, 24)
                                        }
                                        .font(.subheadline)
                                    }
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if isEditMode {
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                itemToEdit = item
                                                isEditMode = false
                                            }) {
                                                Image(systemName: "pencil.circle.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundStyle(.blue, .blue.opacity(0.2))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button(action: {
                                                deleteItem(item)
                                            }) {
                                                Image(systemName: "trash.circle.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundStyle(.red, .red.opacity(0.2))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(.trailing, 16)
                                        .transition(.move(edge: .trailing).combined(with: .opacity))
                                    }
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Styles.Colors.secondaryColor)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                )
                                .listRowInsets(EdgeInsets(top: 18, leading: 8, bottom: 18, trailing: 8))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Styles.Colors.mainColor)
                        .animation(.easeInOut(duration: 0.3), value: isEditMode)
                    }
                }
            }
            .navigationTitle("FrozenFunctions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditMode ? "Done" : "Edit") {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }
                    .foregroundColor(Styles.Colors.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Label("Add", systemImage: "plus")
                    }
                    .foregroundColor(Styles.Colors.accentColor)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(authManager)
            }
            .sheet(item: $itemToEdit) { item in
                AddItemView(itemToEdit: item)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(authManager)
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear(perform: checkExpiredThreshold)
            .alert("🧼 Clean Out Reminder",
                   isPresented: $showExpiredAlert) {
                Button("Got it!", role: .cancel) { }
            } message: {
                Text("You have at least 3 expired items. It might be time to clean out your fridge.")
            }
        }
    }

    // MARK: - Helper functions
    private func deleteItem(_ item: FoodItem) {
        withAnimation {
            // ✅ Delete from Firestore first (if authenticated)
            if let itemId = item.id?.uuidString {
                Task {
                    do {
                        try await FirestoreService.shared.deleteFoodItem(id: itemId)
                    } catch {
                        print("⚠️ Failed to delete from cloud: \(error)")
                    }
                }
            }
            
            // Delete from Core Data
            viewContext.delete(item)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting item: \(error.localizedDescription)")
            }
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func isExpired(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return date < Date()
    }

    private func isExpiringSoon(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return date <= tomorrow && !isExpired(date)
    }

    private func colorForExpiration(_ date: Date?) -> Color {
        if isExpired(date) { return .red }
        if isExpiringSoon(date) { return .orange }
        return .secondary
    }
    
    private func checkExpiredThreshold() {
        guard !hasShownExpiredAlert else { return }
        let expiredCount = items.filter { isExpired($0.expirationDate) }.count
        
        if expiredCount >= 3 {
            showExpiredAlert = true
            hasShownExpiredAlert = true
            print("🧼 Clean out reminder triggered: \(expiredCount) expired items.")
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(AuthenticationManager())
}
