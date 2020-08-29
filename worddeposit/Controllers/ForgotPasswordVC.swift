import UIKit
import FirebaseAuth

class ForgotPasswordVC: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewCenterY: NSLayoutConstraint!
    
    // Custom
    private var isKeyboardShowing = false
    private var keyboardHeight: CGFloat!
    
    // MARK: - IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    var progressHUD = ProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressHUD.hide()
        
        // Keyboard observers - willshow willhide
        let notificationCeneter: NotificationCenter = NotificationCenter.default
        notificationCeneter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCeneter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - @objc Methods
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        // check if keyboard already is on the screen
        if isKeyboardShowing { return }
        isKeyboardShowing = true
        
        
        // titleLabel.isHidden = true
        titleLabel.alpha = 0
        cancelButton.alpha = 0
        
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardHeight = keyboardFrame.cgRectValue.height
            
            // Using centerY constrains and changing it allow to save the position of the stackview at the center
            // even if we accidently touch (and drag) uiViewController.
             UIView.animate(withDuration: 0.3) {
                self.stackViewCenterY.constant -= (self.keyboardHeight - self.stackView.frame.size.height)
                self.view.layoutIfNeeded()
             }
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        // check if keyboard already is on the screen
        if !isKeyboardShowing { return }
        isKeyboardShowing = false
        
        titleLabel.alpha = 1
        cancelButton.alpha = 1
        
        self.stackView.frame.origin.y += (keyboardHeight - self.stackView.frame.height)
        
         UIView.animate(withDuration: 0.3) {
            self.stackViewCenterY.constant += (self.keyboardHeight - self.stackView.frame.size.height)
            self.view.layoutIfNeeded()
         }
    }
    
    // MARK: - Methods
    
    // MARK: - IBActions
    @IBAction func onResetPasswordBtnPress(_ sender: RoundedButton) {
        guard let email = emailTextField.text, email.isNotEmpty else {
            simpleAlert(title: "Error", msg: "Fill email field out")
            return
        }
        progressHUD.show()
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if let error = error {
                self.progressHUD.hide()
                self.simpleAlert(title: "Error", msg: error.localizedDescription)
                return
            }
            self.navigationController?.popViewController(animated: true)
            self.progressHUD.hide()
        }
    }
    
    @IBAction func onCancelBtnPress(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
