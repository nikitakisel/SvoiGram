//
//  NewsViewController.swift
//  SvoiGram
//
//  Created by Никита Киселев on 03.03.2025.
//

import Foundation
import UIKit

struct Post: Decodable {
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
        
        newsTable.delegate = self
        newsTable.dataSource = self
        
        let nib = UINib(nibName: "NewsTableViewCell", bundle: nil)
        newsTable.register(nib, forCellReuseIdentifier: "NewsTableViewCell")
        
        fetchData(token: self.userToken) { // Call fetchData with completion handler
            print("Data fetched and table reloaded")
            print(self.PostsData.count)
            DispatchQueue.main.async {
                self.newsTable.reloadData()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        modalPresentationStyle = .fullScreen
    }
    
    func fetchData(token: String, completion: @escaping () -> Void) {
        guard let url = URL(string: "http://localhost:8080/api/post/all") else {
            print("Invalid URL")
            completion()
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization") // Set Authorization header
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error: \(error)")
                completion()
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Server error! StatusCode: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                completion()
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion()
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
                        
                        guard let postAuthor = jsonObject["username"] as? String else {
                            return
                        }
                        
                        guard let postDescription = jsonObject["caption"] as? String else {
                            return
                        }
                        
                        getImageBytes(token: self.userToken, id: postId) { imageData in
                            if let imageData = imageData {
                                print("Image data received: \(imageData.count) bytes")
                                
                                let CurrentPost: Post = Post(id: postId, title: postTitle, place: postPlace, image: imageData, author: postAuthor, description: postDescription)
                                CurrentPost.getInfo()
                                self.PostsData.append(CurrentPost)
                                completion()
                                
                            } else {
                                print("Failed to retrieve image data")
                                completion()
                            }
                        }
                        
                    }
                    
                } else {
                    print("Не удалось распарсить JSON ответ как массив словарей.")
                    completion()
                }
            } catch {
                print("Ошибка при парсинге JSON: \(error)")
                completion()
            }
            
            
        }
        task.resume()
    }
        
}

extension NewsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 370.0
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

func getImageBytes(token: String, id: Int, completion: @escaping (Data?) -> Void) {
    guard let url = URL(string: "http://localhost:8080/api/image/\(id)/image") else {
        print("Invalid URL")
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(token, forHTTPHeaderField: "Authorization")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            completion(nil)
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("Server error! StatusCode: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
            completion(nil)
            return
        }

        guard let data = data else {
            print("No data received")
            completion(nil)
            return
        }
        do {
           guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                 let imgBytes = json["imageBytes"] as? String,
                 let imageData = Data(base64Encoded: imgBytes) else {
               print("Image not found in JSON response or invalid base64 string.")
               completion(nil)
               return
           }

           completion(imageData)

       } catch {
           print("Ошибка при парсинге JSON: \(error)")
           completion(nil)
       }
   }
   task.resume()
}
