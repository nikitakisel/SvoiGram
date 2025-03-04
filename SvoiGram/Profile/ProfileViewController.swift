//
//  ProfileViewController.swift
//  SvoiGram
//
//  Created by Никита Киселев on 04.03.2025.
//

import Foundation
import UIKit

class ProfileViewController: UIViewController {
    
    weak var delegate: ProfileViewControllerDelegate?
    var userToken = getToken()
    var PostsData: [Post] = []
    
    
    @IBOutlet weak var userNickNameLabel: UILabel!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userPhoto: UIImageView!
    
    @IBOutlet weak var postsTable: UITableView!
    
    @IBOutlet weak var newsButton: UIButton!
    
    @IBOutlet weak var quitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        loadProfileData(token: self.userToken)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        modalPresentationStyle = .fullScreen
    }
    
    @IBAction func newsButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func quitButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Выход", message: "Вы уверены, что хотите выйти?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Да", style: .default, handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
            self?.delegate?.profileDidDismiss()
        }))

        alert.addAction(UIAlertAction(title: "Нет", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)

    }
    
    func loadProfileData(token: String) {
        guard let url = URL(string: "http://localhost:8080/api/user/") else {
            print("Invalid URL")
//            completion()
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization") // Set Authorization header
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error: \(error)")
//                completion()
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Server error! StatusCode: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
//                completion()
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                
                print("Response from POST request: \(responseString)")

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        
                        guard let userNickName = json["username"] as? String,
                              let userFirstName = json["firstname"] as? String,
                              let userLastName = json["lastname"] as? String else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.userNickNameLabel.text = userNickName
                            self.userNameLabel.text = "\(userFirstName) \(userLastName)"
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
}
