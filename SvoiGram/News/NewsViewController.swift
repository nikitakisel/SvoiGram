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
    var image: Data?
    var author: String
    var description: String
    var likesCount: Int
    
    init(id: Int, title: String, place: String, image: Data?, author: String, description: String, likesCount: Int) {
        self.id = id
        self.title = title
        self.place = place
        self.image = image
        self.author = author
        self.description = description
        self.likesCount = likesCount
    }
    
    func getInfo() {
        print("Id: \(id)")
        print("Title: \(title)")
        print("Place: \(place)")
        print("Author: \(author)")
        print("Likes: \(likesCount)")
    }
}

protocol ProfileViewControllerDelegate: AnyObject {
    func profileDidDismiss()
}

class NewsViewController: UIViewController, ProfileViewControllerDelegate, UpdatePostTableDelegate {
    
    @IBOutlet weak var profileButton: UIButton!
    
    @IBOutlet weak var quitButton: UIButton!
    
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
        
        updatePostTable()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        modalPresentationStyle = .fullScreen
    }
    
    func profileDidDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func updatePostTable() {
        self.PostsData.removeAll()
        
        fetchData(token: self.userToken) {
            DispatchQueue.main.async {
                self.newsTable.reloadData()
            }
        }
    }


    @IBAction func profileButtonPressed(_ sender: UIButton) {

//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let profileVC = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
//
//        profileVC.modalPresentationStyle = .fullScreen
//        present(profileVC, animated: true)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let profileVC = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        profileVC.updateDelegate = self
        profileVC.closeDelegate = self
        present(profileVC, animated: true, completion: nil)


    }
    
    
    @IBAction func quitButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Выход", message: "Вы уверены, что хотите выйти?", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Да", style: .default, handler: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }))

            alert.addAction(UIAlertAction(title: "Нет", style: .cancel, handler: nil))

            present(alert, animated: true, completion: nil)
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
                
                        guard let postId = jsonObject["id"] as? Int,
                              let postTitle = jsonObject["title"] as? String,
                              let postPlace = jsonObject["location"] as? String,
                              let postAuthor = jsonObject["username"] as? String,
                              let postDescription = jsonObject["caption"] as? String else {
                            return
                        }
                        
                        getImageData(token: self.userToken, url: "http://localhost:8080/api/image/\(postId)/image") { imageData in
                            if let imageData = imageData {
                                
                                let CurrentPost: Post = Post(id: postId, title: postTitle, place: postPlace, image: imageData, author: postAuthor, description: postDescription, likesCount: 0)
                                self.PostsData.append(CurrentPost)
                                completion()
                                
                            } else {
                                print("Failed to retrieve image data")
                                let CurrentPost: Post = Post(id: postId, title: postTitle, place: postPlace, image: nil, author: postAuthor, description: postDescription, likesCount: 0)
                                self.PostsData.append(CurrentPost)
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

func getImageData(token: String, url: String, completion: @escaping (Data?) -> Void) {
    guard let url = URL(string: url) else {
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
                 let imageBase64 = json["encoded_image"] as? String,
                 let imageData = Data(base64Encoded: imageBase64, options: .ignoreUnknownCharacters) else {
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
