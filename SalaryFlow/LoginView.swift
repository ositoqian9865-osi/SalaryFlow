import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            ClayBackground()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 10) {
                    Text("SalaryFlow")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("先登录，再把你的小金库、目标和复盘存到你的账号里")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                SignInWithAppleButton(
                    onRequest: { request in
                        authManager.handleAppleSignInRequest(request)
                    },
                    onCompletion: { result in
                        authManager.handleAppleSignInCompletion(result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 24)

                Text("后面我再帮你接微信、Google、QQ")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}
