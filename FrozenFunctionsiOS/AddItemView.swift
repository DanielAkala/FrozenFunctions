//import SwiftUI
//import CoreData
//import UserNotifications
//
//struct AddItemView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.managedObjectContext) private var viewContext
//    @EnvironmentObject var authManager: AuthenticationManager
//    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
//
//    var itemToEdit: FoodItem?
//    
//    @State private var name = ""
//    @State private var quantity = 1
//    @State private var selectedUnit = "Items"
//    @State private var expirationDate = Date()
//    @State private var showError = false
//    @State private var errorMessage = ""
//    @State private var isSaving = false  // ✅ NEW: Prevent double-tap
//    
//    private let units = ["Items", "Box(es)", "Bag(s)", "Bottle(s)", "Can(s)", "lbs", "oz", "kg", "g", "L", "mL"]
//    
//    private var isEditing: Bool {
//        itemToEdit != nil
//    }
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                Styles.Colors.mainColor.ignoresSafeArea()
//                
//                Form {
//                    Section {
//                        HStack {
//                            Label("Item Name:", systemImage: "pencil.circle.fill")
//                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
//                            
//                            TextField("Enter Food Name", text: $name)
//                                .textInputAutocapitalization(.words)
//                                .autocorrectionDisabled()
//                                .foregroundColor(Styles.Colors.accentColor)
//                        }
//                        .listRowBackground(Styles.Colors.secondaryColor)
//
//                        HStack {
//                            Label("Quantity:", systemImage: "number.circle.fill")
//                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
//                            
//                            Spacer()
//                            
//                            Text("\(quantity)")
//                                .foregroundColor(Styles.Colors.accentColor)
//                                .font(.body)
//                            
//                            Picker("", selection: $selectedUnit) {
//                                ForEach(units, id: \.self) { unit in
//                                    Text(unit).tag(unit)
//                                }
//                            }
//                            .pickerStyle(.menu)
//                            .tint(Styles.Colors.accentColor)
//                            .frame(width: 100)
//                            
//                            Stepper("", value: $quantity, in: 1...999)
//                                .labelsHidden()
//                        }
//                        .listRowBackground(Styles.Colors.secondaryColor)
//                        .colorScheme(.dark)
//
//                        DatePicker(selection: $expirationDate, displayedComponents: .date) {
//                            HStack {
//                                Label("Expires On", systemImage: "calendar.badge.clock")
//                                    .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
//                            }
//                        }
//                        .datePickerStyle(.wheel)
//                        .listRowBackground(Styles.Colors.secondaryColor)
//                        .colorScheme(.dark)
//                        
//                    } header: {
//                        Label("Food Information", systemImage: "fork.knife.circle.fill")
//                            .foregroundColor(Styles.Colors.thirdColor)
//                    }
//                    
//                    Section {
//                        Button(action: {
//                            guard !isSaving else { return }  // ✅ Prevent double-tap
//                            isSaving = true
//                            Task {
//                                await saveItem()
//                            }
//                        }) {
//                            HStack {
//                                Spacer()
//                                if isSaving {
//                                    ProgressView()
//                                        .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.accentColor))
//                                } else {
//                                    Text(isEditing ? "Update" : "Save")
//                                }
//                                Spacer()
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Styles.Colors.secondaryColor)
//                        .foregroundColor(Styles.Colors.accentColor)
//                        .cornerRadius(12)
//                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
//                        .listRowBackground(Styles.Colors.mainColor)
//                    }
//                }
//                .navigationTitle(isEditing ? "Edit Food" : "Add Food")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .cancellationAction) {
//                        Button("Cancel") {
//                            dismiss()
//                        }
//                        .foregroundColor(Styles.Colors.accentColor)
//                    }
//                }
//                .toolbarBackground(.visible, for: .navigationBar)
//                .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
//                .toolbarColorScheme(.dark, for: .navigationBar)
//                .scrollContentBackground(.hidden)
//                .alert("Error", isPresented: $showError) {
//                    Button("OK", role: .cancel) { }
//                } message: {
//                    Text(errorMessage)
//                }
//            }
//        }
//        .onAppear {
//            loadItemData()
//        }
//    }
//    
//    private func loadItemData() {
//        guard let item = itemToEdit else { return }
//        
//        name = item.name ?? ""
//        quantity = Int(item.quantity)
//        selectedUnit = item.unit ?? "Items"
//        expirationDate = item.expirationDate ?? Date()
//    }
//
//    private func saveItem() async {
//        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else {
//            await MainActor.run {
//                isSaving = false
//            }
//            return
//        }
//
//        print("Attempting to save item: \(trimmed)")
//        
//        let item: FoodItem
//        
//        if let existingItem = itemToEdit {
//            item = existingItem
//            print("Updating existing item with ID: \(item.id?.uuidString ?? "nil")")
//        } else {
//            item = FoodItem(context: viewContext)
//            item.id = UUID()
//            print("Item created with ID: \(item.id?.uuidString ?? "nil")")
//        }
//        
//        item.name = trimmed
//        item.quantity = Int16(quantity)
//        item.unit = selectedUnit
//        item.expirationDate = expirationDate
//
//        do {
//            try viewContext.save()
//            print("✅ Save successful!")
//            
//            // ✅ Save to Firestore (if authenticated and database exists)
//            do {
//                try await FirestoreService.shared.saveFoodItem(item, context: viewContext)
//                print("✅ Item synced to Firestore")
//            } catch {
//                print("⚠️ Failed to sync to cloud (this is OK if Firestore isn't set up): \(error)")
//            }
//            
//            // Schedule notification if enabled
//            if notificationsEnabled {
//                scheduleExpirationNotification(for: item)
//            } else {
//                print("🔵 Notifications disabled - skipping notification scheduling")
//            }
//            
//            // ✅ CRITICAL: Dismiss on main thread AFTER all async work completes
//            await MainActor.run {
//                isSaving = false
//                dismiss()
//            }
//        } catch {
//            print("❌ Save failed: \(error.localizedDescription)")
//            await MainActor.run {
//                isSaving = false
//                errorMessage = "Failed to save: \(error.localizedDescription)"
//                showError = true
//            }
//        }
//    }
//    
//    private func scheduleExpirationNotification(for item: FoodItem) {
//        guard let id = item.id?.uuidString,
//              let name = item.name,
//              let expiryDate = item.expirationDate else { return }
//        
//        let calendar = Calendar.current
//        let now = Date()
//        
//        let expirationDay = calendar.startOfDay(for: expiryDate)
//        let today = calendar.startOfDay(for: now)
//        
//        guard let daysDifference = calendar.dateComponents([.day], from: today, to: expirationDay).day else {
//            print("⚠️ Could not calculate days difference")
//            return
//        }
//        
//        print("📊 Days until expiration for \(name): \(daysDifference)")
//        
//        let content = UNMutableNotificationContent()
//        content.sound = .default
//        let trigger: UNNotificationTrigger
//
//        #if DEBUG
//        if daysDifference < 0 {
//            content.title = "⚠️ Expired! (Demo)"
//            content.body = "\(name) has already expired. Please check your item."
//            print("DEBUG: Item already expired - scheduling notification in 5 seconds")
//        } else if daysDifference == 0 {
//            content.title = "🚨 Expires Today! (Demo)"
//            content.body = "\(name) expires today. Use it now!"
//            print("DEBUG: Item expires today - scheduling notification in 5 seconds")
//        } else if daysDifference == 1 {
//            content.title = "⏰ Expiring Soon! (Demo)"
//            content.body = "\(name) expires tomorrow. Use it soon!"
//            print("DEBUG: Item expires tomorrow - scheduling notification in 5 seconds")
//        } else {
//            print("📅 No demo notification scheduled for \(name). Expires in \(daysDifference) days.")
//            return
//        }
//        
//        trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
//        
//        #else
//        if daysDifference < 0 {
//            print("⚠️ Item already expired, not scheduling notification")
//            return
//        }
//        
//        content.title = "Expiring Soon! 🧊"
//        content.body = "\(name) is expiring today. Don't forget to use it!"
//        
//        var triggerDate = calendar.dateComponents([.year, .month, .day], from: expiryDate)
//        triggerDate.hour = 9
//        triggerDate.minute = 0
//        trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
//        
//        #endif
//
//        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
//
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("❌ Notification error: \(error.localizedDescription)")
//            } else {
//                print("✅ Notification scheduled for \(name) (id: \(id))")
//            }
//        }
//    }
//}
//
//#Preview {
//    AddItemView()
//        .environmentObject(AuthenticationManager())
//}

import SwiftUI
import CoreData
import UserNotifications
import FirebaseAuth

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var notificationsEnabled = true  // ✅ Changed from @AppStorage

    var itemToEdit: FoodItem?
    
    @State private var name = ""
    @State private var quantity = 1
    @State private var selectedUnit = "Items"
    @State private var expirationDate = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false  // ✅ NEW: Prevent double-tap
    
    private let units = ["Items", "Box(es)", "Bag(s)", "Bottle(s)", "Can(s)", "lbs", "oz", "kg", "g", "L", "mL"]
    
    private var isEditing: Bool {
        itemToEdit != nil
    }

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

                        HStack {
                            Label("Quantity:", systemImage: "number.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                            
                            Spacer()
                            
                            Text("\(quantity)")
                                .foregroundColor(Styles.Colors.accentColor)
                                .font(.body)
                            
                            Picker("", selection: $selectedUnit) {
                                ForEach(units, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Styles.Colors.accentColor)
                            .frame(width: 100)
                            
                            Stepper("", value: $quantity, in: 1...999)
                                .labelsHidden()
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
                        Button(action: {
                            guard !isSaving else { return }  // ✅ Prevent double-tap
                            isSaving = true
                            Task {
                                await saveItem()
                            }
                        }) {
                            HStack {
                                Spacer()
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Styles.Colors.accentColor))
                                } else {
                                    Text(isEditing ? "Update" : "Save")
                                }
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Styles.Colors.secondaryColor)
                        .foregroundColor(Styles.Colors.accentColor)
                        .cornerRadius(12)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                        .listRowBackground(Styles.Colors.mainColor)
                    }
                }
                .navigationTitle(isEditing ? "Edit Food" : "Add Food")
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
        .onAppear {
            loadItemData()
            loadNotificationSetting()  // ✅ Load user-specific setting
        }
    }
    
    // ✅ Load user-specific notification setting
    private func loadNotificationSetting() {
        if let userId = authManager.user?.uid {
            notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled_\(userId)") as? Bool ?? true
        } else {
            notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        }
    }
    
    private func loadItemData() {
        guard let item = itemToEdit else { return }
        
        name = item.name ?? ""
        quantity = Int(item.quantity)
        selectedUnit = item.unit ?? "Items"
        expirationDate = item.expirationDate ?? Date()
    }

    private func saveItem() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run {
                isSaving = false
            }
            return
        }

        print("Attempting to save item: \(trimmed)")
        
        let item: FoodItem
        
        if let existingItem = itemToEdit {
            item = existingItem
            print("Updating existing item with ID: \(item.id?.uuidString ?? "nil")")
        } else {
            item = FoodItem(context: viewContext)
            item.id = UUID()
            print("Item created with ID: \(item.id?.uuidString ?? "nil")")
        }
        
        item.name = trimmed
        item.quantity = Int16(quantity)
        item.unit = selectedUnit
        item.expirationDate = expirationDate

        do {
            try viewContext.save()
            print("✅ Save successful!")
            
            // ✅ Save to Firestore (if authenticated and database exists)
            do {
                try await FirestoreService.shared.saveFoodItem(item, context: viewContext)
                print("✅ Item synced to Firestore")
            } catch {
                print("⚠️ Failed to sync to cloud (this is OK if Firestore isn't set up): \(error)")
            }
            
            // Schedule notification if enabled
            if notificationsEnabled {
                scheduleExpirationNotification(for: item)
            } else {
                print("🔵 Notifications disabled - skipping notification scheduling")
            }
            
            // ✅ CRITICAL: Dismiss on main thread AFTER all async work completes
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        } catch {
            print("❌ Save failed: \(error.localizedDescription)")
            await MainActor.run {
                isSaving = false
                errorMessage = "Failed to save: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func scheduleExpirationNotification(for item: FoodItem) {
        guard let id = item.id?.uuidString,
              let name = item.name,
              let expiryDate = item.expirationDate else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        let expirationDay = calendar.startOfDay(for: expiryDate)
        let today = calendar.startOfDay(for: now)
        
        guard let daysDifference = calendar.dateComponents([.day], from: today, to: expirationDay).day else {
            print("⚠️ Could not calculate days difference")
            return
        }
        
        print("📊 Days until expiration for \(name): \(daysDifference)")
        
        let content = UNMutableNotificationContent()
        content.sound = .default
        let trigger: UNNotificationTrigger

        #if DEBUG
        if daysDifference < 0 {
            content.title = "⚠️ Expired! (Demo)"
            content.body = "\(name) has already expired. Please check your item."
            print("DEBUG: Item already expired - scheduling notification in 5 seconds")
        } else if daysDifference == 0 {
            content.title = "🚨 Expires Today! (Demo)"
            content.body = "\(name) expires today. Use it now!"
            print("DEBUG: Item expires today - scheduling notification in 5 seconds")
        } else if daysDifference == 1 {
            content.title = "⏰ Expiring Soon! (Demo)"
            content.body = "\(name) expires tomorrow. Use it soon!"
            print("DEBUG: Item expires tomorrow - scheduling notification in 5 seconds")
        } else {
            print("📅 No demo notification scheduled for \(name). Expires in \(daysDifference) days.")
            return
        }
        
        trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        #else
        if daysDifference < 0 {
            print("⚠️ Item already expired, not scheduling notification")
            return
        }
        
        content.title = "Expiring Soon! 🧊"
        content.body = "\(name) is expiring today. Don't forget to use it!"
        
        var triggerDate = calendar.dateComponents([.year, .month, .day], from: expiryDate)
        triggerDate.hour = 9
        triggerDate.minute = 0
        trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        #endif

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            } else {
                print("✅ Notification scheduled for \(name) (id: \(id))")
            }
        }
    }
}

#Preview {
    AddItemView()
        .environmentObject(AuthenticationManager())
}
