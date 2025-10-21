import SwiftUI

struct Styles {
    // use #colorLiteral inside Color()
    struct Colors {
        static let mainColor = Color(#colorLiteral(red: 0.076, green: 0.153, blue: 0.278, alpha: 1))
        static let secondaryColor = Color(#colorLiteral(red: 0.203, green: 0.243, blue: 0.388, alpha: 1))
        static let accentColor = Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        static let thirdColor = Color(#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1))
        static let iconColor = Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
    }


    struct Fonts {
        static let headingFont = Font.system(size: 24, weight:.bold)
        static let bodyFont = Font.system(size: 16, weight:.regular)
    }
    
    struct PrimaryButtonStyle: ViewModifier {
        func body(content: Content) -> some View {
            content.background(Styles.Colors.mainColor).foregroundColor(.white).cornerRadius(8).font(Styles.Fonts.headingFont)
        }
    }
    
    struct Constants {
        static let dietaryRestrictions = [
            "None",
            "Vegan",
            "Vegetarian",
            "Pescatarian",
            "Peanut Allergy",
            "Lactose Intolerance"
        ]
    }
    
}

extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(Styles.PrimaryButtonStyle())
    }
}

