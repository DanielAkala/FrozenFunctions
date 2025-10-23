import SwiftUI
import UserNotifications
import CoreData

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name = "User"
    @State private var fridgeName = "Fridge"
    @State private var selectedOption: String = "None"
    @State private var isEditing = false
    @State private var isEditingText: Bool = false
    @State private var isEditingRestrictions: Bool = false
    
    @State private var tempName = ""
    @State private var tempFridgeName = ""
    
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
                                TextField("Fridge Name", text: $tempFridgeName)
                                    .focused($isTextFieldFocused)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .font(.title3)
                                    .foregroundColor(Styles.Colors.thirdColor)
                            } else {
                                Text(fridgeName)
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
                                tempFridgeName = fridgeName
                                isEditingText = false
                                isTextFieldFocused = false
                            }
                        }
                        
                        Button (isEditingText ? "Done" : "Edit") {
                            if isEditingText {
                                let trimmedName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                                let trimmedFridge = tempFridgeName.trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                if !trimmedName.isEmpty {
                                    name = trimmedName
                                }
                                if !trimmedFridge.isEmpty {
                                    fridgeName = trimmedFridge
                                }
                                
                                saveProfile()
                            } else {
                                tempName = name
                                tempFridgeName = fridgeName
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
                    Section {
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
                            if isEditingRestrictions {
                                saveProfile()
                            }
                            isEditingRestrictions.toggle()
                            if isEditingRestrictions {
                                isTextFieldFocused = false
                                isEditingText = false
                            }
                        }
                        .listRowBackground(Styles.Colors.secondaryColor)
                    }
                    header: {
                        Label("Dietary Restiction", systemImage: "fork.knife")
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
            .onAppear {
                loadProfile()
            }
        }
    }
    
    private func loadProfile() {
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        
        do {
            if let profile = try viewContext.fetch(fetchRequest).first {
                name = profile.userName ?? ""
                fridgeName = profile.fridgeName ?? ""
                selectedOption = profile.diet ?? "None"
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func saveProfile() {
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        
        do {
            let profiles = try viewContext.fetch(fetchRequest)
            let profile = profiles.first ?? Profile(context: viewContext)
            
            profile.userName = name
            profile.fridgeName = fridgeName
            profile.diet = selectedOption
            
            try viewContext.save()
            print("Profile saved successfully")
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

#Preview {
//    let context = PersistenceController.preview.container.viewContext
    ProfileView()
//        .environment(\.managedObjectContext, context)
}
