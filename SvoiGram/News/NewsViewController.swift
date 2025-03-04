//
//  NewsViewController.swift
//  SvoiGram
//
//  Created by Никита Киселев on 03.03.2025.
//

import Foundation
import UIKit

class NewsViewController: UIViewController {

    @IBOutlet weak var newsTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        let token = getToken()
        fetchData(token: token)
        
    }

    func fetchData(token: String) {
        guard let url = URL(string: "http://localhost:8080/api/post/all") else {
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

            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for jsonObject in jsonArray {
                        var tableItem = NewsTableViewCell()
                        
//                        if let id = jsonObject["id"] as? Int {
//                            print("ID: \(id)")
//                            // Теперь вы можете использовать id
//                        }
                        
                        guard let postTitle = jsonObject["title"] as? String else {
                            return
                        }

                        guard let postPlace = jsonObject["location"] as? String else {
                            return
                        }

                        guard let postAuthor = jsonObject["username"] as? String else {
                            return
                        }

                        guard let postDescription = jsonObject["caption"] as? String else {
                            return
                        }

                        tableItem.configure(postTitle: postTitle, postPlace: postPlace, postImage: "", postAuthor: postAuthor, postDescription: postDescription)

//                        newsTable.addConstraint(<#T##constraint: NSLayoutConstraint##NSLayoutConstraint#>)
                        
                    }
                    
                } else {
                    print("Не удалось распарсить JSON ответ как массив словарей.")
                }
            } catch {
                print("Ошибка при парсинге JSON: \(error)")
            }


        }
        task.resume()
    }

    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        modalPresentationStyle = .fullScreen
    }
}
