import SharingGRDB
import SwiftUI
import UIKit
import UIKitNavigation

struct Foo: Codable, FetchableRecord, PersistableRecord {
  let id: Int64?
  let letter: String
  
  static let databaseTableName = "foo"
}

private struct CountFetchKeyRequest: FetchKeyRequest {
  let letter: String
  
  func fetch(_ db: Database) throws -> Int {
    return try Foo.filter(Column("letter") == letter).fetchCount(db)
  }
}

@Observable
final class ViewModel {
  @ObservationIgnored
  @SharedReader var count: Int
  var selectedLetter = "A"
  
  private var loadTask: Task<Void, Error>?
  
  init() {
    self._count = SharedReader(wrappedValue: 0, .fetch(CountFetchKeyRequest(letter: "A")))
  }
  
  func buttonTapped() {
    let letters = ["A", "B", "C", "D", "E", "F", "G", "H"]
    if let currentIndex = letters.firstIndex(of: selectedLetter) {
      let nextIndex = (currentIndex + 1) % letters.count
      selectedLetter = letters[nextIndex]
    }
    
    loadTask?.cancel()
    loadTask = Task {
      try await $count.load(.fetch(CountFetchKeyRequest(letter: selectedLetter)))
    }
  }
}

final class ViewController: UIViewController {
  private let viewModel = ViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let countLabel = UILabel()
    let letterLabel = UILabel()
    let button = UIButton(primaryAction: UIAction(title: "Update Letter") { [weak self] _ in
      self?.viewModel.buttonTapped()
    })
    
    let stackView = UIStackView(arrangedSubviews: [letterLabel, countLabel, button])
    stackView.axis = .vertical
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    view.addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
    
    observe { [weak self] in
      guard let self else { return }
      letterLabel.text = viewModel.selectedLetter
    }
    
    observe { [weak self] in
      guard let self else { return }
      countLabel.text = "\(viewModel.count)"
    }
  }
}

#Preview {
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
  
  ViewController()
}

