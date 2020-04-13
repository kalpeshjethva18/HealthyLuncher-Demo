//
//  UpdatableLunchImageClassifier+Extensions.swift
//  HealthyLuncher
//
//  Copyright © 2020 Netguru. All rights reserved.
//

import CoreML

extension UpdatableLunchImageClassifier {

    /// The size and format constraints for an image feature.
    var imageConstraint: MLImageConstraint {
        return model.modelDescription.inputDescriptionsByName["image"]!.imageConstraint!
    }

    /// Predict the result of image classification.
    ///
    /// - Parameter value: Feature value to classify.
    func predict(for value: MLFeatureValue) -> String? {
        guard let pixelBuffer = value.imageBufferValue else {
            fatalError("Could not extract CVPixelBuffer from the image feature value")
        }
        guard let prediction = try? prediction(image: pixelBuffer),
            prediction.label != "unknown" else {
                return nil
        }
        print("Prediction: \(prediction.labelProbability)")
        return prediction.label
    }
}
