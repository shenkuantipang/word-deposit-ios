import UIKit
import Foundation

class PrimaryButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = Radiuses.large
        setTitleColor(Colors.yellow, for: .normal)
        titleLabel?.font = UIFont(name: Fonts.medium, size: 16)
        layer.backgroundColor = Colors.dark.cgColor
    }
    
    override var isEnabled: Bool {
        didSet {
            if self.isEnabled {
                layer.backgroundColor = Colors.dark.cgColor
            } else {
                layer.backgroundColor = Colors.dark.withAlphaComponent(0.4).cgColor
            }
        }
    }
}
