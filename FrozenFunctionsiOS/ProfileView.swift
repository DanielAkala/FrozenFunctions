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
            Form {
                Section(header: Text("Profile")){
                    if isEditingText {
                        TextField("Name", text: $name)
                            .focused($isTextFieldFocused)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled() // doesnt save between sessions
                    } else {
                        Text("Name: " + name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    if isEditingText {
                        TextField("Fridge Name", text: $fridgeType)
                            .focused($isTextFieldFocused)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled() // doesnt save between sessions
                    } else {
                        Text("Fridge: " + fridgeType)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    Button (isEditingText ? "Done" : "Edit") {
                        isEditingText.toggle()
                    }
                    
                }
                
                // Diet:
                Section(header: Text("Dietary Restrictions")) {
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
                }
            }
        }
    }
}
