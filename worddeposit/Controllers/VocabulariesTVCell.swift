import UIKit
import FirebaseAuth
import FirebaseFirestore

class VocabulariesTVCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var wordsAmount: UILabel!
    @IBOutlet weak var selectionSwitch: UISwitch!
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - Istances
    
    var isSelectedVocabulary: Bool! {
        didSet {
            selectionSwitch.isOn = isSelectedVocabulary
            if isSelectedVocabulary {
                containerView.layer.borderWidth = 2
                containerView.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
            }

        }
    }
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        selectionSwitch.isOn = false
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: - Own Methods
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected == true {
            containerView.layer.backgroundColor = CGColor(srgbRed: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1)
            
        } else {
            if isSelectedVocabulary == true {
                containerView.layer.backgroundColor = .none
            } else {
                containerView.layer.backgroundColor = CGColor(srgbRed: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 0.5)
            }
        }
    }
    
    func configureCell(vocabulary: Vocabulary, userRef: DocumentReference) {
        titleLabel.text = vocabulary.title
        languageLabel.text = vocabulary.language
        
        var amount = 0
        
        let vocabularyRef = userRef.collection("vocabularies").document(vocabulary.id)
        vocabularyRef.getDocument { (snapshot, error) in
            if let error = error {
                print(error.localizedDescription)
            } else  {
                amount = snapshot?.data()?.count ?? 0
            }
        }
        
        wordsAmount.text = String(amount)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 0
        containerView.layer.backgroundColor = CGColor(srgbRed: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 0.5)
        if isSelectedVocabulary == true {
            containerView.layer.backgroundColor = .none
        }
    }
}