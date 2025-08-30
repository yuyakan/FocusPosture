import SwiftUI

struct GraphView: View {
    private let repository: FocusSessionDataRepositoryProtocol

    init(
        repository: FocusSessionDataRepositoryProtocol
    ) {
        self.repository = repository
    }

    var body: some View {
        Text("")
    }
}

#Preview {
    GraphView(repository: FakeFocusSessionDataRepository())
}
