//
//  ImageViewController.swift
//  HealthyLuncher
//
//  Created by Anna on 19/10/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import UIKit
import CoreML

class ImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var predictionView: UIView!
    @IBOutlet weak var retrainModelButton: UIButton!
    
    /// Service for classification of images.
    private let classificationService = ImageClassificationService()
    
    private lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        return picker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        retrainModelButton.isHidden = true
//        classificationService.completionHandler = { [weak self] prediction in
//            DispatchQueue.main.async {
//                self?.retrainModelButton.isHidden = false
//                self?.updatePredictionLabel(with: prediction)
//            }
//        }
    }
    
    @IBAction func openPhoto(_ sender: Any) {
        present(imagePickerController, animated: true)
    }

    @IBAction func retrainModel(_ sender: Any) {
        predictionLabel.text = "Retraining..."
        var featureProviders = [MLFeatureProvider]()

         let inputName = "image"
         let outputName = "label"
        let imageConstraint = UpdatableLunchImageClassifier().imageConstraint

        let imageFeatureValue = try? MLFeatureValue(cgImage: imageView.image!.cgImage!,
                                                    constraint: imageConstraint)
        let inputValue = imageFeatureValue
        let outputValue = MLFeatureValue(string: "healthy")

        let dataPointFeatures: [String: MLFeatureValue] = [inputName: inputValue!,
                                                            outputName: outputValue]

         if let provider = try? MLDictionaryFeatureProvider(dictionary: dataPointFeatures) {
             featureProviders.append(provider)
         }

        let traininData = MLArrayBatchProvider(array: featureProviders)
        classificationService.update(with: traininData) { [weak self] in
            self?.predictionLabel.text = "Finished retraining"
        }
    }
    

    func updatePredictionLabel(with prediction: Prediction) {
        predictionLabel.text = prediction.description
        predictionLabel.textColor = prediction.color
    }
}

extension ImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        imageView.image = image
        predictionLabel.text = "Classifying..."
        predictionLabel.textColor = .darkGray
        retrainModelButton.isHidden = true
        let label = classificationService.predict(for: image)
        retrainModelButton.isHidden = false
        updatePredictionLabel(with: Prediction(classLabel: label ?? "unknown") ?? Prediction.empty)
    }
}
