//
//  NewsTableViewCell.swift
//  SvoiGram
//
//  Created by Никита Киселев on 03.03.2025.
//

import Foundation
import UIKit

class NewsTableViewCell: UITableViewCell {
    
    private var postId: Int
    @IBOutlet private weak var postTitle: UILabel!
    @IBOutlet private weak var postPlace: UILabel!
    @IBOutlet private weak var postImage: UIImageView!
    @IBOutlet private weak var postAuthor: UILabel!
    @IBOutlet private weak var postDescription: UILabel!
    
    func displayBase64Image(imageData: Data, imageView: UIImageView) {
        if let image = UIImage(data: imageData) {
            imageView.image = image // imageView - ваш UIImageView
        } else {
            // Обработка ошибки:
            print("Ошибка: Не удалось создать изображение из предоставленных данных.")
            // Например, можно установить placeholder image:
            imageView.image = UIImage(named: "placeholderImage")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func configure(postId: Int, postTitle: String, postPlace: String, postImage: Data, postAuthor: String, postDescription: String) {
        self.postId = postId
        self.postTitle.text = postTitle
        self.postPlace.text = postPlace
//        self.postImage.cgImage = postImage
        self.postAuthor.text = postAuthor
        self.postDescription.text = postDescription
        displayBase64Image(imageData: postImage, imageView: self.postImage)
    }
}
