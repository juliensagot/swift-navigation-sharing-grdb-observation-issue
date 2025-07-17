import IssueReporting
import Dependencies
import SharingGRDB
import UIKitNavigation
import Testing
@testable import UIKit_Observation_Issue

@MainActor
@Suite("ViewController Tests")
struct ViewControllerTests {
  @Test("observe closure is called when viewModel.count changes after buttonTapped")
  func testObserveClosureCalledOnCountChange() async throws {
    let _ = prepareDependencies {
      let db = try! DatabaseQueue()
      $0.defaultDatabase = db
      
      try! db.write { db in
        try db.create(table: "foo") { t in
          t.autoIncrementedPrimaryKey("id")
          t.column("letter", .text).notNull()
        }
        
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H"]
        for (index, letter) in letters.enumerated() {
          let count = (index + 1) * 10_000
          for _ in 0..<count {
            try Foo(id: nil, letter: letter).insert(db)
          }
        }
      }
    }
    
    let viewModel = ViewModel()
    
    let observedValue = LockIsolated(0)
    let observeClosureCallCount = LockIsolated(0)
    
    var observeToken: ObserveToken?
    
    // Set up observe closure to track count changes
    observeToken = observe {
      observedValue.withValue { $0 = viewModel.count }
      observeClosureCallCount.withValue { $0 += 1 }
    }
    
    // Wait for initial load
    try await Task.sleep(for: .milliseconds(100))
    
    // Trigger button tap repeatedly
    for _ in 0..<16 {
      viewModel.buttonTapped()
    }
    
    // Wait for async operation to complete
    try await Task.sleep(for: .milliseconds(200))
    
    #expect(observeClosureCallCount.value == 16)
    #expect(observedValue.value == 10_000, "observed value should reflect the new count for letter B")
    #expect(viewModel.count == 10_000)
    #expect(viewModel.selectedLetter == "A")
    
    observeToken = nil
  }
}
