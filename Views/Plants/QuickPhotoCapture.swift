//
//  QuickPhotoCapture.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import SwiftData
import PhotosUI

struct QuickPhotoCapture: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var plants: [Plant]
    
    @State private var selectedPlant: Plant?
    @State private var showingCamera = false
    @State private var showingPhotosPicker = false
    @State private var capturedImage: UIImage?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedCategory: PhotoCategory = .general
    @State private var caption = ""
    @State private var showingPlantPicker = false
    @State private var loadState: LoadState = .idle
    @State private var errorMessage: String?
    
    @StateObject private var cameraPermission = CameraPermissionManager()
    
    var body: some View {
        NavigationView {
            VStack {
                if plants.isEmpty {
                    emptyPlantsView
                } else {
                    photoFormView
                }
            }
            .navigationTitle("Quick Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if selectedPlant != nil && capturedImage != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            savePhoto()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraCapture(capturedImage: $capturedImage, isPresented: $showingCamera)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedPhotoItems, maxSelectionCount: 1, matching: .images)
        .sheet(isPresented: $showingPlantPicker) {
            PlantPickerView(selectedPlant: $selectedPlant, plants: plants)
        }
        .onChange(of: selectedPhotoItems) { oldValue, newValue in
            Task {
                await loadSelectedPhoto()
            }
        }
        .overlay(alignment: .bottom) {
            if loadState == .loading {
                HStack(spacing: BotanicaTheme.Spacing.sm) {
                    ProgressView()
                    Text("Saving photo…")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, BotanicaTheme.Spacing.md)
            }
        }
        .alert("Photo Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }
    
    // MARK: - Empty Plants View
    
    private var emptyPlantsView: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundColor(BotanicaTheme.Colors.primary.opacity(0.6))
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                Text("No Plants Yet")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Add some plants to your collection first, then you can start capturing their photos.")
                    .font(BotanicaTheme.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(BotanicaTheme.Spacing.xl)
    }
    
    // MARK: - Photo Form View
    
    private var photoFormView: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            // Plant selection
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                Text("Select Plant")
                    .font(BotanicaTheme.Typography.headline)
                    .foregroundColor(.primary)
                
                Button {
                    showingPlantPicker = true
                } label: {
                    HStack {
                        if let plant = selectedPlant {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(BotanicaTheme.Colors.leafGreen)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plant.displayName)
                                    .font(BotanicaTheme.Typography.body)
                                    .foregroundColor(.primary)
                                
                                if !plant.scientificName.isEmpty {
                                    Text(plant.scientificName)
                                        .font(BotanicaTheme.Typography.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                        } else {
                            Image(systemName: "plus.circle")
                                .foregroundColor(BotanicaTheme.Colors.primary)
                            Text("Choose Plant")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(BotanicaTheme.Colors.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(BotanicaTheme.Spacing.md)
                    .background(BotanicaTheme.Colors.surface)
                    .cornerRadius(BotanicaTheme.CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(selectedPlant?.displayName ?? "Choose Plant")
                .accessibilityHint("Select which plant this photo belongs to")
            }
            
            // Photo capture
            if selectedPlant != nil {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Take Photo")
                        .font(BotanicaTheme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    if let image = capturedImage {
                        // Photo preview
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(BotanicaTheme.CornerRadius.medium)
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    capturedImage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(Circle().fill(.black.opacity(0.6)))
                                }
                                .padding(8)
                            }
                    } else {
                        // Photo options
                        VStack(spacing: BotanicaTheme.Spacing.md) {
                            Button {
                                if cameraPermission.hasPermission {
                                    showingCamera = true
                                } else if cameraPermission.canRequestPermission {
                                    Task {
                                        let granted = await cameraPermission.requestPermission()
                                        if granted {
                                            await MainActor.run {
                                                showingCamera = true
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(BotanicaTheme.Colors.primary)
                                    Text("Take Photo")
                                        .font(BotanicaTheme.Typography.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(BotanicaTheme.Spacing.md)
                                .background(BotanicaTheme.Colors.surface)
                                .cornerRadius(BotanicaTheme.CornerRadius.medium)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                showingPhotosPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .foregroundColor(BotanicaTheme.Colors.leafGreen)
                                    Text("Choose from Library")
                                        .font(BotanicaTheme.Typography.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(BotanicaTheme.Spacing.md)
                                .background(BotanicaTheme.Colors.surface)
                                .cornerRadius(BotanicaTheme.CornerRadius.medium)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Photo details (only show if we have both plant and image)
            if selectedPlant != nil && capturedImage != nil {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Photo Details")
                        .font(BotanicaTheme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: BotanicaTheme.Spacing.md) {
                        // Category picker
                        HStack {
                            Text("Category")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(PhotoCategory.allCases, id: \.self) { category in
                                    HStack {
                                        Image(systemName: category.icon)
                                        Text(category.rawValue)
                                    }
                                    .tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Caption field
                        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                            Text("Caption (Optional)")
                                .font(BotanicaTheme.Typography.body)
                                .foregroundColor(.primary)
                            
                            TextField("Add a caption...", text: $caption, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                        }
                    }
                    .padding(BotanicaTheme.Spacing.md)
                    .background(BotanicaTheme.Colors.surface)
                    .cornerRadius(BotanicaTheme.CornerRadius.medium)
                }
            }
            
            Spacer()
        }
        .padding(BotanicaTheme.Spacing.md)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func loadSelectedPhoto() async {
        if let item = selectedPhotoItems.first,
           let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            capturedImage = image
        }
        selectedPhotoItems.removeAll()
    }
    
    private func savePhoto() {
        guard let plant = selectedPlant,
              let image = capturedImage,
              let imageData = ImageProcessor.normalizedJPEGData(from: image) else { return }
        loadState = .loading
        
        plant.addPhoto(
            from: imageData,
            caption: caption.isEmpty ? "" : caption,
            category: selectedCategory,
            isPrimary: nil
        )

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
        loadState = .loaded
    }
}

// MARK: - Plant Picker View

struct PlantPickerView: View {
    @Binding var selectedPlant: Plant?
    let plants: [Plant]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(plants) { plant in
                Button {
                    selectedPlant = plant
                    dismiss()
                } label: {
                    HStack {
                        AsyncPlantThumbnail(photo: plant.primaryPhoto, plant: plant, size: 50, cornerRadius: 25)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plant.displayName)
                                .font(BotanicaTheme.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            if !plant.scientificName.isEmpty {
                                Text(plant.scientificName)
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        
                        Spacer()
                        
                        if selectedPlant?.id == plant.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(BotanicaTheme.Colors.primary)
                        }
                    }
                    .padding(.vertical, BotanicaTheme.Spacing.xs)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, configurations: config)
    let context = container.mainContext
    let plants = MockDataGenerator.shared.createSamplePlants()
    for plant in plants {
        context.insert(plant)
    }
    QuickPhotoCapture()
        .modelContainer(container)
}
#endif
