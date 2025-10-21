import SwiftUI
import UserNotifications

struct ProfileView: View {
    @State private var name = "TestUser"
    @State private var fridgeType = "DefaultFridge"
    @State private var isEditing = false
    @State private var selectedOption: String = "None"
    @State private var isEditingText: Bool = false
    @State private var isEditingRestrictions: Bool = false
    
    @FocusState private var isTextFieldFocused: Bool
        
    var body: some View {
        NavigationView {
            ZStack {
                
                Styles.Colors.mainColor.ignoresSafeArea()
                
                Form {
                    // --- Name Editing Section ---
                    if isEditingText {
                        HStack {
                            Text("Name:")
                                .font(.title3)
                                .foregroundColor(Styles.Colors.accentColor)
                            
                            TextField("Enter Name", text: $name)
                                .focused($isTextFieldFocused)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .font(.title3)
                                .foregroundColor(Styles.Colors.thirdColor)
                        } .listRowBackground(Styles.Colors.secondaryColor)
                        
                    } else {
                        Text("Name: " + name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .font(.title3)
                            .foregroundColor(Styles.Colors.accentColor)
                            .listRowBackground(Styles.Colors.secondaryColor)
                            .onTapGesture {
                                isEditingText = true
                                isTextFieldFocused = true
                            }
                    }
                    
                    // --- Fridge Editing Section ---
                    if isEditingText {
                        HStack {
                            Text("Fridge:")
                                .font(.title3)
                                .foregroundColor(Styles.Colors.accentColor)
                            
                            TextField("Fridge Name", text: $fridgeType)
                                .focused($isTextFieldFocused)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .font(.title3)
                                .foregroundColor(Styles.Colors.thirdColor)
                        } .listRowBackground(Styles.Colors.secondaryColor)
                        
                    } else {
                        Text("Fridge: " + fridgeType)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .font(.title3)
                            .foregroundColor(Styles.Colors.accentColor)
                            .listRowBackground(Styles.Colors.secondaryColor)
                            .onTapGesture {
                                isEditingText = true
                                isTextFieldFocused = true
                            }
                    }
                    
                    Button (isEditingText ? "Done" : "Edit") {
                        isEditingText.toggle()
                        if !isEditingText {
                            isTextFieldFocused = false
                        }
                    }
                    .listRowBackground(Styles.Colors.secondaryColor)

                    // --- Dietary Restrictions Section ---
                    Section(header: Text("Dietary Restrictions")
                        .foregroundColor(Styles.Colors.accentColor))
                    {
                        HStack {
                            Text("Selected:")
                                .foregroundStyle(Styles.Colors.accentColor)
                                .font(.title3)

                            if isEditingRestrictions {
                                Picker("Restriction", selection: $selectedOption) {
                                    ForEach(Styles.Constants.dietaryRestrictions, id: \.self){
                                        option in
                                        Text(option)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxHeight: 90)
                                .clipped()
                                .foregroundColor(Styles.Colors.thirdColor)

                            } else {
                                Text(selectedOption)
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.accentColor)
                                    .onTapGesture {
                                        isEditingRestrictions = true
                                        isEditingText = false
                                        isTextFieldFocused = false
                                    }
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)

                        Button (isEditingRestrictions ? "Done" : "Edit") {
                            isEditingRestrictions.toggle()
                            if isEditingRestrictions {
                                isTextFieldFocused = false
                                isEditingText = false
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                    }

                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                        }
                    }
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview {
    ProfileView()
}
