import SwiftUI
import PhotosUI

struct CreateTaskView: View {
    @StateObject private var viewModel: CreateTaskViewModel
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImageDataList: [Data] = []

    init(viewModel: CreateTaskViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Group {
                            inputField("Title", text: $viewModel.title)

                            multiLineInput(
                                title: "Description",
                                text: $viewModel.description,
                                height: 130
                            )

                            categoryPicker

                            inputField("City", text: $viewModel.city)

                            multiLineInput(
                                title: "Full address (hidden until accepted)",
                                text: $viewModel.fullAddress,
                                height: 90
                            )

                            inputField("Price (optional)", text: $viewModel.priceText, keyboardType: .decimalPad)
                        }

                        photosSection

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
                                let created = await viewModel.createTask(imageDataList: selectedImageDataList)
                                if created {
                                    selectedPhotos = []
                                    selectedImageDataList = []
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
        .task(id: selectedPhotos) {
            await loadSelectedImages()
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

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Select photos")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if !selectedImageDataList.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedImageDataList.enumerated()), id: \.offset) { _, data in
                            if let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                    }
                }
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

    private func loadSelectedImages() async {
        selectedImageDataList = []

        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self) {
                selectedImageDataList.append(data)
            }
        }
    }
}
