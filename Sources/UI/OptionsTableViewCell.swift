//
//  OptionsTableViewCell.swift
//  KalturaPlayer
//
//  Created by Vadim Kononov on 16/01/2018.
//

import UIKit

class OptionsTableViewCell: UITableViewCell {
    
    var isSelectable = false
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        selectionStyle = .none
        textLabel?.font = UIFont(name: "Helvetica", size: 16)
        textLabel?.textColor = UIColor.white
        textLabel?.numberOfLines = 2
        tintColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        imageView?.image = nil
        accessoryType = .none
        isSelectable = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if isSelectable {
            accessoryType = selected ? .checkmark : .none
        }
    }
}
