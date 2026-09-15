import AppKit
import EventKit
import Foundation

/// One reminder list exposed to the UI (SPEC §13.3).
struct ReminderList: Identifiable, Equatable {
    let id: String
    let title: String
}

/// One incomplete reminder.
struct ReminderTask: Identifiable, Equatable {
    let id: String
    let title: String
}

/// Access state of the Reminders database.
enum ReminderAccessStatus: Equatable {
    case notDetermined
    case denied
    case authorized
}

/// Single gateway to EventKit (SPEC §13.1, §29.3) — the UI never
/// touches EventKit directly. Reloads on database changes (debounced)
/// and on app activation; it never polls (SPEC §23). The picked list
/// is persisted so it survives relaunches (SPEC §24).
@MainActor
final class ReminderService: ObservableObject {
    static let shared = ReminderService()

    @Published private(set) var status: ReminderAccessStatus = .notDetermined
    @Published private(set) var lists: [ReminderList] = []
    @Published private(set) var tasks: [ReminderTask] = []
    /// Set when the last reload failed; the last good tasks stay
    /// visible (SPEC §22).
    @Published private(set) var loadError: String?
    @Published private(set) var selectedListID: String?
    /// True once the first authorized reload finished, so the UI can
    /// tell "loading" from "really nothing there".
    @Published private(set) var hasLoaded = false

    /// The user's pick, falling back to the first list.
    var resolvedList: ReminderList? {
        lists.first { $0.id == selectedListID } ?? lists.first
    }

    private let store = EKEventStore()
    private var changeToken: NSObjectProtocol?
    private var reloadTask: Task<Void, Never>?

    /// One-shot sink for fetchReminders' completion, which can fire
    /// more than once when the calendar source changes.
    private final class ReminderFetchBox: @unchecked Sendable {
        private let lock = NSLock()
        private var filled = false
        private var stored: [EKReminder] = []

        var isFilled: Bool { lock.withLock { filled } }

        func fill(_ value: [EKReminder]?) {
            lock.lock()
            defer { lock.unlock() }
            guard !filled else { return }
            filled = true
            stored = value ?? []
        }

        var value: [EKReminder] { lock.withLock { stored } }
    }

    private init() {
        status = Self.status(for: EKEventStore.authorizationStatus(for: .reminder))

        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification, object: nil
        )
        changeToken = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleReload() }
        }

        if status == .authorized {
            scheduleReload()
        }
    }

    deinit {
        if let changeToken {
            NotificationCenter.default.removeObserver(changeToken)
        }
        NotificationCenter.default.removeObserver(self)
    }

    /// Prompts the system permission dialog on first use (SPEC §13.2).
    func requestAccess() {
        Task {
            do {
                let granted = try await store.requestFullAccessToReminders()
                status = Self.status(for: EKEventStore.authorizationStatus(for: .reminder))
                if granted {
                    scheduleReload()
                }
            } catch {
                loadError = error.localizedDescription
            }
        }
    }

    /// Persists the picked list (SPEC §24) and reloads its tasks.
    /// nil resets to the first list.
    func selectList(_ id: String?) {
        selectedListID = id
        if let id {
            UserDefaults.standard.set(id, forKey: ConfigurationStore.todoListIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: ConfigurationStore.todoListIDKey)
        }
        scheduleReload()
    }

    func reloadNow() {
        scheduleReload()
    }

    // MARK: - Internals

    @objc private func applicationDidBecomeActive() {
        scheduleReload()
    }

    private func scheduleReload() {
        guard status == .authorized else { return }
        reloadTask?.cancel()
        reloadTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)  // merge change-notification bursts
            guard !Task.isCancelled else { return }
            await reload()
        }
    }

    private func reload() async {
        loadLists()
        await loadTasks()
        hasLoaded = true
    }

    private func loadLists() {
        if selectedListID == nil {
            selectedListID = UserDefaults.standard.string(forKey: ConfigurationStore.todoListIDKey)
        }
        lists = store.calendars(for: .reminder)
            .map { ReminderList(id: $0.calendarIdentifier, title: $0.title) }
            .sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
    }

    private func loadTasks() async {
        guard let list = resolvedList,
              let calendar = store.calendar(withIdentifier: list.id)
        else {
            tasks = []
            return
        }
        // fetchReminders' completion can hang or fire more than once,
        // so results go through a one-shot box with a polling timeout
        // instead of a continuation.
        let predicate = store.predicateForReminders(in: [calendar])
        let box = ReminderFetchBox()
        store.fetchReminders(matching: predicate) { box.fill($0) }

        let deadline = Date().addingTimeInterval(12)
        while !box.isFilled && Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if Task.isCancelled { return }
        }
        guard box.isFilled else {
            loadError = "加载提醒事项超时。"
            return
        }
        tasks = Array(
            box.value
                .filter { !$0.isCompleted }
                .sorted { lhs, rhs in
                    let lhsDue = lhs.dueDateComponents?.date ?? .distantFuture
                    let rhsDue = rhs.dueDateComponents?.date ?? .distantFuture
                    if lhsDue != rhsDue { return lhsDue < rhsDue }
                    return (lhs.title ?? "") < (rhs.title ?? "")
                }
                .prefix(100)
                .map { ReminderTask(id: $0.calendarItemIdentifier, title: $0.title ?? "无标题") }
        )
        loadError = nil
    }

    private static func status(for ekStatus: EKAuthorizationStatus) -> ReminderAccessStatus {
        switch ekStatus {
        case .authorized: return .authorized
        case .denied, .restricted: return .denied
        default: return .notDetermined
        }
    }
}
