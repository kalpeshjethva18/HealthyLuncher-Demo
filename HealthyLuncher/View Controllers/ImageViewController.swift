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
    @IBOutlet weak var resetModelButton: UIButton!

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
    }
    
    @IBAction func openPhoto(_ sender: Any) {
        present(imagePickerController, animated: true)
    }

    @IBAction func retrainModel(_ sender: Any) {
        predictionLabel.textColor = .darkGray
        predictionLabel.text = "Retraining..."
        
        classificationService.update(with: imageView.image!, for: "healthy") { [weak self] in
            self?.predictionLabel.text = "Finished retraining"
        }
    }

    @IBAction func resetModel(_ sender: Any) {
        classificationService.reset()
        let animation = CATransition()
        animation.duration = 0.2
        view.layer.add(animation, forKey: nil)
        imageView.image = nil
        predictionLabel.text = "Let's check if your lunch is healthy! 💪🏻🍎👇🏻"
        predictionLabel.textColor = .lightGray
        retrainModelButton.isHidden = true
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
