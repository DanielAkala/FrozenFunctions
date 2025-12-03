import Foundation

class EmailService {
    static let shared = EmailService()
    
    // ✅ Your Firebase Cloud Function URL
    private let functionURL = "https://sendverificationcode-oq5ojojfyq-uc.a.run.app"
    // Update this URL after deploying! Get it from Firebase Console → Functions
    
    private init() {}
    
    /// Send verification code to email using Firebase Cloud Function
    func sendVerificationCode(to email: String, code: String) async throws -> String {
        guard let url = URL(string: functionURL) else {
            throw EmailServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "email": email
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmailServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Email Function Error: \(errorMessage)")
            throw EmailServiceError.sendFailed(statusCode: httpResponse.statusCode)
        }
        
        // Parse response to get the code
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let returnedCode = json["code"] as? String {
            print("✅ Verification code sent to \(email)")
            return returnedCode
        }
        
        throw EmailServiceError.invalidResponse
    }
    
    /// Generate 6-digit verification code
    func generateVerificationCode() -> String {
        return String(format: "%06d", Int.random(in: 100000...999999))
    }
}

enum EmailServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case sendFailed(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid email service URL"
        case .invalidResponse:
            return "Invalid response from email service"
        case .sendFailed(let code):
            return "Failed to send email (Status: \(code))"
        }
    }
}
