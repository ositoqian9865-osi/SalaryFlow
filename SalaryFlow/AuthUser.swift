import Foundation

struct AuthUser: Codable, Equatable {
    let id: String
    let displayName: String?
    let email: String?
    let provider: String
}
