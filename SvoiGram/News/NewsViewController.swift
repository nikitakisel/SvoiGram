//
//  NewsViewController.swift
//  SvoiGram
//
//  Created by Никита Киселев on 03.03.2025.
//

import Foundation
import UIKit

struct Post {
    var id: Int
    var title: String
    var place: String
    var image: Data
    var author: String
    var description: String
    
    init(id: Int, title: String, place: String, image: Data, author: String, description: String) {
        self.id = id
        self.title = title
        self.place = place
        self.image = image
        self.author = author
        self.description = description
    }
    
    func getInfo() {
        print("Id: \(id)")
        print("Title: \(title)")
        print("Place: \(place)")
        print("Author: \(author)")
        print("Image: \(image)")
    }
}

class NewsViewController: UIViewController {
    
    @IBOutlet weak var newsTable: UITableView!
    var userToken = getToken()
    var PostsData: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        PostsData.removeAll()
        fetchData(token: userToken)
//        newsTable.register(NewsTableViewCell.self, forCellReuseIdentifier: "NewsTableViewCell")
        let nib = UINib(nibName: "NewsTableViewCell", bundle: nil)
        newsTable.register(nib, forCellReuseIdentifier: "NewsTableViewCell")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        modalPresentationStyle = .fullScreen
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
                        
                        guard let postId = jsonObject["id"] as? Int else {
                            return
                        }
                        
                        guard let postTitle = jsonObject["title"] as? String else {
                            return
                        }
                        
                        guard let postPlace = jsonObject["location"] as? String else {
                            return
                        }
                        
                        let postImage = getImageBytes(token: self.userToken, id: postId)
                        print(postImage)
                        
                        guard let postAuthor = jsonObject["username"] as? String else {
                            return
                        }
                        
                        guard let postDescription = jsonObject["caption"] as? String else {
                            return
                        }
                        
                        let CurrentPost: Post = Post(id: postId, title: postTitle, place: postPlace, image: postImage, author: postAuthor, description: postDescription)
//                        CurrentPost.getInfo()
                        self.PostsData.append(CurrentPost)
                        
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
        
}

extension NewsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 270.0
    }
}

extension NewsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PostsData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Попытка переиспользовать ячейку
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTableViewCell", for: indexPath) as? NewsTableViewCell else {
//            fatalError("Не удалось создать/переиспользовать ячейку NewsTableViewCell")
//        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTableViewCell", for: indexPath) as! NewsTableViewCell

        // Настройка ячейки с данными
        cell.configure(postId: PostsData[indexPath.row].id, postTitle: PostsData[indexPath.row].title, postPlace: PostsData[indexPath.row].place, postImage: PostsData[indexPath.row].image, postAuthor: PostsData[indexPath.row].author, postDescription: PostsData[indexPath.row].description)

        return cell
    }
}


    
func getImageBytes(token: String, id: Int) -> Data {
    
    var result: Data = Data(base64Encoded: "")!
    
    guard let url = URL(string: "http://localhost:8080/api/image/\(id)/image") else {
        print("Invalid URL")
        return result
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
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let imgBytes = json["imageBytes"] as? String {
                    if Data(base64Encoded: imgBytes) != nil {
                        result = Data(base64Encoded: imgBytes)!
                    } else {
                        print("Image not found in JSON response.")
                    }
                    
                } else {
                    print("Image not found in JSON response.")
                    return
                }
                
                
            } else {
                print("Не удалось распарсить JSON ответ как массив словарей.")
            }
        } catch {
            print("Ошибка при парсинге JSON: \(error)")
        }
        
        
    }
    task.resume()
    return result
}
