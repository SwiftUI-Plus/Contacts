import SwiftUI
import Combine
import Contacts

internal final class GroupsObserver: NSObject, ObservableObject {
    @Published internal var results: [CNGroup] = []

    internal let store = CNContactStore()
    private let queue = DispatchQueue(label: "com.benkau.contacts-observer")
    private var cancellable: AnyCancellable?

    private let predicate: NSPredicate?
    private let animation: Animation?

    internal init(predicate: NSPredicate?, animation: Animation?) {
        self.predicate = predicate
        self.animation = animation
        super.init()

        self.cancellable = NotificationCenter.default
            .publisher(for: Notification.Name.CNContactStoreDidChange)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.refetch(animated: true)
            }

        refetch(animated: false)
    }

    private func refetch(animated: Bool) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var groups: [CNGroup] = []

            defer {
                DispatchQueue.main.async {
                    withAnimation(animated ? self.animation : nil) { self.results = groups }
                }
            }

            do {
                groups = try self.store.groups(matching: self.predicate)
            } catch {
                print(error)
            }
        }
    }
}
