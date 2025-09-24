import SwiftUI
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
