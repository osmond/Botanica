//
//  PhotoManager.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import SwiftData
import PhotosUI

struct PhotoManager: View {
    let plant: Plant
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingCamera = false
    @State private var showingPhotosPicker = false
    @State private var showingAddPhotoSheet = false
    @State private var capturedImage: UIImage?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var loadState: LoadState = .idle
    @State private var errorMessage: String?
    
    @StateObject private var cameraPermission = CameraPermissionManager()
    
    private var sortedPhotos: [Photo] {
        plant.photos.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: BotanicaTheme.Spacing.md) {
                    if sortedPhotos.isEmpty {
                        emptyStateView
                    } else {
                        photosGridView
                    }
                }
                .padding(BotanicaTheme.Spacing.md)
            }
            .navigationTitle("Plant Photos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPhotoSheet = true
                        HapticManager.shared.light()
                    } label: {
                        Label("Add Photo", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPhotoSheet) {
            addPhotoActionSheet
        }
        .sheet(isPresented: $showingCamera) {
            CameraCapture(capturedImage: $capturedImage, isPresented: $showingCamera)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedPhotoItems, maxSelectionCount: 5, matching: .images)
        .onChange(of: capturedImage) { oldValue, newValue in
            if let image = newValue {
                Task { await savePhoto(image: image, category: .general) }
                capturedImage = nil
            }
        }
        .onChange(of: selectedPhotoItems) { oldValue, newValue in
            Task {
                await loadSelectedPhotos()
            }
        }
        .overlay(alignment: .bottom) {
            if loadState == .loading {
                HStack(spacing: BotanicaTheme.Spacing.sm) {
                    ProgressView()
                    Text("Saving photos…")
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
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(BotanicaTheme.Colors.primary.opacity(0.6))
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                Text("No Photos Yet")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Start capturing beautiful moments of \(plant.displayName)'s growth journey.")
                    .font(BotanicaTheme.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddPhotoSheet = true
                HapticManager.shared.light()
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Add First Photo")
                }
                .font(BotanicaTheme.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, BotanicaTheme.Spacing.lg)
                .padding(.vertical, BotanicaTheme.Spacing.md)
                .background(BotanicaTheme.Colors.primary)
                .cornerRadius(BotanicaTheme.CornerRadius.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(BotanicaTheme.Spacing.xl)
    }
    
    // MARK: - Photos Grid
    
    private var photosGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: BotanicaTheme.Spacing.md) {
            ForEach(sortedPhotos) { photo in
                PhotoGridItem(photo: photo, plant: plant)
            }
        }
    }
    
    // MARK: - Add Photo Action Sheet
    
    private var addPhotoActionSheet: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, BotanicaTheme.Spacing.sm)
            
            VStack(spacing: BotanicaTheme.Spacing.lg) {
                Text("Add Photo")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, BotanicaTheme.Spacing.lg)
                
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    // Camera option
                    PhotoSourceButton(
                        title: "Take Photo",
                        subtitle: "Use camera to capture a new photo",
                        icon: "camera.fill",
                        color: BotanicaTheme.Colors.primary
                    ) {
                        showingAddPhotoSheet = false
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
                    }
                    
                    // Photo Library option
                    PhotoSourceButton(
                        title: "Choose from Library",
                        subtitle: "Select existing photos from your library",
                        icon: "photo.on.rectangle",
                        color: BotanicaTheme.Colors.leafGreen
                    ) {
                        showingAddPhotoSheet = false
                        showingPhotosPicker = true
                    }
                }
                
                Button("Cancel") {
                    showingAddPhotoSheet = false
                }
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(.secondary)
                .padding(.top, BotanicaTheme.Spacing.md)
            }
            .padding(BotanicaTheme.Spacing.xl)
            
            Spacer()
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Helper Methods
    
    private func savePhoto(image: UIImage, category: PhotoCategory) async {
        // Normalize image data for consistency/caching
        guard let imageData = ImageProcessor.normalizedJPEGData(from: image) else { return }
        loadState = .loading
        
        _ = plant.addPhoto(
            from: imageData,
            caption: "",
            category: category,
            isPrimary: nil
        )
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
        loadState = .loaded
    }
    
    @MainActor
    private func loadSelectedPhotos() async {
        loadState = .loading
        for item in selectedPhotoItems {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                errorMessage = "Unable to load photo from library."
                continue
            }
            // Decode using shared thumbnail decoder to match other components
            if let image = await ThumbnailDecode.decodeThumbnail(data, maxDimension: 1600) {
                await savePhoto(image: image, category: .general)
            }
        }
        selectedPhotoItems.removeAll()
        loadState = .loaded
    }
}

// MARK: - Photo Source Button

struct PhotoSourceButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text(title)
                        .font(BotanicaTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(BotanicaTheme.Spacing.md)
            .background(BotanicaTheme.Colors.surface)
            .cornerRadius(BotanicaTheme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Photo Grid Item

struct PhotoGridItem: View {
    let photo: Photo
    let plant: Plant
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingPhotoDetail = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button {
            showingPhotoDetail = true
            HapticManager.shared.light()
        } label: {
            ZStack(alignment: .topTrailing) {
                AsyncPlantImageFill(photo: photo, cornerRadius: BotanicaTheme.CornerRadius.medium)
                    .frame(height: 180)
                
                // Primary badge
                if photo.isPrimary {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("Primary")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(8)
                }
                
                // Category badge
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: photo.category.icon)
                                .font(.caption)
                            Text(photo.category.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.7))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPhotoDetail) {
            PhotoDetailView(photo: photo, plant: plant)
        }
    }
}

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, configurations: config)
    let context = container.mainContext
    let plant = MockDataGenerator.shared.createSamplePlants().first!
    context.insert(plant)
    PhotoManager(plant: plant)
        .modelContainer(container)
}
#endif
