import Combine
import Foundation

/// Presentation state for the todo card, covering every SPEC §13/§22
/// situation: permission prompt, denial, load failure, no lists,
/// an all-done list, and the task list itself.
enum TodoState: Equatable {
    case loading
    case needsPermission
    case accessDenied
    case unavailable(String)
    case noLists
    case empty(listTitle: String)
    case content(listTitle: String, tasks: [ReminderTask])
}

/// ReminderService → TodoViewModel → TodoWidget (SPEC §29.3): maps
/// service state into something the card can render directly.
@MainActor
final class TodoViewModel: ObservableObject {
    @Published private(set) var state: TodoState = .loading

    private let service: ReminderService
    private var cancellables: Set<AnyCancellable> = []

    init(service: ReminderService = .shared) {
        self.service = service

        // @Published sinks fire with the current value immediately,
        // so the state is computed on init without extra work. Each
        // change just recomputes the whole state (cheap, idempotent).
        func observe<P: Publisher>(_ publisher: P) -> AnyCancellable where P.Failure == Never {
            publisher.sink { [weak self] _ in self?.recompute() }
        }
        cancellables.insert(observe(service.$status))
        cancellables.insert(observe(service.$lists))
        cancellables.insert(observe(service.$tasks))
        cancellables.insert(observe(service.$loadError))
        cancellables.insert(observe(service.$selectedListID))
        cancellables.insert(observe(service.$hasLoaded))
    }

    func requestAccess() {
        service.requestAccess()
    }

    func reload() {
        service.reloadNow()
    }

    private func recompute() {
        switch service.status {
        case .notDetermined:
            state = .needsPermission
        case .denied:
            state = .accessDenied
        case .authorized:
            if let error = service.loadError, service.tasks.isEmpty {
                state = .unavailable(error)
            } else if !service.hasLoaded {
                state = .loading
            } else if service.lists.isEmpty {
                state = .noLists
            } else if let list = service.resolvedList {
                if service.tasks.isEmpty {
                    state = .empty(listTitle: list.title)
                } else {
                    state = .content(listTitle: list.title, tasks: service.tasks)
                }
            } else {
                state = .noLists
            }
        }
    }
}
