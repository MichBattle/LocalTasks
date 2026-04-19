import SwiftUI

struct AuthScreen: View {
    @ObservedObject var authViewModel: AuthViewModel
    let onAuthSuccess: (String) -> Void

    @State private var isLoginMode = true

    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var city = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer(minLength: 50)

                        VStack(spacing: 10) {
                            Text("LocalTasks")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)

                            Text(isLoginMode ? "Welcome back" : "Create your account")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        modeSelector

                        VStack(spacing: 16) {
                            if !isLoginMode {
                                inputField("Username", text: $username)
                                inputField("City", text: $city)
                            }

                            inputField("Email", text: $email, keyboardType: .emailAddress)
                            secureInputField("Password", text: $password)
                        }

                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task {
                                if isLoginMode {
                                    await authViewModel.signIn(email: email, password: password)

                                    if authViewModel.isAuthenticated {
                                        onAuthSuccess("Login effettuato")
                                    }
                                } else {
                                    await authViewModel.signUp(
                                        email: email,
                                        password: password,
                                        username: username,
                                        city: city
                                    )

                                    if authViewModel.isAuthenticated {
                                        onAuthSuccess("Registrazione effettuata")
                                    }
                                }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.primaryLight, AppColors.primary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 56)

                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isLoginMode ? "Login" : "Create Account")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .disabled(authViewModel.isLoading)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 0) {
            Button {
                isLoginMode = true
                authViewModel.errorMessage = nil
            } label: {
                Text("Login")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isLoginMode ? .white : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(isLoginMode ? AppColors.primary : .clear)
            }

            Button {
                isLoginMode = false
                authViewModel.errorMessage = nil
            } label: {
                Text("Register")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(!isLoginMode ? .white : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(!isLoginMode ? AppColors.primary : .clear)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func inputField(
        _ title: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func secureInputField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
