import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
final class AuthManager: NSObject, ObservableObject {
    private enum StorageKey {
        static let currentUser = "sf.auth.currentUser"
        static let guestUserId = "sf.auth.guestUserId"
    }

    @Published var currentUser: AuthUser?

    override init() {
        super.init()
        ensureGuestUserId()
        loadCurrentUser()
    }

    var isLoggedIn: Bool {
        currentUser != nil
    }

    var activeStorageUserId: String {
        currentUser?.id ?? guestUserId
    }

    private var guestUserId: String {
        UserDefaults.standard.string(forKey: StorageKey.guestUserId) ?? "guest_local"
    }

    private func ensureGuestUserId() {
        if UserDefaults.standard.string(forKey: StorageKey.guestUserId) == nil {
            UserDefaults.standard.set("guest_local", forKey: StorageKey.guestUserId)
        }
    }

    func signOut() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: StorageKey.currentUser)
    }

    func saveCurrentUser(_ user: AuthUser) {
        currentUser = user
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: StorageKey.currentUser)
        }
    }

    private func loadCurrentUser() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.currentUser),
              let user = try? JSONDecoder().decode(AuthUser.self, from: data) else {
            return
        }
        currentUser = user
    }

    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            print("Apple 登录失败: \(error.localizedDescription)")
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                return
            }

            let fullName = [credential.fullName?.familyName, credential.fullName?.givenName]
                .compactMap { $0 }
                .joined()

            let user = AuthUser(
                id: credential.user,
                displayName: fullName.isEmpty ? nil : fullName,
                email: credential.email,
                provider: "apple"
            )

            saveCurrentUser(user)
        }
    }
}
