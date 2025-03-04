//
//  NewsTableViewCell.swift
//  SvoiGram
//
//  Created by Никита Киселев on 03.03.2025.
//

import Foundation
import UIKit

class NewsTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var postTitle: UILabel!
    @IBOutlet private weak var postPlace: UILabel!
    @IBOutlet private weak var postImage: UIImageView!
    @IBOutlet private weak var postAuthor: UILabel!
    @IBOutlet private weak var postDescription: UILabel!
    
    func configure(postTitle: String, postPlace: String, postImage: String, postAuthor: String, postDescription: String) {
        self.postTitle.text = postTitle
        self.postPlace.text = postPlace
//        self.postImage.cgImage = postImage
        self.postAuthor.text = postAuthor
        self.postDescription.text = postDescription
        
    }
    
}
