//
//  ImageClassificationService.swift
//  HealthyLuncher
//
//  Created by Anna on 23/10/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import UIKit
import CoreML

/// Service used for performing a classification of images by a ML model.
final class ImageClassificationService {

    private var currentModel: UpdatableLunchImageClassifier {
        updatedImageClassifier ?? defaultImageClassifier
    }

    private var imageConstraint: MLImageConstraint {
        currentModel.imageConstraint
    }

    private var updatedImageClassifier: UpdatableLunchImageClassifier?

    private let defaultImageClassifier = UpdatableLunchImageClassifier()

    private let fileManager = FileManager.default

    private var appDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory,
        in: .userDomainMask).first!
    }

    private let defaultModelURL = UpdatableLunchImageClassifier.urlOfModelInThisBundle

    private var updatedModelURL: URL {
        appDirectory.appendingPathComponent("personalized.mlmodelc")
    }
    private var tempUpdatedModelURL: URL {
        appDirectory.appendingPathComponent("personalized_tmp.mlmodelc")
    }

    private var hasMadeFirstPrediction = false

    private var updateTask: MLUpdateTask?

    /// Predict the result of image classification.
    ///
    /// - Parameter image: Image to classify.
    func predict(for image: UIImage) -> String? {
        guard let cgImage = image.cgImage,
            let featureValue = try? MLFeatureValue(cgImage: cgImage,
                                                   constraint: currentModel.imageConstraint,
                                                   options: nil) else { return "unknown" }
        return predict(for: featureValue)
    }

    /// Update the model with new results.
    ///
    /// - Parameters:
    ///     - image: Image for which make a retraining.
    ///     - label: Label for which to retrain the model.
    ///     - completionHandler: A completion to be called once finished ratraining.
    func update(with image: UIImage,
                for label: String,
                completionHandler: @escaping () -> Void) {
        var featureProviders = [MLFeatureProvider]()
        let inputName = "image"
        let outputName = "label"
        let imageConstraint = currentModel.imageConstraint

        let imageFeatureValue = try? MLFeatureValue(cgImage: image.cgImage!,
                                                    constraint: imageConstraint)
        let inputValue = imageFeatureValue
        let outputValue = MLFeatureValue(string: label)

        let dataPointFeatures: [String: MLFeatureValue] = [inputName: inputValue!,
                                                            outputName: outputValue]

         if let provider = try? MLDictionaryFeatureProvider(dictionary: dataPointFeatures) {
             featureProviders.append(provider)
         }

        let trainingData = MLArrayBatchProvider(array: featureProviders)
        update(with: trainingData, completionHandler: completionHandler)
    }

    /// Update the model with new results.
    ///
    /// - Parameters:
    ///     - trainingData: Data for which to retrain model.
    ///     - completionHandler: A completion to be called once finished ratraining.
    func update(with trainingData: MLBatchProvider,
                       completionHandler: @escaping () -> Void) {
        let usingUpdatedModel = updatedImageClassifier != nil
        let currentModelURL = usingUpdatedModel ? updatedModelURL : defaultModelURL
        let completionHandler = { [weak self] (updatedContext: MLUpdateContext) in
            self?.saveUpdatedModel(updatedContext)
            self?.loadUpdatedModel()
            self?.updateTask = nil
            DispatchQueue.main.async {
                completionHandler()
            }
        }
        let progressHandler = { (context: MLUpdateContext) in
            switch context.event {
            case .trainingBegin:
              print("Training begin")
            case .epochEnd:
              print("Epoch ended")
            default:
                print("Unknown event")
            }
        }

        let handlers = MLUpdateProgressHandlers(
            forEvents: [.trainingBegin, .epochEnd],
            progressHandler: progressHandler,
            completionHandler: completionHandler)

        print("Update started")

        let parameters: [MLParameterKey: Any] = [
           .epochs: 1,
           .miniBatchSize: 1,
         ]
         let config = MLModelConfiguration()
         config.computeUnits = .all
         config.parameters = parameters

        do {
            updateTask = try MLUpdateTask(forModelAt: currentModelURL,
                                               trainingData: trainingData,
                                               configuration: config,
                                               progressHandlers: handlers)
            updateTask?.resume()
        } catch {
            print("Update failed with error: \(error)")
        }

    }

    /// Reset a model to the initial state before updates.
    func reset() {
        updatedImageClassifier = nil
        if fileManager.fileExists(atPath: updatedModelURL.path) {
            try? FileManager.default.removeItem(at: updatedModelURL)
        }
    }

    // MARK: - Private methods

    private func predict(for value: MLFeatureValue) -> String? {
        if !hasMadeFirstPrediction {
            hasMadeFirstPrediction = true
            loadUpdatedModel()
        }
        return currentModel.predict(for: value)
    }

    private func saveUpdatedModel(_ updateContext: MLUpdateContext) {
        let updatedModel = updateContext.model
        do {
            try fileManager.createDirectory(at: tempUpdatedModelURL,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            try updatedModel.write(to: tempUpdatedModelURL)
            _ = try fileManager.replaceItemAt(updatedModelURL,
                                              withItemAt: tempUpdatedModelURL)
            print("Updated model saved to:\n\t\(updatedModelURL)")
        } catch let error {
            print("Could not save updated model to the file system: \(error)")
            return
        }
    }

    private func loadUpdatedModel() {
        guard fileManager.fileExists(atPath: updatedModelURL.path),
            let model = try? UpdatableLunchImageClassifier(contentsOf: updatedModelURL) else {
            return
        }
        updatedImageClassifier = model
    }
}
