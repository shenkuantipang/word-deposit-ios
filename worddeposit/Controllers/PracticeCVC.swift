import UIKit
import Firebase
import FirebaseFirestore

private let reuseIdentifier = XIBs.PracticeCVCell

class PracticeCVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    // MARK: - Instances
    
    var user = User()
    var words = [Word]()
    var auth: Auth!
    var db: Firestore!
    var handle: AuthStateDidChangeListenerHandle?
    
    private var trainers = [PracticeTrainer]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        auth = Auth.auth()
        db = Firestore.firestore()
        
        trainers = PracticeTrainers().data
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        let nib = UINib(nibName: XIBs.PracticeCVCell, bundle: nil)
        self.collectionView!.register(nib, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView!.isPrefetchingEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let flowlayout = collectionViewLayout as? UICollectionViewFlowLayout {
            flowlayout.minimumLineSpacing = 20
        }

        getCurrentUser()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        auth.removeStateDidChangeListener(handle!)
    }
    
    // MARK: - Methods
    
    private func getCurrentUser() {
        handle = auth.addStateDidChangeListener { (auth, user) in
            guard let currentUser = auth.currentUser else { return }
            let userRef = self.db.collection("users").document(currentUser.uid)
            userRef.getDocument { (document, error) in
                if let error = error {
                    debugPrint(error.localizedDescription)
                    return
                }
                if let document = document, document.exists {
                    guard let data = document.data() else { return }
                    self.user = User.init(data: data)
                    // self.welcomeLbl.text = self.user.email
                    // self.welcomeLbl.isHidden = false
                    
                    // user defaults
                    let defaults = UserDefaults.standard
                    defaults.set(self.user.nativeLanguage, forKey: "native_language")
                    defaults.set(self.user.notifications, forKey: "notifications")
                    defaults.set(Date(), forKey: "last_run")
                    
                    self.fetchWords(from: userRef)
                } else {
                    print("Document does not exist")
                }
            }
        }
    }
    
    private func fetchWords(from: DocumentReference) {
        let wordsRef = from.collection("words")
        
        wordsRef.getDocuments { (snapshot, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
                return
            }
            self.words.removeAll()
            guard let documents = snapshot?.documents else { return }
            for document in documents {
                let data = document.data()
                let word = Word.init(data: data)
                self.words.append(word)
            }
            // self.activityIndicator.stopAnimating()
            // self.wordsLbl.text = String(self.words.count)
            // self.wordsLbl.isHidden = false
        }
    }
    
    func makeWordDesk(size: Int, wordsData: [Word], _ result: [Word] = []) -> [Word] {
        var result = result
        if wordsData.count < 5 {
            return result
        }
        var tmpCount = size
        if tmpCount <= 0 {
            return result.shuffled()
        }
        let randomWord: Word = wordsData.randomElement() ?? wordsData[0]
        if !result.contains(where: { $0.id == randomWord.id }) {
            result.append(randomWord)
            tmpCount -= 1
        }
        return makeWordDesk(size: tmpCount, wordsData: wordsData, result)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - UICollectionViewDataSource

    /*
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    */

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return trainers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PracticeCVCell {
            let trainer = trainers[indexPath.row]
            cell.backgroundColor = trainer.backgroundColor
            cell.configureCell(cover: trainer.coverImageSource, title: trainer.title)
            return cell
        }
        return PracticeCVCell()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize = UIScreen.main.bounds
        return CGSize(width: screenSize.width - 40, height: 200)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sender = trainers[indexPath.row]
        performSegue(withIdentifier: Segues.PracticeRead, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.PracticeRead {
            if let practiceReadVC = segue.destination as? PracticeReadVC {
                if let sender = (sender as? PracticeTrainer) {
                    
                    // Hide the tabbar during this segue
                    hidesBottomBarWhenPushed = true

                    // Restore the tabbar when it's popped in the future
                    DispatchQueue.main.async { self.hidesBottomBarWhenPushed = false }
                    
                    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
                    self.navigationController?.navigationBar.shadowImage = UIImage()
                    self.navigationController?.navigationBar.isTranslucent = true
                    self.navigationController?.view.backgroundColor = .clear
                    
                    let backItem = UIBarButtonItem()
                    backItem.title = ""
                    self.navigationItem.backBarButtonItem = backItem
                    self.navigationController?.navigationBar.tintColor = UIColor.white
                    
                    let wordsDesk = makeWordDesk(size: 5, wordsData: words)
                    practiceReadVC.trainedWord = wordsDesk.randomElement()
                    practiceReadVC.wordsDesk = wordsDesk
                    
                    switch sender.controller {
                    case Controllers.TrainerWordToTranslate:
                        practiceReadVC.view.backgroundColor = .purple
                        practiceReadVC.practiceType = Controllers.TrainerWordToTranslate
                    case Controllers.TrainerTranslateToWord:
                        practiceReadVC.view.backgroundColor = .blue
                        practiceReadVC.practiceType = Controllers.TrainerTranslateToWord
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
