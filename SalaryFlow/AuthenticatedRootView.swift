import SwiftUI

struct AuthenticatedRootView: View {
    let userId: String
    @StateObject private var vm: AppViewModel

    init(userId: String) {
        self.userId = userId
        _vm = StateObject(wrappedValue: AppViewModel(userId: userId))
    }

    var body: some View {
        ContentView()
            .environmentObject(vm)
    }
}
