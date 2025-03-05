//
//  ProfileTableViewCell.swift
//  SvoiGram
//
//  Created by Никита Киселев on 05.03.2025.
//

import Foundation
import UIKit

class ProfileTableViewCell: UITableViewCell {
    
    private var postId: Int = -1
    
    @IBOutlet weak var postTitle: UILabel!
    
    @IBOutlet weak var postPlace: UILabel!
    
    @IBOutlet weak var postImage: UIImageView!
    
    @IBOutlet weak var postDescription: UILabel!
    
    @IBOutlet weak var postLikesCount: UILabel!
    
    @IBOutlet weak var editButton: UIButton!
    
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
    
    override func awakeFromNib() {
       super.awakeFromNib()
       // Initialization code
    }

    required init?(coder: NSCoder) {
       super.init(coder: coder)
    }
    
    func configure(postId: Int, postTitle: String, postPlace: String, postImage: Data, postDescription: String, postLikesCount: Int) {
        self.postId = postId
        self.postTitle.text = postTitle
        self.postPlace.text = postPlace
//        self.postImage.cgImage = postImage
        self.postDescription.text = postDescription
        displayBase64Image(imageData: postImage, imageView: self.postImage)
        self.postLikesCount.text = "\(postLikesCount)"
    }
}
