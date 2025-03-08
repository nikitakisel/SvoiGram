//
//  EditProfileViewController.swift
//  SvoiGram
//
//  Created by Никита Киселев on 08.03.2025.
//

import Foundation
import UIKit

protocol EditProfileDataDelegate: AnyObject {
    func updateUserData()
}

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: EditProfileDataDelegate?
    
    @IBOutlet weak var userNickNameLabel: UITextField!
    @IBOutlet weak var userFirstNameLabel: UITextField!
    @IBOutlet weak var userLastNameLabel: UITextField!
    @IBOutlet weak var userBioLabel: UITextField!
    
    @IBOutlet weak var updateUserDataButton: UIButton!
    @IBOutlet weak var quitButton: UIButton!
    
    
    @IBAction func updateUserDataButtonPressed(_ sender: UIButton) {
        self.updateUserData(token: getToken())
    }
    
    @IBAction func quitButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadProfileData(token: getToken())
        
    }
    
    func clearForm() {
        self.userNickNameLabel.text = ""
        self.userFirstNameLabel.text = ""
        self.userLastNameLabel.text = ""
        self.userBioLabel.text = ""
    }
    
    func loadProfileData(token: String) {
        guard let url = URL(string: "http://localhost:8080/api/user/") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization") // Set Authorization header
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Server error! StatusCode: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        
                        guard let userNickName = json["username"] as? String,
                              let userFirstName = json["firstname"] as? String,
                              let userLastName = json["lastname"] as? String else {
                            return
                        }

                        let userBio = json["bio"] as? String

                        DispatchQueue.main.async {
                            self.userNickNameLabel.text = userNickName
                            self.userFirstNameLabel.text = userFirstName
                            self.userLastNameLabel.text = userLastName
                            self.userBioLabel.text = userBio ?? ""
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
    
    func updateUserData(token: String) {
        guard let userNickName = userNickNameLabel.text, !userNickName.isEmpty,
              let userFirstName = userFirstNameLabel.text, !userFirstName.isEmpty,
              let userLastName = userLastNameLabel.text, !userLastName.isEmpty else {
            print("Inputs cannot be empty.")
            // Display an alert to the user
            return
        }
        
        let userBio = userBioLabel.text ?? ""

        // Construct the URL
        guard let url = URL(string: "http://localhost:8080/api/user") else {
            print("Invalid URL.")
            return
        }

        // Prepare the request body
        let requestBody: [String: Any] = [
            "firstname": userFirstName,
            "lastname": userLastName,
            "username": userNickName,
            "bio": userBio
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize JSON data.")
            return
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
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
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Успешно!", message: "Данные пользователя обновлены!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                        self?.dismiss(animated: true, completion: nil)
                        self?.delegate?.updateUserData()
                    }))
                    self.present(alert, animated: true, completion: nil)

                    self.clearForm()
                }
            }
        }

        task.resume()
    }
    
}
