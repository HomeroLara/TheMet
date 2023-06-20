
import Foundation
import SwiftUI
import Combine

class TheMetStore: ObservableObject {
  @Published var objects: [Object] = []
  let service = TheMetService()
  let maxIndex: Int
  
  init(_ maxIndex: Int = 30) {
    self.maxIndex = maxIndex
  }
  
  @MainActor
  func fetchObjects(for queryTerm: String) async throws {
    guard let objectIDs = try await service.getObjectIDs(from: queryTerm) else {
      return
    }
    
    let stream = getResultsStream(for: objectIDs.objectIDs)
    for try await object in stream {
      if let object = object {
        objects.append(object)
      }
    }
  }
  
  private func getResultsStream(for objectIDs: [Int]) -> AsyncStream<Object?> {
    AsyncStream { continuation in
      Task {
        for (index, objectID) in objectIDs.enumerated() where index < self.maxIndex {
          do {
            let object = try await self.service.getObject(from: objectID)
            continuation.yield(object)
          } catch {
            continuation.finish()
          }
        }
      }
    }
  }
}

