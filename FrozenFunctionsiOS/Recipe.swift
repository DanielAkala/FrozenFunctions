import Foundation

struct Recipe: Identifiable, Codable {
    let id = UUID()
    let name: String
    let ingredients: [String]
    let instructions: String
    
    // NEW: Properties from the AI API
    let prepTime: String?
    let difficulty: String?

    // Ensure we only decode API properties
    enum CodingKeys: String, CodingKey {
        case name, ingredients, instructions, prepTime, difficulty
    }
}
