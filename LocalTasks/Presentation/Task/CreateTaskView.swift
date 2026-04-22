import SwiftUI
import MapKit

struct CreateTaskView: View {
    @StateObject private var viewModel: CreateTaskViewModel
    @StateObject private var addressViewModel = AddressSearchViewModel()

    init(viewModel: CreateTaskViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        inputField("Title", text: $viewModel.title)

                        multiLineInput(
                            title: "Description",
                            text: $viewModel.description,
                            height: 130
                        )

                        categoryPicker

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Address")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)

                            disclaimerBox("It is recommended not to enter your home address when possible")

                            TextField(
                                "Start typing an existing street and pick a suggestion",
                                text: Binding(
                                    get: { addressViewModel.query },
                                    set: { addressViewModel.updateQuery($0) }
                                )
                            )
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            if let selected = addressViewModel.selectedAddress {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Selected: \(selected.fullAddress)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.green)

                                    Text("City: \(selected.cityName)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }

                            if !addressViewModel.completions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(addressViewModel.completions, id: \.self) { completion in
                                        Button {
                                            Task {
                                                await addressViewModel.selectCompletion(completion)
                                            }
                                        } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(completion.title)
                                                    .foregroundStyle(AppColors.textPrimary)
                                                    .frame(maxWidth: .infinity, alignment: .leading)

                                                if !completion.subtitle.isEmpty {
                                                    Text(completion.subtitle)
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(AppColors.textSecondary)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                            }
                                            .padding()
                                        }
                                        .buttonStyle(.plain)

                                        Divider()
                                    }
                                }
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Price")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)

                            disclaimerBox("Payments are handled as donations and are entirely between users")

                            TextField("Price (optional)", text: $viewModel.priceText)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        if let addressError = addressViewModel.errorMessage {
                            Text(addressError)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let successMessage = viewModel.successMessage {
                            Text(successMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task {
                                let created = await viewModel.createTask(
                                    address: addressViewModel.selectedAddress
                                )
                                if created {
                                    addressViewModel.query = ""
                                    addressViewModel.selectedAddress = nil
                                    addressViewModel.completions = []
                                    addressViewModel.errorMessage = nil
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

                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Task")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(20)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            Menu {
                ForEach(TaskCategory.allCases) { category in
                    Button(category.displayName) {
                        viewModel.selectedCategory = category
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedCategory.displayName)
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func inputField(
        _ title: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            TextField(title, text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func multiLineInput(
        title: String,
        text: Binding<String>,
        height: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            TextEditor(text: text)
                .frame(height: height)
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func disclaimerBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 14))

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
