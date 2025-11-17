import Foundation
import CoreData

struct RecipeService {
    
    let FIREBASE_FUNCTION_URL = "https://generaterecipes-oq5ojojfyq-uc.a.run.app"

    // Helper struct to match the API's top-level JSON structure
    struct RecipeResponse: Decodable {
        let recipes: [Recipe]
    }
    
    func fetchRecipes(for ingredients: [String], diet: String) async throws -> [Recipe] {
        guard let url = URL(string: FIREBASE_FUNCTION_URL) else {
            throw URLError(.badURL)
        }
        
        let requestBody: [String: Any] = [
            "ingredients": ingredients,
            "dietaryRestriction": diet
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverError = String(data: data, encoding: .utf8) ?? "Unknown server error"
            print("Server returned status \(httpResponse.statusCode): \(serverError)")
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(RecipeResponse.self, from: data)
        
        return apiResponse.recipes
    }
}
