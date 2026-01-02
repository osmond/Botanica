//
//  PlantIdentificationView.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import PhotosUI
import UIKit

/// View for capturing and identifying plants using AI
struct PlantIdentificationView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Variables
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var identificationResult: PlantIdentificationResult?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingAISettings = false
    @State private var loadState: LoadState = .idle
    
    // MARK: - Services
    @StateObject private var aiService = AIService.shared
    
    // MARK: - Completion Handler
    let onPlantIdentified: ((PlantIdentificationResult, UIImage) -> Void)?
    
    init(onPlantIdentified: ((PlantIdentificationResult, UIImage) -> Void)? = nil) {
        self.onPlantIdentified = onPlantIdentified
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BotanicaTheme.Spacing.xl) {
                    // Error banner
                if let errorMessage = errorMessage, case .failed = loadState {
                    ErrorBanner(
                        title: "Identification Failed",
                        message: errorMessage,
                        actionLabel: "Try Again"
                    ) {
                            identifyPlant()
                        }
                    }
                    
                    captureSection
                    
                    // Results section
                    if let result = identificationResult {
                        resultsSection(result: result)
                    }
                    
                    Spacer(minLength: BotanicaTheme.Spacing.xl)
                }
                .padding(.horizontal, BotanicaTheme.Spacing.lg)
                .padding(.vertical, BotanicaTheme.Spacing.md)
            }
            .navigationTitle("Plant Identification")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(BotanicaTheme.Typography.labelEmphasized)
                            .foregroundColor(BotanicaTheme.Colors.primary)
                    }
                }
                
                if identificationResult != nil, let image = selectedImage {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Use This Plant") {
                            if let result = identificationResult {
                                print("🌱 PlantIdentificationView: Use This Plant toolbar button tapped with result: \(result.commonName)")
                                onPlantIdentified?(result, image)
                            }
                            dismiss()
                        }
                        .foregroundColor(BotanicaTheme.Colors.primary)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                selectedImage = image
                identifyPlant()
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    identifyPlant()
                }
            }
        }
        .alert("Plant Identification Failed", isPresented: $showingError) {
            if let errorMessage = errorMessage, errorMessage.contains("API key") || errorMessage.contains("not configured") {
                Button("Configure API Key") {
                    showingAISettings = true
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("Try Again") {
                    if selectedImage != nil {
                        identifyPlant()
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .sheet(isPresented: $showingAISettings) {
            NavigationStack {
                AISettingsView()
                    .navigationTitle("AI Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingAISettings = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - View Components
    
    private var captureSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: BotanicaTheme.Sizing.iconLarge, weight: .semibold))
                    .foregroundColor(BotanicaTheme.Colors.primary)
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text("AI Plant Identification")
                        .font(BotanicaTheme.Typography.title3)
                        .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    Text("Take a photo or choose from your library to identify your plant.")
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                }
                Spacer()
            }

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BotanicaTheme.Colors.primary.opacity(0.2), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(BotanicaTheme.Colors.surfaceAlt)
                    .frame(height: 220)
                    .overlay(
                        VStack(spacing: BotanicaTheme.Spacing.sm) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: BotanicaTheme.Sizing.iconXL))
                                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                            Text("No photo selected")
                                .font(BotanicaTheme.Typography.callout)
                                .foregroundColor(BotanicaTheme.Colors.textSecondary)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BotanicaTheme.Colors.primary.opacity(0.15), lineWidth: 1)
                    )
            }

            if loadState == .loading {
                HStack(spacing: BotanicaTheme.Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: BotanicaTheme.Colors.primary))
                    Text("Identifying plant...")
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                }
            }

            if selectedImage == nil {
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    Button(action: { showingCamera = true }) {
                        HStack(spacing: BotanicaTheme.Spacing.xs) {
                            Image(systemName: "camera.fill")
                            Text("Take Photo")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()

                    Button(action: { showingPhotoPicker = true }) {
                        HStack(spacing: BotanicaTheme.Spacing.xs) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose Photo")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .secondaryButtonStyle()
                }
            } else {
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    Button("Retake") {
                        selectedImage = nil
                        identificationResult = nil
                        errorMessage = nil
                        loadState = .idle
                        showingCamera = true
                    }
                    .secondaryButtonStyle()

                    Button("Choose Different") {
                        selectedImage = nil
                        identificationResult = nil
                        errorMessage = nil
                        loadState = .idle
                        showingPhotoPicker = true
                    }
                    .secondaryButtonStyle()
                }

                if identificationResult == nil && loadState != .loading {
                    Button("Identify Plant") {
                        identifyPlant()
                    }
                    .primaryButtonStyle()
                }
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
        .disabled(loadState == .loading)
    }
    
    private func resultsSection(result: PlantIdentificationResult) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(BotanicaTheme.Colors.success)
                
                Text("Plant Identified!")
                    .font(BotanicaTheme.Typography.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(result.confidence * 100))% confident")
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    .padding(.horizontal, BotanicaTheme.Spacing.sm)
                    .padding(.vertical, BotanicaTheme.Spacing.xs)
                    .background(BotanicaTheme.Colors.success.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                ResultRow(
                    title: "Scientific Name",
                    value: result.scientificName,
                    icon: "leaf.fill"
                )
                
                ResultRow(
                    title: "Common Name",
                    value: result.commonName,
                    icon: "tag.fill"
                )
                
                if !result.description.isEmpty {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            
                            Text("Description")
                                .font(BotanicaTheme.Typography.callout)
                                .fontWeight(.medium)
                        }
                        
                        Text(result.description)
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    }
                }
                
                if !result.careInstructions.isEmpty {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            
                            Text("Care Instructions")
                                .font(BotanicaTheme.Typography.callout)
                                .fontWeight(.medium)
                        }
                        
                        Text(result.careInstructions)
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    }
                }
                
                // Use This Information Button
                if let image = selectedImage {
                    Button(action: {
                        print("🌱 PlantIdentificationView: Use This Information tapped with result: \(result.commonName), scientificName: \(result.scientificName)")
                        onPlantIdentified?(result, image)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                            Text("Use This Information")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BotanicaTheme.Colors.primary)
                        .cornerRadius(BotanicaTheme.CornerRadius.medium)
                    }
                    .padding(.top, BotanicaTheme.Spacing.md)
                }
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    // MARK: - Methods
    
    private func identifyPlant() {
        guard let image = selectedImage else { return }
        
        Task {
            loadState = .loading
            errorMessage = nil // Clear previous errors
            
            do {
                let result = try await aiService.identifyPlant(image: image)
                await MainActor.run {
                    identificationResult = result
                    loadState = .loaded
                }
            } catch {
                await MainActor.run {
                    errorMessage = ErrorMessageFormatter.userFriendlyMessage(for: error)
                    showingError = true
                    loadState = .failed(errorMessage ?? "Unknown error")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ResultRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(BotanicaTheme.Colors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                
                Text(value)
                    .font(BotanicaTheme.Typography.callout)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    PlantIdentificationView()
}
