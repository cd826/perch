import Foundation

enum AsyncTimeoutError: Error, LocalizedError {
    case timedOut

    var errorDescription: String? {
        "请求超时"
    }
}

/// Bounds an async operation. The underlying work is cancelled when
/// the deadline passes, so a hung backend can never freeze a card
/// forever (SPEC §22).
func withTimeout<T: Sendable>(
    seconds: Double,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw AsyncTimeoutError.timedOut
        }
        guard let first = try await group.next() else {
            throw AsyncTimeoutError.timedOut
        }
        group.cancelAll()
        return first
    }
}
