import Dependencies
import SharingGRDB
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let _ = prepareDependencies {
      let db = try! DatabaseQueue()
      $0.defaultDatabase = db
      
      try! db.write { db in
        try db.create(table: "foo") { t in
          t.autoIncrementedPrimaryKey("id")
          t.column("letter", .text).notNull()
        }
        
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H"]
        for letter in letters {
          let count = Int.random(in: 10_000...20_000)
          for _ in 0..<count {
            try Foo(id: nil, letter: letter).insert(db)
          }
        }
      }
    }
    
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }


}

