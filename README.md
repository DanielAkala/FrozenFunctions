# FrozenFunctions

## Team 10:
### Daniel Akala
### Parker Oria
### Nathen Paniagua
FrozenFunctions is a lightweight iOS application that helps users manage their refridgerator contents, reduce food waste, and plan smarter meals.
FEATURES
*Add food items with name, quantity, and expiration date
*Receive local notification the day the item expires
*Expired, expiring soon, and default indicators
*Swipe to mark items as used*
*View meal ideas based on fridge contents
*Clean-out reminder when 3+ items are expired
*Core Data-powered offline storage (no Firebase or Cloudkit)

TECHNOLOGIES TO BE USED
*SWiftUI
*Declarative UI Core Data
*Local data storage UserNotifications
*XCode 26+, Swift 5.9+

PROJECT STRUCTURE
*ContentView.swift - Main dashboard with food items list
*AddItemView.swift - Add food UI + notificartion setup
*ShoppingListView.swift - Shopping cart screen
*Persistence.swift - Core Data stack setup
*FrozenFunctions.swift - App entry point + notification setup
*Recipe.swift - Static recipe data model

SETUP INSTRUCTIONS
Open FrozenFunctions.xcodeproj in XCode 
Select a development team under *Signing and Capabilities
Set deployment tartget to iOS 17 or above Build and run on simulator  
