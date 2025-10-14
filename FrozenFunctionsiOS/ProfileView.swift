import SwiftUI
import UserNotifications

//ADDME: allergens (common ones like peanuts, shellfish, vegan/vegetarian) dropdown selection

struct ProfileView: View {
    
    @State private var name = "TestUser"
    @State private var fridgeType = "DefaultFridge"
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            Form {
//                Text("Edit")
//                    .toolbar {
//                        ToolbarItem(placement: .navigationBarTrailing) {
//                            Button(action: { isEditing.toggle()}) {
//                                Label("Add", systemImage: "plus")
//                            }
                            Section(header: Text("Profile")){
                                Text(name)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                Text(fridgeType)
                                
                                // Change to be when editing username, fridge, etc
                                TextField("Item name", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled() // doesnt save between sessions
                                
                            }
                        }
                    }
            }
        }
//    }
//}

#Preview {
    ProfileView()
}
