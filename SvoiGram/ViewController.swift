
//  ViewController.swift
//  SvoiGram
//
//  Created by Никита Киселев on 02.03.2025.



import UIKit


func saveJsonToFile(jsonObject: [String: Any], filename: String) {
    let filePath = "/Users/nikitakiselev/Documents/XCode Projects/SvoiGram/SvoiGram/\(filename).json"
    let fileURL = URL(fileURLWithPath: filePath)
    let fileURLString = fileURL.path

    let fileManager = FileManager.default

    // Check if the file exists and remove it
    if fileManager.fileExists(atPath: fileURLString) {
        do {
            try fileManager.removeItem(atPath: fileURLString)
            print("File \(fileURLString) removed successfully before writing new data.")
        } catch {
            print("Error removing file: \(error)")
            return // Exit the function if removing the file fails
        }
    }

    do {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        try data.write(to: fileURL)
        print("JSON успешно сохранен в: \(fileURL)")
    } catch {
        print("Ошибка сохранения JSON в файл: \(error)")
    }
}


func loadJsonFromFile(filename: String) -> [String: Any]? {
    let filePath = "/Users/nikitakiselev/Documents/XCode Projects/SvoiGram/SvoiGram/\(filename).json"
    let fileURL = URL(fileURLWithPath: filePath)

    do {
        let data = try Data(contentsOf: fileURL)
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return json
        } else {
            print("Не удалось преобразовать данные в JSON.")
            return nil
        }
    } catch {
        print("Ошибка загрузки JSON из файла: \(error)")
        return nil
    }
}


func getToken() -> String {
    if let json = loadJsonFromFile(filename: "UserToken") {
        if let token = json["token"] as? String {
            return "Bearer \(token)"
            // Now you can use the token
        } else {
            return "Token not found in JSON response"
        }
    } else {
        return "Could not parse JSON response"
    }
}


class ViewController: UIViewController {

    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var authorizationButton: UIButton!
    @IBOutlet weak var registrationButton: UIButton!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isSecureTextEntry = true
        authorizationButton.layer.cornerRadius = 10
        loadBackgroundImage()
        // Do any additional setup after loading the view.
    }
    
    func loadBackgroundImage() {
        let myImage = UIImage(named: "Background")
            self.backgroundImageView.image = myImage
            view.addSubview(backgroundImageView)
            backgroundImageView.contentMode = .scaleAspectFill
            view.sendSubviewToBack(backgroundImageView)

    }
    
    private func clearForm() {
        self.loginTextField.text = ""
        self.passwordTextField.text = ""
    }
    
    @IBAction func authorizationButtonTapped(_ sender: UIButton) {
        guard let username = loginTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            print("Email and password cannot be empty.")
            return
        }

        // Construct the URL
        guard let url = URL(string: "http://localhost:8080/api/auth/signin") else {
            print("Invalid URL.")
            return
        }

        // Prepare the request body
        let requestBody: [String: Any] = [
            "username": username,
            "password": password
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
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Ошибка", message: "Введён некорректный логин или пароль", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                
                print("Response from POST request: \(responseString)")

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        
                        saveJsonToFile(jsonObject: json, filename: "UserToken")
                    } else {
                        print("Could not parse JSON response.")
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }

                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(title: "Вход", message: "Успешная авторизация!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        let sb = UIStoryboard(name: "Main", bundle: nil)
                        let newsVC = sb.instantiateViewController(identifier: "NewsViewController")

                        self.show(newsVC, sender: self)

                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                    self.clearForm()
                }
            }
        }

        task.resume()
    }
    
    
    @IBAction func registrationButtonPressed(_ sender: UIButton) {
        self.clearForm()
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let registrationVC = sb.instantiateViewController(identifier: "RegistrationViewController")

        show(registrationVC, sender: self)
    }
}
