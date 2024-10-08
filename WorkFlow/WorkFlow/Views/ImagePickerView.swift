import SwiftUI
import PhotosUI

// ImagePicker is a SwiftUI wrapper for the UIKit PHPickerViewController
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage? // Binding to hold the selected image, updates the parent view when an image is selected

    // Creates the PHPickerViewController instance
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration() // Configuration for the picker
        config.filter = .images // Only allow image selection
        let picker = PHPickerViewController(configuration: config) // Initialize the picker with the configuration
        picker.delegate = context.coordinator // Set the delegate to handle user interactions
        return picker
    }

    // This function updates the PHPickerViewController when SwiftUI state changes, currently not used
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    // Creates the coordinator object to manage the picker’s interactions
    func makeCoordinator() -> Coordinator {
        Coordinator(self) // Pass the ImagePicker instance to the coordinator
    }

    // Coordinator class acts as a delegate for PHPickerViewController
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker // Reference to the parent ImagePicker instance

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        // This method is called when the user selects an image or cancels
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true) // Dismiss the picker once an image is selected or canceled

            // If the user selected an image, load it asynchronously
            if let result = results.first {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    // If the image is successfully loaded, update the selectedImage binding
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImage = image
                        }
                    }
                }
            }
        }
    }
}

