//
//  AppPostViewController.swift
//  SvoiGram
//
//  Created by Никита Киселев on 06.03.2025.
//

import Foundation
import UIKit

protocol UpdatePostTableDelegate: AnyObject {
    func updatePostTable()
}

class AddPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: UpdatePostTableDelegate?
    var postImageName: String = ""
    var postImageData: Data = Data(base64Encoded: "")!
    var userToken = getToken()
    
    @IBOutlet weak var postTitleTextField: UITextField!
    
    @IBOutlet weak var postDescriptionTextField: UITextField!
    
    @IBOutlet weak var postLocationTextField: UITextField!
    
    @IBOutlet weak var addImageButton: UIButton!
    
    @IBOutlet weak var imageNameLabel: UILabel!
    
    @IBOutlet weak var addPostButton: UIButton!
    
    @IBOutlet weak var exitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func addImageButtonPressed(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary // Choose photo library as source
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func addPostButtonPressed(_ sender: UIButton) {
        addPost(token: getToken())
    }
    
    func addPost(token: String) {
        guard let postTitle = postTitleTextField.text, !postTitle.isEmpty,
              let postDescription = postDescriptionTextField.text, !postDescription.isEmpty,
              let postLocation = postLocationTextField.text, !postLocation.isEmpty else {
            print("Inputs cannot be empty.")
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Ошибка", message: "Вы заполнили не все поля!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            return
        }

        // Construct the URL
        guard let url = URL(string: "http://localhost:8080/api/post") else {
            print("Invalid URL.")
            return
        }

        // Prepare the request body
        let requestBody: [String: Any] = [
            "title": postTitle,
            "caption": postDescription,
            "location": postLocation
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize JSON data.")
            return
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.setValue(token, forHTTPHeaderField: "Authorization")

        // Perform the POST request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error with POST request: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response from POST request!")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                return
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response from POST request: \(responseString)")
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        
                        guard let postId = json["id"] as? Int else {
                            return
                        }

                        DispatchQueue.main.async {
                            
                            if self.imageNameLabel.text != "No Image" {
                                self.addImageToPost(token: getToken(), postId: postId)
                            }
                            
                            let alert = UIAlertController(title: "Успешно!", message: "Ваш пост опубликован!", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                                self?.dismiss(animated: true, completion: nil)
                                self?.delegate?.updatePostTable()
                            }))
                            self.present(alert, animated: true, completion: nil)

                            self.clearForm()
                        }
                        
                    } else {
                        print("Could not parse JSON response.")
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }
        }

        task.resume()
    }
    
    
    func addImageToPost(token: String, postId: Int) {
        guard let url = URL(string: "http://localhost:8080/api/image/\(postId)/upload") else {
            print("Invalid URL.")
            return
        }

        // Prepare the request body
        let requestBody: [String: Any] = [
            "name": self.postImageName,
            "encoded_image": self.postImageData.base64EncodedString(options: .lineLength76Characters)
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize JSON data.")
            return
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.setValue(token, forHTTPHeaderField: "Authorization")

        // Perform the POST request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error with POST request: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response from POST request!")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                return
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response from POST request: \(responseString)")
            }
        }

        task.resume()
    }
    
    @IBAction func exitButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        if let image = info[.originalImage] as? UIImage,
           let imageName = info[.imageURL] as? URL { // Access the URL
            postImageName = imageName.lastPathComponent // Gets the name
            self.imageNameLabel.text = postImageName

            if let imageData = image.jpegData(compressionQuality: 1.0) {
                postImageData = imageData
                // postImageData теперь содержит строку Base64
            } else if let imageData = image.pngData() {
                postImageData = imageData
                // postImageData теперь содержит строку Base64
            } else {
                print("Не удалось преобразовать изображение в данные.")
            }

            print("Image Name: \(postImageName)")
//            print("Image Data: \(postImageData)")

        } else {
            print("Error: No image found or URL couldn't be accessed.")
            postImageName = "" // Reset the name if there's an issue.
            postImageData = Data(base64Encoded: "")! // Reset the data if there's an issue.

        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func clearForm() {
        self.postTitleTextField.text = ""
        self.postDescriptionTextField.text = ""
        self.postLocationTextField.text = ""
        self.imageNameLabel.text = "No image"
    }

}


class HalfScreenPresentationController: UIPresentationController {
    
    private var dimmingView: UIView!
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        setupDimmingView()
    }
    
    private func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmingView.alpha = 0
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        let height = containerView.bounds.height / 2
        let originY = containerView.bounds.height - height
        return CGRect(x: 0, y: originY, width: containerView.bounds.width, height: height)
    }
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView, let presentedView = presentedView else { return }
        
        setupDimmingView()
        containerView.addSubview(dimmingView)
        dimmingView.frame = containerView.bounds
        
        containerView.addSubview(presentedView)
        
        guard let coordinator = presentingViewController.transitionCoordinator else {
            dimmingView.alpha = 1
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        }, completion: nil)
    }
}
