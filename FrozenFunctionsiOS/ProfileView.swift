import SwiftUI
import UserNotifications

struct ProfileView: View {
    @State private var name = "TestUser"
    @State private var fridgeType = "DefaultFridge"
    @State private var isEditing = false
    @State private var selectedOption: String = "None"
    @State private var isEditingText: Bool = false
    @State private var isEditingRestrictions: Bool = false
    
    @State private var tempName = ""
    @State private var tempFridgeType = ""
    
    @FocusState private var isTextFieldFocused: Bool
        
    var body: some View {
        NavigationView {
            ZStack {
                
                Styles.Colors.mainColor.ignoresSafeArea()
                
                Form {
                    Section {
                        // --- Name Editing Section ---
                        HStack(alignment: .center, spacing: 8) {
                            Label("Name:", systemImage: "person.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                                .font(.title3)
                                .frame(width: 120, alignment: .leading)
                            
                            if isEditingText {
                                TextField("Enter Name", text: $tempName)
                                    .focused($isTextFieldFocused)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.thirdColor)
                            } else {
                                Text(name)
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.accentColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: 44)
                        .listRowBackground(Styles.Colors.secondaryColor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isEditingText {
                                tempName = name
                                isEditingText = false
                                isTextFieldFocused = false
                            }
                        }
                        
                        // --- Fridge Editing Section ---
                        HStack(alignment: .center, spacing: 8) {
                            Label("Fridge:", systemImage: "snowflake")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                                .font(.title3)
                                .frame(width: 120, alignment: .leading)
                            
                            if isEditingText {
                                TextField("Fridge Name", text: $tempFridgeType)
                                    .focused($isTextFieldFocused)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.thirdColor)
                            } else {
                                Text(fridgeType)
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.accentColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: 44)
                        .listRowBackground(Styles.Colors.secondaryColor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isEditingText {
                                tempName = name
                                tempFridgeType = fridgeType
                                isEditingText = false
                                isTextFieldFocused = false
                            }
                        }
                        
                        Button (isEditingText ? "Done" : "Edit") {
                            if isEditingText {
                                // Save only if not empty, otherwise revert
                                let trimmedName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                                let trimmedFridge = tempFridgeType.trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                if !trimmedName.isEmpty {
                                    name = trimmedName
                                }
                                if !trimmedFridge.isEmpty {
                                    fridgeType = trimmedFridge
                                }
                            } else {
                                tempName = name
                                tempFridgeType = fridgeType
                            }
                            
                            isEditingText.toggle()
                            if !isEditingText {
                                isTextFieldFocused = false
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                    } header: {
                        Label("Personal Information", systemImage: "person.text.rectangle.fill")
                    }

                    // --- Dietary Restrictions Section ---
                    Section(header: Text("Dietary Restrictions")
                        .foregroundColor(Styles.Colors.accentColor))
                    {
                        HStack(alignment: .center, spacing: 8) {
                            Label("Selected:", systemImage: "leaf.circle.fill")
                                .foregroundStyle(Styles.Colors.accentColor, Styles.Colors.iconColor)
                                .font(.title3)

                            if isEditingRestrictions {
                                Picker("Restriction", selection: $selectedOption) {
                                    ForEach(Styles.Constants.dietaryRestrictions, id: \.self) { option in
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
                                        isEditingRestrictions = false
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
                }
                .scrollContentBackground(.hidden)
                .colorScheme(.dark)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Styles.Colors.mainColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    ProfileView()
}
