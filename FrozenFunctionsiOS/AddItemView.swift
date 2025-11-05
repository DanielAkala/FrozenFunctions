/*import SwiftUI
import UserNotifications

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity = 1
    @State private var expirationDate = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Info")) {
                    TextField("Item name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    Stepper(value: $quantity, in: 1...100) {
                        Text("Quantity: \(quantity)")
                    }

                    DatePicker("Expires on", selection: $expirationDate, displayedComponents: .date)
                }

                Section(footer: Text("In this sprint, Save only closes the form (no persistence yet).")) {
                    Button("Save (UI Only)") {
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Add Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddItemView()
}*/

import SwiftUI
import CoreData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name = ""
    @State private var quantity = 1
    @State private var expirationDate = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Info")) {
                    TextField("Item name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    Stepper(value: $quantity, in: 1...100) {
                        Text("Quantity: \(quantity)")
                    }

                    DatePicker("Expires on", selection: $expirationDate, displayedComponents: .date)
                }

                Section {
                    Button("Save") { saveItem() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func saveItem() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let item = FoodItem(context: viewContext)
        item.id = UUID()
        item.name = trimmed
        item.quantity = Int16(quantity)
        item.expirationDate = expirationDate

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Save failed: \(error.localizedDescription)")
        }
    }
}
