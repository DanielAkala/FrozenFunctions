import SwiftUI
import CoreData

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
                        .cornerRadius(12)
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
            dismiss()
        } catch {
            print("Save failed: \(error.localizedDescription)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    AddItemView()
}
