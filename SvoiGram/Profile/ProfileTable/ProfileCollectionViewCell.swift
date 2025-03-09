//
//  ProfileCollectionViewCell.swift
//  SvoiGram
//
//  Created by Никита Киселев on 09.03.2025.
//

import Foundation
import UIKit

protocol DeleteCommentDelegate: AnyObject {
    func updateComments()
}

protocol UpdateCommentsDelegate: AnyObject {
    func updateNewsCommentsTable()
}

class ProfileCollectionViewCell: UICollectionViewCell {
    
    private var commentId: Int = -1
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var deleteCommentButton: UIButton!
    
    weak var deleteCommentDelegate: DeleteCommentDelegate?
    weak var updateCommentsDelegate: UpdateCommentsDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(id: Int, userName: String, userComment: String) {
        self.commentId = id
        self.userNameLabel.text = "\(userName):"
        self.commentLabel.text = userComment
    }
    
    @IBAction func deleteCommentButtonPressed(_ sender: UIButton) {
        self.deleteComment(token: getToken(), commentId: self.commentId)
    }
    
    func deleteComment(token: String, commentId: Int) {
        guard let url = URL(string: "http://localhost:8080/api/comment/\(commentId)") else {
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
                self.deleteCommentDelegate?.updateComments()
                self.updateCommentsDelegate?.updateNewsCommentsTable()
            }
            
        }
        task.resume()
    }
}
