import Combine
import ComposableArchitecture
import XCTest

final class ViewStoreTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  override func setUp() {
    super.setUp()
    equalityChecks = 0
    subEqualityChecks = 0
  }

  func testPublisherFirehose() {
    let store = Store(
      initialState: 0,
      reducer: Reducer<Int, Void, Void>.empty,
      environment: ()
    )

    let viewStore = ViewStore(store)

    var emissionCount = 0
    viewStore.publisher
      .sink { _ in emissionCount += 1 }
      .store(in: &self.cancellables)

    XCTAssertEqual(emissionCount, 1)
    viewStore.send(())
    XCTAssertEqual(emissionCount, 1)
    viewStore.send(())
    XCTAssertEqual(emissionCount, 1)
    viewStore.send(())
    XCTAssertEqual(emissionCount, 1)
  }

  func testEqualityChecks() {
    let store = Store(
      initialState: State(),
      reducer: Reducer<State, Void, Void>.empty,
      environment: ()
    )

    let store1 = store.scope(state: { $0 })
    let store2 = store1.scope(state: { $0 })
    let store3 = store2.scope(state: { $0 })
    let store4 = store3.scope(state: { $0 })

    let viewStore1 = ViewStore(store1)
    let viewStore2 = ViewStore(store2)
    let viewStore3 = ViewStore(store3)
    let viewStore4 = ViewStore(store4)

    viewStore1.publisher.sink { _ in }.store(in: &self.cancellables)
    viewStore2.publisher.sink { _ in }.store(in: &self.cancellables)
    viewStore3.publisher.sink { _ in }.store(in: &self.cancellables)
    viewStore4.publisher.sink { _ in }.store(in: &self.cancellables)
    viewStore1.publisher.substate.sink { _ in }.store(in: &self.cancellables)
    viewStore2.publisher.substate.sink { _ in }.store(in: &self.cancellables)
    viewStore3.publisher.substate.sink { _ in }.store(in: &self.cancellables)
    viewStore4.publisher.substate.sink { _ in }.store(in: &self.cancellables)

    XCTAssertEqual(0, equalityChecks)
    XCTAssertEqual(0, subEqualityChecks)
    viewStore4.send(())
    XCTAssertEqual(42, equalityChecks)
    XCTAssertEqual(42, subEqualityChecks)
    viewStore4.send(())
    XCTAssertEqual(84, equalityChecks)
    XCTAssertEqual(84, subEqualityChecks)
    viewStore4.send(())
    XCTAssertEqual(126, equalityChecks)
    XCTAssertEqual(126, subEqualityChecks)
    viewStore4.send(())
    XCTAssertEqual(168, equalityChecks)
    XCTAssertEqual(168, subEqualityChecks)
  }
}

private struct State: Equatable {
  var substate = Substate()

  static func == (lhs: Self, rhs: Self) -> Bool {
    equalityChecks += 1
    return lhs.substate == rhs.substate
  }
}

private struct Substate: Equatable {
  var name = "Blob"

  static func == (lhs: Self, rhs: Self) -> Bool {
    subEqualityChecks += 1
    return lhs.name == rhs.name
  }
}

private var equalityChecks = 0
private var subEqualityChecks = 0
