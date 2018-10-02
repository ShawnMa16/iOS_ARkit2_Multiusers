//
//  GameCell.swift
//  Multiplayer_test
//
//  Created by Shawn Ma on 10/1/18.
//  Copyright © 2018 Shawn Ma. All rights reserved.
//

import Foundation
import UIKit

class GameCell: UITableViewCell {
    
//    let textLabel: UILabel = {
//        return UILabel()
//    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
//        contentView.addSubview(textLabel)
//        setupTextLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    func setupTextLabel() {
//        textLabel.snp.makeConstraints { (make) in
//            make.edges.equalToSuperview().offset(0)
//        }
//    }
    
}
