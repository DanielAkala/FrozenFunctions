import SwiftUI

struct Styles {
    struct Colors {
        static let mainColor = Color(UIColor.init(red: 0.076, green: 0.153, blue: 0.278, alpha: 1))
        static let secondaryColor = Color(UIColor.init(red: 0.203, green: 0.243, blue: 0.388, alpha: 1))
        static let accentColor = Color(UIColor.white)
    }

    struct Fonts {
        static let headingFont = Font.system(size: 24, weight:.bold) // Use Font for SwiftUI
        static let bodyFont = Font.system(size: 16, weight:.regular)
    }
    
    // You can define reusable styles for buttons or views in SwiftUI differently. Use ViewModifiers or custom views.

    // Example of a reusable style with ViewModifier
    struct PrimaryButtonStyle: ViewModifier {
        func body(content: Content) -> some View {
            content.background(Styles.Colors.mainColor).foregroundColor(.white).cornerRadius(8).font(Styles.Fonts.headingFont)
        }
    }
}

extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(Styles.PrimaryButtonStyle())
    }
}

