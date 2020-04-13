//
//  UpdatableLunchImageClassifier+Extensions.swift
//  HealthyLuncher
//
//  Copyright © 2020 Netguru. All rights reserved.
//

import CoreML

extension UpdatableLunchImageClassifier {

    var imageConstraint: MLImageConstraint {
        return model.modelDescription.inputDescriptionsByName["image"]!.imageConstraint!
    }

    func predict(for value: MLFeatureValue) -> String? {
        guard let pixelBuffer = value.imageBufferValue else {
            fatalError("Could not extract CVPixelBuffer from the image feature value")
        }
        guard let prediction = try? prediction(image: pixelBuffer).label,
            prediction != "unknown" else {
                return nil
        }
        return prediction
    }
}
