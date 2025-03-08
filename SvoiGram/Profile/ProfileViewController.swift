//
//  ProfileViewController.swift
//  SvoiGram
//
//  Created by Никита Киселев on 04.03.2025.
//

import Foundation
import UIKit

class ProfileViewController: UIViewController, UpdatePostTableDelegate, DeletePostDelegate {
    
    weak var updateDelegate: UpdatePostTableDelegate?
    weak var closeDelegate: ProfileViewControllerDelegate?
    var userToken = getToken()
    var PostsData: [Post] = []
    
    @IBOutlet weak var userNickNameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var postsTable: UITableView!
    @IBOutlet weak var addPostButton: UIButton!
    @IBOutlet weak var newsButton: UIButton!
    @IBOutlet weak var quitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        loadProfileData(token: self.userToken)
        getImageData(token: self.userToken, url: "http://localhost:8080/api/image/profileImage") { imageData in
            if let imageData = imageData {
                self.displayUserImage(imageData: imageData, imageView: self.userPhoto)
            } else {
                DispatchQueue.main.async {
                    self.userPhoto.image = UIImage(systemName: "person")
                }
            }
        }
        
        postsTable.delegate = self
        postsTable.dataSource = self
        
        let nib = UINib(nibName: "ProfileTableViewCell", bundle: nil)
        postsTable.register(nib, forCellReuseIdentifier: "ProfileTableViewCell")
        
        fetchData(token: self.userToken) {
            DispatchQueue.main.async {
                self.postsTable.reloadData()
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
    
    func updatePostTable() {
        self.PostsData.removeAll()

        fetchData(token: self.userToken) {
            DispatchQueue.main.async {
                self.postsTable.reloadData()
            }
        }
        
        updateDelegate?.updatePostTable()

    }
    
    func displayUserImage(imageData: Data, imageView: UIImageView) {
        if let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                imageView.image = image
            }
        } else {
            print("Ошибка: Не удалось создать изображение из предоставленных данных.")
            DispatchQueue.main.async {
                imageView.image = UIImage(systemName: "person")
            }
        }
    }
    
    @IBAction func newsButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func addPostButtonPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "AddPostViewController") as! AddPostViewController
        viewController.delegate = self
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = self
        present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func quitButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Выход", message: "Вы уверены, что хотите выйти?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Да", style: .default, handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
            self?.closeDelegate?.profileDidDismiss()
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
    
    
    
    func fetchData(token: String, completion: @escaping () -> Void) {
        guard let url = URL(string: "http://localhost:8080/api/post/user/posts") else {
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
                              let postDescription = jsonObject["caption"] as? String,
                              let postLikesCount = jsonObject["likes"] as? Int else {
                            return
                        }
                        
                        getImageData(token: self.userToken, url: "http://localhost:8080/api/image/\(postId)/image") { imageData in
                            if let imageData = imageData {
//                                print("Image data received: \(imageData.count) bytes")
                                
                                let CurrentPost: Post = Post(id: postId, title: postTitle, place: postPlace, image: imageData, author: postAuthor, description: postDescription, likesCount: postLikesCount, usersLiked: [])
                                self.PostsData.append(CurrentPost)
                                completion()
                                
                            } else {
                                print("Failed to retrieve image data")
                                let CurrentPost: Post = Post(id: postId, title: postTitle, place: postPlace, image: nil, author: postAuthor, description: postDescription, likesCount: postLikesCount, usersLiked: [])
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
    
    
    func offerToDeletePost(postId: Int) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Удаление", message: "Вы уверены, что хотите удалить данный пост?", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Да", style: .default, handler: { [weak self] _ in
                self?.deletePost(token: getToken(), postId: postId)
            }))

            alert.addAction(UIAlertAction(title: "Нет", style: .cancel, handler: nil))

            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func deletePost(token: String, postId: Int) {
        guard let url = URL(string: "http://localhost:8080/api/post/\(postId)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "DELETE"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
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
            
            DispatchQueue.main.async {
                
                self.updatePostTable()
                let alert = UIAlertController(title: "Успешно!", message: "Выбранный пост удалён", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
            
        }
        task.resume()
    }
}



extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 370.0
    }
}

extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PostsData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell", for: indexPath) as! ProfileTableViewCell
        cell.delegate = self

        cell.configure(postId: PostsData[indexPath.row].id, postTitle: PostsData[indexPath.row].title, postPlace: PostsData[indexPath.row].place, postImage: PostsData[indexPath.row].image, postDescription: PostsData[indexPath.row].description, postLikesCount: PostsData[indexPath.row].likesCount)

        return cell
    }
}


extension ProfileViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfScreenPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
