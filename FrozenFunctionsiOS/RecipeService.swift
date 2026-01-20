import Foundation

struct Recipe: Identifiable, Codable {
    let id = UUID()
    let name: String
    let ingredients: [String]
    let instructions: String
    let prepTime: String?
    let difficulty: String?
    
    enum CodingKeys: String, CodingKey {
        case name, ingredients, instructions, prepTime, difficulty
    }
}

struct RecipeResponse: Codable {
    let recipes: [Recipe]
}

class RecipeService {
    private let firebaseFunctionURL = "https://generaterecipes-oq5ojojfyq-uc.a.run.app"
    
    func fetchRecipes(for ingredients: [String], diet: String) async throws -> [Recipe] {
        guard let url = URL(string: firebaseFunctionURL) else {
            throw RecipeServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "ingredients": ingredients,
            "dietaryRestriction": diet
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecipeServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw RecipeServiceError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let recipeResponse = try decoder.decode(RecipeResponse.self, from: data)
        
        return recipeResponse.recipes
    }
}

enum RecipeServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        }
    }
}
