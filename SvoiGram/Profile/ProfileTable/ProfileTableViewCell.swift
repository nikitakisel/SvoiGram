//
//  ProfileTableViewCell.swift
//  SvoiGram
//
//  Created by Никита Киселев on 05.03.2025.
//

import Foundation
import UIKit

protocol DeletePostDelegate: AnyObject {
    func offerToDeletePost(postId: Int)
}

class ProfileTableViewCell: UITableViewCell, DeleteCommentDelegate, UpdateCommentsDelegate {
    
    private var postId: Int = -1
    private var PostComments: [Comment] = []
    weak var deletePostDelegate: DeletePostDelegate?
    weak var updateCommentsDelegate: UpdateCommentsDelegate?
    
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postPlace: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    
    @IBOutlet weak var postDescription: UILabel!
    @IBOutlet weak var postLikesCount: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var commentsCollectionView: UICollectionView!
    
    override func awakeFromNib() {
       super.awakeFromNib()
        self.commentsCollectionView.delegate = self
        self.commentsCollectionView.dataSource = self
        
        let nib = UINib(nibName: "ProfileCollectionViewCell", bundle: nil)
        commentsCollectionView.register(nib, forCellWithReuseIdentifier: "ProfileCollectionViewCell")
        
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
    
    func configure(postId: Int, postTitle: String, postPlace: String, postImage: Data?, postDescription: String, postLikesCount: Int) {
        self.postId = postId
        self.postTitle.text = postTitle
        self.postPlace.text = postPlace
//        self.postImage.cgImage = postImage
        self.postDescription.text = postDescription
        
        self.updateComments()
        displayBase64Image(imageData: postImage, imageView: self.postImage)
        self.postLikesCount.text = "\(postLikesCount)"
    }
    
    func updateComments() {
        self.PostComments.removeAll()
        
        getComments(token: getToken(), postId: self.postId) {
            DispatchQueue.main.async {
                self.commentsCollectionView.reloadData()
            }
        }
    }
    
    func updateNewsCommentsTable() {
        self.updateCommentsDelegate?.updateNewsCommentsTable()
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        deletePostDelegate?.offerToDeletePost(postId: self.postId)
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
                        
                        let newComment: Comment = Comment(id: commentId, userName: commentUsername, userComment: commentValue)
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

extension ProfileTableViewCell: UICollectionViewDelegate {
    
}

extension ProfileTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PostComments.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCollectionViewCell", for: indexPath) as! ProfileCollectionViewCell
        cell.deleteCommentDelegate = self
        cell.updateCommentsDelegate = self
        
        cell.configure(id: PostComments[indexPath.row].id, userName: PostComments[indexPath.row].userName, userComment: PostComments[indexPath.row].userComment)
        
        return cell
    }
}

extension ProfileTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 30)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
