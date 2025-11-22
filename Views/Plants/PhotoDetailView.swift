//
//  PhotoDetailView.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import SwiftData

struct PhotoDetailView: View {
    let photo: Photo
    let plant: Plant
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var caption: String
    @State private var selectedCategory: PhotoCategory
    @State private var isPrimary: Bool
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    init(photo: Photo, plant: Plant) {
        self.photo = photo
        self.plant = plant
        self._caption = State(initialValue: photo.caption)
        self._selectedCategory = State(initialValue: photo.category)
        self._isPrimary = State(initialValue: photo.isPrimary)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Photo
                        photoView(geometry: geometry)
                        
                        // Photo info
                        photoInfoSection
                    }
                }
            }
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button {
                            togglePrimary()
                        } label: {
                            Label(
                                photo.isPrimary ? "Remove as Primary" : "Set as Primary",
                                systemImage: photo.isPrimary ? "star.slash" : "star"
                            )
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Delete Photo", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePhoto()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPhotoSheet(
                caption: $caption,
                category: $selectedCategory,
                isPrimary: $isPrimary,
                availableCategories: PhotoCategory.allCases
            ) {
                saveChanges()
            }
        }
    }
    
    // MARK: - Photo View
    
    private func photoView(geometry: GeometryProxy) -> some View {
        ZStack {
            AsyncPlantImageFill(photo: photo, cornerRadius: 0)
                .frame(maxWidth: geometry.size.width)
                .frame(minHeight: 300, maxHeight: 500)
        }
        .background(Color.black)
    }
    
    // MARK: - Photo Info Section
    
    private var photoInfoSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.lg) {
            // Basic info
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                        Text("Taken")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                        Text(photo.timestamp.formatted(.dateTime.month().day().year().hour().minute()))
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: BotanicaTheme.Spacing.xs) {
                        Text("Category")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: photo.category.icon)
                                .font(.caption)
                            Text(photo.category.rawValue)
                                .font(BotanicaTheme.Typography.body)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                if photo.isPrimary {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(BotanicaTheme.Colors.nutrientOrange)
                        Text("Primary Photo")
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(BotanicaTheme.Colors.nutrientOrange)
                    }
                }
            }
            .padding(BotanicaTheme.Spacing.md)
            .background(BotanicaTheme.Colors.surface)
            .cornerRadius(BotanicaTheme.CornerRadius.medium)
            
            // Caption
            if !photo.caption.isEmpty {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("Caption")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text(photo.caption)
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.primary)
                }
                .padding(BotanicaTheme.Spacing.md)
                .background(BotanicaTheme.Colors.surface)
                .cornerRadius(BotanicaTheme.CornerRadius.medium)
            }
            
            // Plant info
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                Text("Plant")
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(BotanicaTheme.Colors.leafGreen)
                    
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
                }
            }
            .padding(BotanicaTheme.Spacing.md)
            .background(BotanicaTheme.Colors.surface)
            .cornerRadius(BotanicaTheme.CornerRadius.medium)
        }
        .padding(BotanicaTheme.Spacing.md)
    }
    
    // MARK: - Helper Methods
    
    private func togglePrimary() {
        // If setting as primary, remove primary from other photos
        if !photo.isPrimary {
            for otherPhoto in plant.photos {
                otherPhoto.isPrimary = false
            }
        }
        
        photo.isPrimary.toggle()
        isPrimary = photo.isPrimary
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            HapticManager.shared.error()
            print("Failed to update photo: \(error)")
        }
    }
    
    private func saveChanges() {
        photo.caption = caption
        photo.category = selectedCategory
        
        // Handle primary photo logic
        if isPrimary && !photo.isPrimary {
            // Setting this as primary, remove from others
            for otherPhoto in plant.photos {
                otherPhoto.isPrimary = false
            }
        }
        photo.isPrimary = isPrimary
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            showingEditSheet = false
        } catch {
            HapticManager.shared.error()
            print("Failed to save photo changes: \(error)")
        }
    }
    
    private func deletePhoto() {
        // If deleting primary photo, set another as primary
        if photo.isPrimary && plant.photos.count > 1 {
            if let nextPhoto = plant.photos.first(where: { $0.id != photo.id }) {
                nextPhoto.isPrimary = true
            }
        }
        
        plant.photos.removeAll { $0.id == photo.id }
        modelContext.delete(photo)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            HapticManager.shared.error()
            print("Failed to delete photo: \(error)")
        }
    }
}

// MARK: - Edit Photo Sheet

struct EditPhotoSheet: View {
    @Binding var caption: String
    @Binding var category: PhotoCategory
    @Binding var isPrimary: Bool
    let availableCategories: [PhotoCategory]
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Caption") {
                    TextField("Add a caption...", text: $caption, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(availableCategories, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Toggle("Set as Primary Photo", isOn: $isPrimary)
                } footer: {
                    Text("The primary photo is displayed in plant lists and as the main plant image.")
                }
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .fontWeight(.semibold)
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
    let plant = MockDataGenerator.shared.createSamplePlants().first!
    context.insert(plant)
    // Create a sample photo
    let sampleImageData = UIImage(systemName: "leaf.fill")?.pngData() ?? Data()
    let photo = Photo(
        imageData: sampleImageData,
        caption: "Beautiful new growth on my monstera!",
        category: .newGrowth,
        isPrimary: true
    )
    PhotoDetailView(photo: photo, plant: plant)
        .modelContainer(container)
}
#endif
