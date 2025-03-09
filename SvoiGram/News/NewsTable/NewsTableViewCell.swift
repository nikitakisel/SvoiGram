//
//  NewsTableViewCell.swift
//  SvoiGram
//
//  Created by Никита Киселев on 03.03.2025.
//

import Foundation
import UIKit


struct Comment: Decodable {
    var id: Int
    var userName: String
    var userComment: String
    
    init(id: Int, userName: String, userComment: String) {
        self.id = id
        self.userName = userName
        self.userComment = userComment
    }
    
    func getInfo() {
        print("Comment ID: \(self.id)")
        print("Username: \(self.userName)")
        print("Comment: \(self.userComment)")
    }
}


class NewsTableViewCell: UITableViewCell {
    
    private var postId: Int = -1
    private var userNickName: String = ""
    private var isLiked: Bool = false
    private var PostComments: [Comment] = []
    
    @IBOutlet private weak var postTitle: UILabel!
    @IBOutlet private weak var postPlace: UILabel!
    @IBOutlet private weak var postImage: UIImageView!
    @IBOutlet private weak var postAuthor: UILabel!
    @IBOutlet private weak var postDescription: UILabel!
    
    @IBOutlet weak var postLikesCount: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    
    @IBOutlet weak var commentLabel: UITextField!
    @IBOutlet weak var addCommentButton: UIButton!
    @IBOutlet weak var commentsCollectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.commentsCollectionView.delegate = self
        self.commentsCollectionView.dataSource = self
        
        let nib = UINib(nibName: "NewsCollectionViewCell", bundle: nil)
        commentsCollectionView.register(nib, forCellWithReuseIdentifier: "NewsCollectionViewCell")
        
        if let layout = commentsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: commentsCollectionView.frame.width, height: 30)
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            layout.scrollDirection = .vertical
        }

    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(postId: Int, postTitle: String, postPlace: String, postImage: Data?, postAuthor: String, postDescription: String, postLikesCount: Int, postUsersLiked: [String]) {
        self.postId = postId
        self.postTitle.text = postTitle
        self.postPlace.text = postPlace
        self.postAuthor.text = "Posted by \(postAuthor)"
        self.postDescription.text = postDescription
        self.postLikesCount.text = "\(postLikesCount)"
        
        updateComments()
        displayBase64Image(imageData: postImage, imageView: self.postImage)
        getUserName(token: getToken(), usersLiked: postUsersLiked)
    }
    
    func updateComments() {
        self.PostComments.removeAll()
        
        getComments(token: getToken(), postId: self.postId) {
            DispatchQueue.main.async {
                self.commentsCollectionView.reloadData()
            }
        }
    }
    
    
    @IBAction func likeButtonPressed(_ sender: UIButton) {
        like(token: getToken(), postId: self.postId, username: self.userNickName)
    }
    
    
    @IBAction func addCommentButtonPressed(_ sender: UIButton) {
        
        guard let comment = self.commentLabel.text, !comment.isEmpty else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Ошибка", message: "Вы не ввели комментарий!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            }
            return
        }
        
        self.addComment(token: getToken(), comment: self.commentLabel.text!)
        
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
    
    func addComment(token: String, comment: String) {
        guard let url = URL(string: "http://localhost:8080/api/comment/\(self.postId)") else {
            print("Invalid URL.")
            return
        }

        // Prepare the request body
        let requestBody: [String: Any] = [
            "message": comment
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
                
                DispatchQueue.main.async {
                    self.commentLabel.text = ""
                    self.updateComments()
                }
            }
        }

        task.resume()
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
    
    func getComments(token: String, postId: Int, completion: @escaping () -> Void) {
        guard let url = URL(string: "http://localhost:8080/api/comment/\(postId)/all") else {
            print("Invalid URL")
            completion()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")

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
                        guard let commentId = jsonObject["id"] as? Int,
                              let commentValue = jsonObject["message"] as? String,
                              let commentUsername = jsonObject["username"] as? String else {
                            return
                        }
                        print(commentId)
                        
                        let newComment: Comment = Comment(id: commentId, userName: commentUsername, userComment: commentValue)
                        newComment.getInfo()
                        self.PostComments.append(newComment)
                        completion()
                    }
                    
                } else {
                   print("Comments not found in JSON response or invalid base64 string.")
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


func displayBase64Image(imageData: Data?, imageView: UIImageView) {
    if let image = imageData {
        imageView.image = UIImage(data: image) // imageView - ваш UIImageView
        imageView.contentMode = .scaleAspectFill
    } else {
        // Обработка ошибки:
        print("Ошибка: Не удалось создать изображение из предоставленных данных.")
        // Например, можно установить placeholder image:
        imageView.image = UIImage(systemName: "newspaper")
    }
}


extension NewsTableViewCell: UICollectionViewDelegate {
    
}

extension NewsTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PostComments.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCollectionViewCell", for: indexPath) as! NewsCollectionViewCell
        
        cell.configure(id: PostComments[indexPath.row].id, userName: PostComments[indexPath.row].userName, userComment: PostComments[indexPath.row].userComment)
        
        return cell
    }
}

extension NewsTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 25)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
