import SwiftUI
import UIKit

struct AsyncPlantThumbnail: View {
    let photo: Photo?
    var plant: Plant? = nil
    var size: CGFloat = 60
    var cornerRadius: CGFloat = BotanicaTheme.CornerRadius.small

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(BotanicaTheme.Colors.leafGreen.opacity(0.2))
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(BotanicaTheme.Colors.leafGreen)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: photo?.id ?? plant?.id) {
            if let photo {
                guard image == nil else { return }
                if let cached = await ThumbnailCache.shared.get(photo.id) {
                    image = cached
                    return
                }
                if let decoded = await ThumbnailDecode.decodeThumbnail(photo.imageData, maxDimension: size * 2) {
                    await ThumbnailCache.shared.set(decoded, for: photo.id)
                    image = decoded
                }
            } else if let plant,
                      image == nil,
                      plant.primaryPhoto == nil,
                      OpenAIConfig.shared.useAIReferenceImages,
                      OpenAIConfig.shared.isConfigured {
                let descriptor = PlantImageDescriptor(
                    id: plant.id,
                    displayName: plant.displayName,
                    scientificName: plant.scientificName,
                    commonNames: plant.commonNames
                )
                if let reference = await PlantImageService.shared.referenceImage(for: descriptor) {
                    await MainActor.run {
                        image = reference
                    }
                }
            }
        }
    }
}

// Fills available space with async-decoded image; container sets size/aspect.
struct AsyncPlantImageFill: View {
    let photo: Photo?
    var plant: Plant? = nil
    var cornerRadius: CGFloat = BotanicaTheme.CornerRadius.small
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(BotanicaTheme.Colors.leafGreen.opacity(0.08))
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(BotanicaTheme.Colors.leafGreen)
                            .opacity(0.6)
                    }
            }
        }
        .task(id: photo?.id ?? plant?.id) {
            if let photo {
                guard image == nil else { return }
                if let cached = await ThumbnailCache.shared.get(photo.id) {
                    image = cached
                    return
                }
                if let decoded = await ThumbnailDecode.decodeThumbnail(photo.imageData, maxDimension: 512) {
                    await ThumbnailCache.shared.set(decoded, for: photo.id)
                    image = decoded
                }
            } else if let plant,
                      image == nil,
                      plant.primaryPhoto == nil,
                      OpenAIConfig.shared.useAIReferenceImages,
                      OpenAIConfig.shared.isConfigured {
                let descriptor = PlantImageDescriptor(
                    id: plant.id,
                    displayName: plant.displayName,
                    scientificName: plant.scientificName,
                    commonNames: plant.commonNames
                )
                if let reference = await PlantImageService.shared.referenceImage(for: descriptor) {
                    await MainActor.run {
                        image = reference
                    }
                }
            }
        }
    }
}
