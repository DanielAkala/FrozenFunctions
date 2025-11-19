import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddItem = false

    // State for the clean-out reminder
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
                                    }
                                    HStack {
                                        Text("Qty: \(item.quantity)")
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
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Styles.Colors.secondaryColor)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                )
                                .listRowInsets(EdgeInsets(top: 18, leading: 8, bottom: 18, trailing: 8))
                                //.shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 10)
                            }
                            .onDelete(perform: deleteItems)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Styles.Colors.mainColor)
                    }
                }
            }
            .navigationTitle("FrozenFunctions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
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
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            // Clean-out reminder logic
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
    
    // New: check for too many expired items
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
}
