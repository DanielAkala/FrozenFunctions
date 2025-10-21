import SwiftUI
import CoreData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name = ""
    @State private var quantity = 1
    @State private var expirationDate = Date()
    // 1. State for the scale effect
    @State private var quantityScale: CGFloat = 1.0

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
                            HStack {
                                Label("Quantity: ", systemImage: "number.circle.fill")
                                    .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                                Text("\(quantity)")
                                    .font(.body.weight(.bold))
                                    .scaleEffect(quantityScale)
                                    .onChange(of: quantity) {
                                        withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.5, blendDuration: 0.5)) {
                                            quantityScale = 1.2
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.5, blendDuration: 0.5)) {
                                                quantityScale = 1.0
                                            }
                                        }
                                    }
                                Spacer()
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)

                        DatePicker(selection: $expirationDate, displayedComponents: .date) {
                            HStack {
                                Label("Expires On:", systemImage: "calendar.badge.clock")
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
