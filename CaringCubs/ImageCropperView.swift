import SwiftUI

struct ImageCropperView: View {
    var image: UIImage
    var onCropped: (UIImage) -> Void
    var onCancel: () -> Void          // ← NEW: parent controls dismissal

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    let cropDiameter: CGFloat = 250

    var body: some View {
        VStack {
            Text("Adjust & Crop")
                .font(.headline)
                .padding()

            GeometryReader { geo in
                ZStack {
                    Color.black.opacity(0.9)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in scale = lastScale * value }
                                    .onEnded   { _     in lastScale = scale },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width:  lastOffset.width  + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in lastOffset = offset }
                            )
                        )

                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: cropDiameter, height: cropDiameter)
                }
            }

            HStack {
                Button("Cancel") {
                    onCancel()           // ← use callback, not dismiss()
                }
                .padding()

                Spacer()

                Button("Crop & Save") {
                    onCropped(cropImage())
                }
                .padding()
            }
        }
    }

    func cropImage() -> UIImage {
        // ✅ Step 1: Normalize orientation FIRST before any cropping
        let normalizedImage = normalizeOrientation(image)
        
        guard let cgImage = normalizedImage.cgImage else { return image }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let centerX  = imageSize.width  / 2 - offset.width  * (imageSize.width  / cropDiameter)
        let centerY  = imageSize.height / 2 - offset.height * (imageSize.height / cropDiameter)
        let cropSize = cropDiameter * (imageSize.width / cropDiameter) / scale
        let cropRect = CGRect(
            x: max(centerX - cropSize / 2, 0),
            y: max(centerY - cropSize / 2, 0),
            width:  min(cropSize, imageSize.width),
            height: min(cropSize, imageSize.height)
        ).integral

        if let croppedCG = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedCG)
        }
        return normalizedImage
    }

    // ✅ Redraws the image into a fresh context with correct orientation
    func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return normalized
    }
}
