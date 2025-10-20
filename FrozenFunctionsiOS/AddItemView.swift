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
            ZStack{
                
                Styles.Colors.mainColor.ignoresSafeArea()
                
                Form {
                    Section {
                        HStack {
                            Label("Item Name:", systemImage: "pencil.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                            
                            TextField("Enter Food Name", text: $name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)

                        Stepper(value: $quantity, in: 1...100) {
                            Label("Quantity: \(quantity)", systemImage: "number.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)

                        DatePicker(selection: $expirationDate, displayedComponents: .date) {
                            HStack {
                                Label("Expires On", systemImage: "calendar.badge.clock")
                                    .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                            }
                        }.datePickerStyle(.wheel)
                         .listRowBackground(Styles.Colors.secondaryColor)
                        
                    } header: {
                        Label("Food Information", systemImage: "fork.knife.circle.fill")
                    }
                    Section {
                        Button("Save") { saveItem() }
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .listRowBackground(Styles.Colors.secondaryColor)
                }
                
                .navigationTitle("Add Food")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }.colorScheme(.dark)

                .background(Styles.Colors.mainColor)
                .scrollContentBackground(.hidden)
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

#Preview {
    AddItemView()
}
