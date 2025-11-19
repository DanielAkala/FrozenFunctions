import SwiftUI
import CoreData
import UserNotifications

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name = ""
    @State private var quantity = 1
    @State private var expirationDate = Date()
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Styles.Colors.mainColor.ignoresSafeArea()
                
                Form {
                    Section {
                        HStack {
                            Label("Item Name:", systemImage: "pencil.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                            
                            TextField("Enter Food Name", text: $name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .foregroundColor(Styles.Colors.accentColor)
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)

                        Stepper(value: $quantity, in: 1...100) {
                            Label("Quantity: \(quantity)", systemImage: "number.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                        .colorScheme(.dark)

                        DatePicker(selection: $expirationDate, displayedComponents: .date) {
                            HStack {
                                Label("Expires On", systemImage: "calendar.badge.clock")
                                    .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                            }
                        }
                        .datePickerStyle(.wheel)
                        .listRowBackground(Styles.Colors.secondaryColor)
                        .colorScheme(.dark)
                        
                    } header: {
                        Label("Food Information", systemImage: "fork.knife.circle.fill")
                            .foregroundColor(Styles.Colors.thirdColor)
                    }
                    
                    Section {
                        Button("Save") {
                            saveItem()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Styles.Colors.secondaryColor)
                        .foregroundColor(Styles.Colors.accentColor)
                        .cornerRadius(8)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .listRowBackground(Styles.Colors.mainColor)
                    }
                }
                .navigationTitle("Add Food")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(Styles.Colors.accentColor)
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .scrollContentBackground(.hidden)
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
            }
        }
    }

    private func saveItem() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        print("Attempting to save item: \(trimmed)")
        
        let item = FoodItem(context: viewContext)
        item.id = UUID()
        item.name = trimmed
        item.quantity = Int16(quantity)
        item.expirationDate = expirationDate
        
        print("Item created with ID: \(item.id?.uuidString ?? "nil")")

        do {
            try viewContext.save()
            print("Save successful!")
            
            // Call the updated notification scheduler
            scheduleExpirationNotifications(for: item)
            
            dismiss()
        } catch {
            print("Save failed: \(error.localizedDescription)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - UPDATED NOTIFICATION LOGIC (FOR 5-SECOND DEMO)
    private func scheduleExpirationNotifications(for item: FoodItem) {
        // Only run the demo notification logic in a DEBUG environment
        #if DEBUG
        guard let id = item.id?.uuidString,
              let name = item.name,
              let expiryDate = item.expirationDate else { return }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        // 1. Calculate the target dates
        let expirationDay = calendar.startOfDay(for: expiryDate)
        let today = calendar.startOfDay(for: Date())
        
        // 2. Check if the item expires tomorrow (Expiring Soon)
        if expirationDay == calendar.date(byAdding: .day, value: 1, to: today) {
            
            let content = UNMutableNotificationContent()
            content.title = "⏰ Expiring Soon! (5s Demo)"
            content.body = "\(name) expires tomorrow. Use it soon!"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "soon-\(id)", content: content, trigger: trigger)
            
            center.add(request) { error in
                print(error == nil ? "✅ Scheduled 'Expiring Soon' (Tomorrow) for \(name) in 5s." : "❌ Notification error: \(error!.localizedDescription)")
            }
            
        // 3. Check if the item expires today (Day Of)
        } else if expirationDay == today {
            
            let content = UNMutableNotificationContent()
            content.title = "🚨 Expired Today! (5s Demo)"
            content.body = "\(name) has expired today. Please check your item."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "today-\(id)", content: content, trigger: trigger)
            
            center.add(request) { error in
                print(error == nil ? "✅ Scheduled 'Expired Today' for \(name) in 5s." : "❌ Notification error: \(error!.localizedDescription)")
            }
            
        // 4. Otherwise, print that no demo notification was scheduled
        } else {
            print("📅 No demo notification scheduled for \(name). Expiration date is not tomorrow or today.")
        }
        
        // ⭐️ FIX: The incorrect line for removing notifications has been removed.
        // The UNUserNotificationCenter.add() call automatically replaces requests with the same identifier,
        // which serves as the proper cleanup/update mechanism.

        #else
        // Production Logic (Schedule for 9:00 AM on the day of expiration)
        guard let id = item.id?.uuidString,
              let name = item.name,
              let expiryDate = item.expirationDate else { return }
              
        let content = UNMutableNotificationContent()
        content.title = "Expiring Soon! 🧊"
        content.body = "\(name) is expiring today. Don't forget to use it!"
        content.sound = .default

        var triggerDate = Calendar.current.dateComponents([.year, .month, .day], from: expiryDate)
        triggerDate.hour = 9
        triggerDate.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            } else {
                print("📅 Production notification scheduled for \(name) (id: \(id))")
            }
        }
        #endif
    }
}

#Preview {
    AddItemView()
}
