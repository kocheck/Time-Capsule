import Foundation
import SwiftData

extension ModelContext {
    func safeSave() throws {
        if hasChanges {
            try save()
        }
    }

    func fetchFirst<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> T? {
        try fetch(descriptor).first
    }

    func fetchCount<T: PersistentModel>(_ type: T.Type) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        return try fetchCount(descriptor)
    }
}
