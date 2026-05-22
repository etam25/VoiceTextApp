import Vision
import UIKit
import SwiftUI
import Combine

class OCRViewModel: ObservableObject {
    @Published var recognizedText = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?

    func recognizeText(from image: UIImage) {
        isProcessing = true
        recognizedText = ""
        errorMessage = nil

        guard let cgImage = image.cgImage else {
            isProcessing = false
            errorMessage = "Failed to process image"
            return
        }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isProcessing = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                if text.isEmpty {
                    self?.errorMessage = "No text detected in image"
                } else {
                    self?.recognizedText = text
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isProcessing = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
