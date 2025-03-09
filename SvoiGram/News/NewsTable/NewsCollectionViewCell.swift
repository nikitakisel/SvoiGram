//
//  NewsCollectionViewCell.swift
//  SvoiGram
//
//  Created by Никита Киселев on 09.03.2025.
//

import Foundation
import UIKit

class NewsCollectionViewCell: UICollectionViewCell {
    
    private var commentId: Int = -1
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userCommentLabel: UILabel!
    
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
        self.userCommentLabel.text = userComment
    }
}
