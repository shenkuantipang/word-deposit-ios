import UIKit
import FirebaseAuth
import FirebaseFirestore

class VocabulariesTVC: UITableViewController {

    // MARK: - Instances
    
    var vocabularies = [Vocabulary]()
    var selectedVocabularyIndex = 0
    
    var db: Firestore!
    var vocabulariesListener: ListenerRegistration!
    var userRef: DocumentReference!
    var vocabulariesRef: DocumentReference!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        setupTableView()
        
        guard let authUser = Auth.auth().currentUser else { return }
        userRef = db.collection("users").document(authUser.uid)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setVocabularyListener()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vocabulariesListener.remove()
        vocabularies.removeAll()
        tableView.reloadData()
    }
    
    // MARK: - Methods
    
    func setVocabularyListener() {
        // shoud be rewrited
//        guard let authUser = Auth.auth().currentUser else { return }
//        let userRef = db.collection("users").document(authUser.uid)
        let vocabulariesRef = userRef.collection("vocabularies").order(by: "timestamp", descending: true)
        vocabulariesListener = vocabulariesRef.addSnapshotListener({ (snapshot, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
                return
            }
            
            snapshot?.documentChanges.forEach({ (docChange) in
                let data = docChange.document.data()
                let vocabulary = Vocabulary.init(data: data)

                switch docChange.type {
                case .added:
                    self.onDocumentAdded(change: docChange, vocabulary: vocabulary)
                case .modified:
                    self.onDocumentModified(change: docChange, vocabulary: vocabulary)
                case .removed:
                    self.onDocumentRemoved(change: docChange)
                }
            })
        })
    }
    
    func onDocumentAdded(change: DocumentChange, vocabulary: Vocabulary) {
        let newIndex = Int(change.newIndex)
        vocabularies.insert(vocabulary, at: newIndex)
        tableView.insertRows(at: [IndexPath(item: newIndex, section: 0)], with: .fade)
    }
    
    func onDocumentModified(change: DocumentChange, vocabulary: Vocabulary) {
        if change.newIndex == change.oldIndex {
            let index = Int(change.newIndex)
            vocabularies[index] = vocabulary
            tableView.reloadRows(at: [IndexPath(item: index, section: 0)], with: .none)
        } else {
            let oldIndex = Int(change.oldIndex)
            let newIndex = Int(change.newIndex)
            vocabularies.remove(at: oldIndex)
            vocabularies.insert(vocabulary, at: newIndex)
            tableView.moveRow(at: IndexPath(item: oldIndex, section: 0), to: IndexPath(item: newIndex, section: 0))
        }
    }
    
    func onDocumentRemoved(change: DocumentChange) {
        let oldIndex = Int(change.oldIndex)
        vocabularies.remove(at: oldIndex)
        tableView.deleteRows(at: [IndexPath(item: oldIndex, section: 0)], with: .fade)
    }
    
    func setupTableView() {
        let nib = UINib(nibName: XIBs.VocabulariesTVCell, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: XIBs.VocabulariesTVCell)
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return vocabularies.count
    }

    func updateVocabulary(_ vocabulary: Vocabulary) {
        // TODO: - Refactoring
        guard let user = Auth.auth().currentUser else { return }
        vocabulariesRef = db.collection("users").document(user.uid).collection("vocabularies").document(vocabulary.id)
        print(vocabulary)
        let data = Vocabulary.modelToData(vocabulary: vocabulary)
        vocabulariesRef.setData(data, merge: true) { (error) in
            if let error = error {
                self.simpleAlert(title: "Error", msg: error.localizedDescription)
            }
            // success
            print("success")
        }
    }
    
    @objc func switchChaged(sender: UISwitch) {
        if sender.tag != selectedVocabularyIndex {
            
            print("sender ---> ", sender.tag)
            print("old one --> ", selectedVocabularyIndex)
            // update old one
            let oldIndex = selectedVocabularyIndex
            vocabularies[oldIndex].isSelected = false
            updateVocabulary(vocabularies[oldIndex])
            
            // update new one
            selectedVocabularyIndex = sender.tag
            print("changed --> ", selectedVocabularyIndex)
            var vocabulary = vocabularies[selectedVocabularyIndex]
            vocabulary.isSelected = true
            updateVocabulary(vocabulary)
            
            
            
            tableView.reloadData()
        } else {
            sender.isOn = true
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: XIBs.VocabulariesTVCell, for: indexPath) as? VocabulariesTVCell {
            let vocabulary = vocabularies[indexPath.row]
            cell.configureCell(vocabulary: vocabulary, userRef: userRef)
            cell.isSelectedVocabulary = false
            if vocabulary.isSelected == true {
                cell.isSelectedVocabulary = true
                selectedVocabularyIndex = indexPath.row
            }
            cell.selectionSwitch.tag = indexPath.row
            cell.selectionSwitch.addTarget(self, action: #selector(switchChaged(sender:)), for: .valueChanged)
            
            return cell
        }
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }


    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            vocabularies.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }


    // MARK: - Navigation

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Segues.VocabularyDetails, sender: indexPath.row)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vocabularyDetailsVC = segue.destination as? VocabularyDetailsVC {
            if let index = sender as? Int {
                vocabularyDetailsVC.vocabulary = vocabularies[index]
            }
        }
    }
}