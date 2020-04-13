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

    var currentModel: UpdatableLunchImageClassifier {
        updatedImageClassifier ?? defaultImageClassifier
    }

    var imageConstraint: MLImageConstraint {
        currentModel.imageConstraint
    }

    private var updatedImageClassifier: UpdatableLunchImageClassifier?

    private let defaultImageClassifier = UpdatableLunchImageClassifier()

    private let appDirectory = FileManager.default.urls(for: .applicationSupportDirectory,
    in: .userDomainMask).first!

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

    private func predict(for value: MLFeatureValue) -> String? {
        if !hasMadeFirstPrediction {
            hasMadeFirstPrediction = true

            // Load the updated model the app saved on an earlier run, if available.
            loadUpdatedModel()
        }
        return currentModel.predict(for: value)
    }

    func update(with trainingData: MLBatchProvider,
                       completionHandler: @escaping () -> Void) {
        let usingUpdatedModel = updatedImageClassifier != nil
        let currentModelURL = usingUpdatedModel ? updatedModelURL : defaultModelURL
        let completionHandler = { [weak self] (updatedContext: MLUpdateContext) in
            self?.saveUpdatedModel(updatedContext)
            self?.loadUpdatedModel()
            DispatchQueue.main.async {
                completionHandler()
            }
        }
        let progressHandler = { (context: MLUpdateContext) in
            switch context.event {
            case .trainingBegin:
              // This is the first event you receive, just before training actually
              // starts. At this point, context.metrics is empty.
              print("Training begin")

            case .miniBatchEnd:
              // This event is triggered after each mini-batch. You can get the
              // index of this batch and the training loss from context.metrics.
              let batchIndex = context.metrics[.miniBatchIndex] as! Int
              let batchLoss = context.metrics[.lossValue] as! Double
              print("Mini batch \(batchIndex), loss: \(batchLoss)")

            case .epochEnd:
              print("eposh ended")

            default:
                print("Unknown event")
            }
        }
        let handlers = MLUpdateProgressHandlers(
            forEvents: [.trainingBegin, .miniBatchEnd, .epochEnd],
            progressHandler: progressHandler,
            completionHandler: completionHandler)
        print("updating")
        let parameters: [MLParameterKey: Any] = [
           .epochs: 1,
           //.seed: 1234,
           .miniBatchSize: 1,
           //.shuffle: false,
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
            print(error)
        }

    }

    func reset() {
        // Clear the updated Drawing Classifier.
        updatedImageClassifier = nil

        // Remove the updated model from its designated path.
        if FileManager.default.fileExists(atPath: updatedModelURL.path) {
            try? FileManager.default.removeItem(at: updatedModelURL)
        }
    }

    private func saveUpdatedModel(_ updateContext: MLUpdateContext) {
        let updatedModel = updateContext.model
        let fileManager = FileManager.default
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
        guard FileManager.default.fileExists(atPath: updatedModelURL.path) else {
            return
        }

        guard let model = try? UpdatableLunchImageClassifier(contentsOf: updatedModelURL) else {
            return
        }
        updatedImageClassifier = model
    }
}
