//
//  RegistrationViewController.swift
//  SvoiGram
//
//  Created by Никита Киселев on 03.03.2025.
//

import Foundation
import UIKit

class RegistrationViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var nicknameTextField: UITextField!
    
    @IBOutlet weak var firstnameTextField: UITextField!
    
    @IBOutlet weak var lastnameTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var registrationButton: UIButton!
    
    @IBOutlet weak var authorizationButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
        registrationButton.layer.cornerRadius = 10
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        modalPresentationStyle = .fullScreen
    }
    
    @IBAction func registrationButtonPressed(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let nickname = nicknameTextField.text, !nickname.isEmpty,
              let firstname = firstnameTextField.text, !firstname.isEmpty,
              let lastname = lastnameTextField.text, !lastname.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            print("Inputs cannot be empty.")
            // Display an alert to the user
            return
        }

        // Check if passwords match
        if passwordTextField.text != confirmPasswordTextField.text {
            // Display an alert
            let alert = UIAlertController(title: "Ошибка", message: "Пароли должны совпадать!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }

        // Construct the URL
        guard let url = URL(string: "http://localhost:8080/api/auth/signup") else {
            print("Invalid URL.")
            return
        }

        // Prepare the request body
        let requestBody: [String: Any] = [
            "email": email,
            "firstname": firstname,
            "lastname": lastname,
            "username": nickname,
            "password": password,
            "confirmPassword": confirmPassword
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize JSON data.")
            return
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
                // Update UI or perform actions based on the POST response
                DispatchQueue.main.async {
                    // Example: Display a success message
                    let alert = UIAlertController(title: "Регистрация", message: "Ваша регистрация прошла успешно!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                        self?.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)

                }
            }
        }

        task.resume()

    }
    
    
    @IBAction func authorizationButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
