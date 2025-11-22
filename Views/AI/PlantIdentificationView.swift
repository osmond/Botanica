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
    @State private var isIdentifying = false
    @State private var identificationResult: PlantIdentificationResult?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingAISettings = false
    
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
                    // Header
                    headerSection
                    
                    // Error banner
                    if let errorMessage = errorMessage {
                        ErrorBanner(
                            title: "Identification Failed",
                            message: errorMessage,
                            actionLabel: "Try Again"
                        ) {
                            identifyPlant()
                        }
                    }
                    
                    // Image capture/display section
                    imageSection
                    
                    // Action buttons
                    actionButtonsSection
                    
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
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(BotanicaTheme.Colors.primary)
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
    
    private var headerSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(BotanicaTheme.Colors.primary)
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                Text("AI Plant Identification")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Take a photo or select from your library to identify your plant")
                    .font(BotanicaTheme.Typography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var imageSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            if let image = selectedImage {
                // Display selected image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BotanicaTheme.Colors.primary.opacity(0.2), lineWidth: 2)
                    )
                
                if isIdentifying {
                    HStack(spacing: BotanicaTheme.Spacing.sm) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: BotanicaTheme.Colors.primary))
                        
                        Text("Identifying plant...")
                            .font(BotanicaTheme.Typography.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(BotanicaTheme.Spacing.md)
                }
            } else {
                // Placeholder for image
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: BotanicaTheme.Spacing.md) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No image selected")
                                .font(BotanicaTheme.Typography.callout)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .padding(BotanicaTheme.Spacing.lg)
        .cardStyle()
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.md) {
            if selectedImage == nil {
                // Initial capture buttons
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Button(action: { showingCamera = true }) {
                        HStack(spacing: BotanicaTheme.Spacing.sm) {
                            Image(systemName: "camera.fill")
                            Text("Take Photo")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()
                    
                    Button(action: { showingPhotoPicker = true }) {
                        HStack(spacing: BotanicaTheme.Spacing.sm) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Library")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .secondaryButtonStyle()
                }
            } else {
                // Action buttons after image selected
                HStack(spacing: BotanicaTheme.Spacing.md) {
                    Button("Retake") {
                        selectedImage = nil
                        identificationResult = nil
                        errorMessage = nil
                        showingCamera = true
                    }
                    .secondaryButtonStyle()
                    
                    Button("Choose Different") {
                        selectedImage = nil
                        identificationResult = nil
                        errorMessage = nil
                        showingPhotoPicker = true
                    }
                    .secondaryButtonStyle()
                }
                
                if identificationResult == nil && !isIdentifying {
                    Button("Identify Again") {
                        identifyPlant()
                    }
                    .primaryButtonStyle()
                }
            }
        }
        .disabled(isIdentifying)
    }
    
    private func resultsSection(result: PlantIdentificationResult) -> some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Plant Identified!")
                    .font(BotanicaTheme.Typography.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(result.confidence * 100))% confident")
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, BotanicaTheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
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
                            .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
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
            isIdentifying = true
            errorMessage = nil // Clear previous errors
            
            do {
                let result = try await aiService.identifyPlant(image: image)
                await MainActor.run {
                    identificationResult = result
                    isIdentifying = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = ErrorMessageFormatter.userFriendlyMessage(for: error)
                    showingError = true
                    isIdentifying = false
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
                    .foregroundColor(.secondary)
                
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