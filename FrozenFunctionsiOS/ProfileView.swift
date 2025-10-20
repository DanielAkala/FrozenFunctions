import SwiftUI
import UserNotifications

struct ProfileView: View {
    @State private var name = "TestUser"
    @State private var fridgeType = "DefaultFridge"
    @State private var isEditing = false
    @State private var selectedOption: String = "None"
    @State private var isEditingText: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                
                Styles.Colors.mainColor.ignoresSafeArea()
    
                Form {
                    if isEditingText {
                        TextField("Name", text: $name)
                            .focused($isTextFieldFocused)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled() // doesnt save between sessions
                            .font(.title3)
                            .foregroundColor(Styles.Colors.accentColor)
                            .listRowBackground(Styles.Colors.secondaryColor)
 
                    } else {
                        Text("Name: " + name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .font(.title3)
                            .foregroundColor(Styles.Colors.accentColor)
                            .listRowBackground(Styles.Colors.secondaryColor)
                    }
                    if isEditingText {
                        TextField("Fridge Name", text: $fridgeType)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .font(.title3)
                            .foregroundColor(Styles.Colors.accentColor)
                            .listRowBackground(Styles.Colors.secondaryColor)
                    } else {
                        Text("Fridge: " + fridgeType)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .font(.title3)
                            .foregroundColor(Styles.Colors.accentColor)
                            .listRowBackground(Styles.Colors.secondaryColor)
                    }
                    Button (isEditingText ? "Done" : "Edit") {
                        isEditingText.toggle()
                    }
                    
                    .listRowBackground(Styles.Colors.secondaryColor)
                    .navigationTitle("Profile")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            
                        }
                    }
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    
                    // Diet:
                    Section(header: Text("Dietary Restrictions").foregroundColor(Styles.Colors.accentColor)) {
                        Menu (selectedOption) {
                            Button("None") {
                                selectedOption = "None"
                            }
                            Button("Vegan") {
                                selectedOption = "Vegan"
                            }
                            Button("Vegetarian") {
                                selectedOption = "Vegetarian"
                            }
                            Button("Pescatarian") {
                                selectedOption = "Pescatarian"
                            }
                            Button("Peanut Allergy") {
                                selectedOption = "Peanut Allergy"
                            }
                            Button("Lactose Intolerance") {
                                selectedOption = "Lactose Intolerance"
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                    }
                    .listRowBackground(Styles.Colors.secondaryColor)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}
#Preview {
    ProfileView()
}
