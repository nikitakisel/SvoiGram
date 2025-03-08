//
//  NewsTableViewCell.swift
//  SvoiGram
//
//  Created by Никита Киселев on 03.03.2025.
//

import Foundation
import UIKit

class NewsTableViewCell: UITableViewCell {
    
    private var postId: Int = -1
    private var userNickName: String = ""
    private var isLiked: Bool = false
    
    @IBOutlet private weak var postTitle: UILabel!
    @IBOutlet private weak var postPlace: UILabel!
    @IBOutlet private weak var postImage: UIImageView!
    @IBOutlet private weak var postAuthor: UILabel!
    @IBOutlet private weak var postDescription: UILabel!
    
    @IBOutlet weak var postLikesCount: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(postId: Int, postTitle: String, postPlace: String, postImage: Data?, postAuthor: String, postDescription: String, postLikesCount: Int, postUsersLiked: [String]) {
        self.postId = postId
        self.postTitle.text = postTitle
        self.postPlace.text = postPlace
//        self.postImage.cgImage = postImage
        self.postAuthor.text = "Posted by \(postAuthor)"
        self.postDescription.text = postDescription
        self.postLikesCount.text = "\(postLikesCount)"
        
        displayBase64Image(imageData: postImage, imageView: self.postImage)
        getUserName(token: getToken(), usersLiked: postUsersLiked)
    }
    
    
    @IBAction func likeButtonPressed(_ sender: UIButton) {
        like(token: getToken(), postId: self.postId, username: self.userNickName)
    }
    
    func like(token: String, postId: Int, username: String) {
        guard let url = URL(string: "http://localhost:8080/api/post/\(postId)/\(username)/like") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
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
                        
                        guard let likesCount = json["likes"] as? Int else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.postLikesCount.text = "\(likesCount)"
                            if self.isLiked == true {
                                self.deleteLike()
                            } else {
                                self.addLike()
                            }
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
    
    func addLike() {
        self.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        self.isLiked = true
    }
    
    func deleteLike() {
        self.likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        self.isLiked = false
    }
    
    func getUserName(token: String, usersLiked: [String]) {
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
                        
                        guard let userNickName = json["username"] as? String else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.userNickName = userNickName
                            if usersLiked.contains(self.userNickName) {
                                self.addLike()
                            }
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


func displayBase64Image(imageData: Data?, imageView: UIImageView) {
    if let image = imageData {
        imageView.image = UIImage(data: image) // imageView - ваш UIImageView
    } else {
        // Обработка ошибки:
        print("Ошибка: Не удалось создать изображение из предоставленных данных.")
        // Например, можно установить placeholder image:
        imageView.image = UIImage(systemName: "newspaper")
    }
}
