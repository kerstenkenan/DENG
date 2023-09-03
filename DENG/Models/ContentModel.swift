//
//  ContentModel.swift
//  DENG
//
//  Created by Kersten Weise on 29.12.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import Foundation
import SwiftUI
import AVFoundation
import Speech
import CloudKit

enum States {
    case threeanswers
    case textfield
    case speech
}

enum VocabType: String, Codable {
    case ownVocab
    case sharedVocab
    case basicVocab
}

enum Language: String, Codable {
    case english
    case francais
}

struct Word : Codable {
    var id = UUID()
    var english: String
    var german: String
    var counter: Int
}

struct Score: Codable, Hashable {
    var date: String
    var points: Int
    var minutes: String
}

struct Vocab: Codable, Equatable {
    static func == (lhs: Vocab, rhs: Vocab) -> Bool {
        return lhs.id == rhs.id
    }
    var id: UUID
    var title: String
    var type: VocabType
    var words: [Word]
    var language: Language
    var checked: Bool
    var owner: String?
    var recordID: String?
    var fromiCloud: Bool
    var creationDate = Date()
}

struct ModifiedVocab: Codable {
    var id: UUID
    var vocType: VocabType
}

class ContentModel : ObservableObject {
    //MARK: Properties
    
    @Published var isHidden = true
    @Published var englishWord = ""
    @Published var germanWord = ""
    @Published var answers = ["First Answer", "Second Answer", "Third Answer"]
    @Published var answerButtons = [AnswerButton]()
    @Published var results = [Score]()
    @Published var points = 0
    @Published var time = "00:00"
    @Published var states : States = .threeanswers
    @Published var endTitleIsShowing = false
    @Published var speechNotReady = false
    @Published var resultsanswerButtonPressed = false
    @Published var wordColor = Color.black
    @Published var shouldSpringWord = false
    @Published var showGermanWord = false
    @Published var savedToiCloud = false
    @Published var showiCloudAlert = false
    @Published var serviceUnavailableAlert = false
    @Published var isPreparingSharing = false
    
    @State var scEffect = 1.0
    
    var timeButtons : [TimeButton]!
    
    @Published var basicVocabulary = [Vocab]()
    @Published var ownVocabulary = [Vocab]()
    @Published var sharedVocabulary = [Vocab]()
    var holeVocabulary : [Word]!
    var actualWordsList : [Word]?
    var actualWordIndex : Int!
    var actualWord : Word!
    var firstTime = true
    var vocabListIsShown = false
    
    
    var counting : AVAudioPlayer?
    var gameover : AVAudioPlayer?
    var win : AVAudioPlayer?
    var t : Timer?
    var applicationDirectory : URL? {
        return try? FileManager.default.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    //MARK: Speechrecognizer
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-GB"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var inputNode : AVAudioInputNode?
    var audioSession = AVAudioSession.sharedInstance()
    var session : AVCaptureSession?
    
    var speechSynthesizer : AVSpeechSynthesizer!
    
    var imageArr = ["🇬🇧", "→", "🇩🇪"]
    var counter = 0
    @Published var insideRound = false
    @Published var shouldReadAloud = true
    
    lazy var container = CKContainer(identifier: "iCloud.kw.DENG")
    private var notificationCenter : NotificationCenter?
    @Published var keyboardHeight : CGFloat = 0
    @Published var keyboardTime : Double = 0.0
    
    //MARK: Main initializer
    
    init() {
        notificationCenter = NotificationCenter.default
        notificationCenter!.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter!.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.timeButtons = [TimeButton(title: "5min", content: self), TimeButton(title: "10min", content: self), TimeButton(title: "20min", content: self)]
        
        try? counting = AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "counting", ofType: "m4a")!))
        counting?.volume = 0.1
        counting?.numberOfLoops = -1
        counting?.prepareToPlay()
        
        try? gameover = AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "gameover", ofType: "m4a")!))
        gameover?.volume = 0.1
        gameover?.prepareToPlay()
        
        try? win = AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "win", ofType: "m4a")!))
        win?.volume = 0.1
        win?.prepareToPlay()
    }
    
    deinit {
        notificationCenter?.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter?.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardHeight = keyboardRect.height
        }
        if let keyboardTimeToAppear = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber) {
            self.keyboardTime = keyboardTimeToAppear.doubleValue
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if notification.name == UIResponder.keyboardWillHideNotification {
            self.keyboardHeight = 0
        }
        if let keyboardTimeToDisappear = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber) {
            self.keyboardTime = keyboardTimeToDisappear.doubleValue
        }
    }
    
    
    // MARK: Choose word and check result
    
    private func convert(list: [[String: String]]) -> [Word] {
        var words = [Word]()
        list.forEach { element in
            element.forEach { (key, value) in
                words.append(Word(english: key, german: value, counter: 0))
            }
        }
        return words
    }
    
    private func getBasicVocabulary() {
        basicVocabulary = [Vocab(id: UUID(), title: "Basic vocabulary", type: .basicVocab, words: convert(list: Vocabulary.basics), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "Free time", type: .basicVocab, words: convert(list: Vocabulary.freeTime), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "At school", type: .basicVocab, words: convert(list: Vocabulary.atSchool), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "The body", type: .basicVocab, words: convert(list: Vocabulary.theBody), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "Food and Drink", type: .basicVocab, words: convert(list: Vocabulary.foodAndDrink), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "Time", type: .basicVocab, words: convert(list: Vocabulary.time), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "At home", type: .basicVocab, words: convert(list: Vocabulary.atHome), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "Places", type: .basicVocab, words: convert(list: Vocabulary.places), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "Weather", type: .basicVocab, words: convert(list: Vocabulary.weather), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "Animals", type: .basicVocab, words: convert(list: Vocabulary.animals), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "Shopping", type: .basicVocab, words: convert(list: Vocabulary.shopping), language: .english, checked: true, fromiCloud: false), Vocab(id: UUID(), title: "Clothes", type: .basicVocab, words: convert(list: Vocabulary.clothes), language: .english, checked: true, fromiCloud: false)]
    }
    
    private func makeWordList() -> [Word] {
        let vocabularies = [ownVocabulary, sharedVocabulary, basicVocabulary]
        var wordList = [Word]()
        
        vocabularies.forEach { voc in
            if !voc.isEmpty {
                voc.forEach { voc in
                    if voc.checked {
                        voc.words.forEach { entry in
                            wordList.append(entry)
                        }
                    }
                }
            }
        }
        
        if wordList.isEmpty {
            basicVocabulary.forEach { voc in
                voc.words.forEach { entry in
                    wordList.append(entry)
                }
            }
        }
        return wordList
    }
    
    
    func getAllWords() -> [Word] {
        var vocabulary = [Word]()
        for voc in basicVocabulary {
            voc.words.forEach { entry in
                vocabulary.append(entry)
            }
        }
        if !ownVocabulary.isEmpty {
            for voc in ownVocabulary {
                voc.words.forEach { entry in
                    vocabulary.append(entry)
                }
            }
        }
        if !sharedVocabulary.isEmpty {
            for voc in sharedVocabulary {
                voc.words.forEach { entry in
                    vocabulary.append(entry)
                }
            }
        }
        return vocabulary
    }
    
    func newWord() {
        print(#function)
        wordColor = .black
        shouldSpringWord = false
        if basicVocabulary.isEmpty {
            getBasicVocabulary()
        }
        holeVocabulary = getAllWords()
        actualWordsList = makeWordList()
        
        guard let actualWordsList = actualWordsList else {
            print("Couldn't generate a new word: \(String(describing: actualWordsList))")
            return
        }
        
        if let index = actualWordsList.indices.randomElement() {
            actualWordIndex = index
            actualWord = actualWordsList[index]
            englishWord = actualWord.english
            germanWord = actualWord.german
        }
        
        counter += 1
        let range1 = (7..<9)
        let range2 = (3..<5)
        let randomNumber1 = range1.randomElement()
        let randomNumber2 = range2.randomElement()
        if counter == randomNumber1! || counter == range1.max()! {
            states = .textfield
            counter = -1
        } else if counter == randomNumber2! || counter == range2.max()! {
            showGermanWord = false
            states = .speech
            counter = 4
        }  else {
            states = .threeanswers
        }
        
        guard let randomNum = (0...2).randomElement() else { return }
        if !showGermanWord {
            answers[randomNum] = germanWord
        } else {
            answers[randomNum] = englishWord
        }
        for i in 0..<answers.count {
            if i != randomNum {
                if !showGermanWord {
                    repeat
                    {
                        answers[i] = holeVocabulary.randomElement()!.german
                    } while answers[i] == answers[randomNum]
                } else {
                    repeat
                    {
                        answers[i] = holeVocabulary.randomElement()!.english
                    } while answers[i] == answers[randomNum]
                }
            }
        }
        self.answerButtons = [AnswerButton(content: self, title: answers[0]), AnswerButton(content: self, title: answers[1]), AnswerButton(content: self, title: answers[2])]
    }
    
    func checkText(text: String, id: UUID?, points: Int) {
        guard var actualWordsList = actualWordsList else {
            print("Couldn't check text.")
            return
        }
        if (showGermanWord ? englishWord : germanWord).lowercased().contains(text.lowercased()) {
            win?.play()
            if id != nil {
                for i in 0..<answerButtons.count {
                    if answerButtons[i].id == id {
                        answerButtons[i].backgroundColor = Color.green
                    } else {
                        answerButtons[i].backgroundColor = Color.red
                    }
                }
            } else {
                self.wordColor = .green
                self.shouldSpringWord = true
            }
            
            if actualWord.counter == 0 {
                if insideRound {
                    actualWordsList.remove(at: actualWordIndex)
                }
            } else {
                actualWord.counter -= 1
            }
            
            countPoints(points: points, handler: {
                if self.states == .textfield {
                    self.showGermanWord = true
                }
                self.newWord()
            })
        } else {
            gameover?.play()
            if id != nil {
                for i in 0..<answerButtons.count {
                    if (showGermanWord ? englishWord : germanWord).lowercased().contains(answerButtons[i].title.lowercased()) {
                        answerButtons[i].backgroundColor = Color.green
                    } else {
                        answerButtons[i].backgroundColor = Color.red
                    }
                }
            } else {
                self.wordColor = .red
                self.showGermanWord = true
                self.shouldSpringWord = true
            }
            
            switch actualWord.counter {
            case 0:
                actualWord.counter = 3
            default: actualWord.counter -= 1
            }
            
            countPoints(points: -points, handler: {
                self.newWord()
            })
        }
        if shouldReadAloud {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.readAloud(word: self.englishWord)
            }
        }
    }
    
    // MARK: Result methods
    
    func countPoints(points: Int, handler: @escaping () -> ()) {
        var timeSelected = false
        for timebutton in timeButtons {
            if timebutton.timeButtonModel.selected {
                timeSelected = true
                break
            } else {
                timeSelected = false
            }
        }
        
        if timeSelected {
            var counter = 0
            counting?.play()
            switch points {
            case ..<0:
                Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
                    counter -= 1
                    self.points -= 1
                    if self.points <= 0 {
                        self.points = 0
                        self.counting?.stop()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            handler()
                        }
                        timer.invalidate()
                    } else {
                        if counter <= points {
                            self.counting?.stop()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                handler()
                            }
                            timer.invalidate()
                        }
                    }
                }
            case 0...:
                Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
                    counter += 1
                    self.points += 1
                    if counter >= points {
                        self.counting?.stop()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            handler()
                        }
                        timer.invalidate()
                        
                    }
                }
            default: break
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                handler()
            }
        }
    }
    
    func setResults(min: String, handler: @escaping () -> ()) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "DE")
        results.append(Score(date: formatter.string(from: Date()), points: self.points, minutes: min))
        if let data = try? JSONEncoder().encode(results) {
            if let path = self.applicationDirectory?.appendingPathComponent("results.json") {
                do {
                    try data.write(to: path, options: Data.WritingOptions.atomic)
                } catch let error {
                    print("couldn't save: \(error)")
                }
            }
        }
        handler()
    }
    
    func getResults() {
        if let path = self.applicationDirectory?.appendingPathComponent("results.json") {
            if let jsonData = try? Data(contentsOf: path) {
                if let results = try? JSONDecoder().decode([Score].self, from: jsonData) {
                    self.results = results
                }
            }
        }
    }
    
    func deleteResults() {
        if let url = self.applicationDirectory {
            try? FileManager().removeItem(at: url)
        }
        results.removeAll()
    }
    
    // MARK: Speech
    
    func readAloud(word: String) {
        let speechUtterance = AVSpeechUtterance(string: word)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate -  0.15
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.speak(speechUtterance)
    }
    
    // MARK: The clock
    
    func timer(min: String) {
        if t != nil {
            t?.invalidate()
        }
        insideRound = true
        var minutes = min
        var sek = 0
        var minInteger = 0
        for _ in 0..<3 {
            minutes.removeLast()
        }
        minInteger = Int(minutes)!
        self.t = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.time = "\(String(format: "%02d", minInteger))" + ":" + "\(String(format: "%02d", sek))"
            
            sek -= 1
            if sek < 0 {
                sek = 59
                minInteger -= 1
            }
            
            if minInteger <= 0 && sek <= 0 {
                sek = 0
                minInteger = 0
                self.time = "\(String(format: "%02d", minInteger))" + ":" + "\(String(format: "%02d", sek))"
                self.setResults(min: min) {
                    self.endTitleIsShowing = true
                    self.resultsanswerButtonPressed.toggle()
                    for timebutton in self.timeButtons {
                        timebutton.timeButtonModel.selected = false
                    }
                    self.insideRound = false
                    timer.invalidate()
                }
            }
        })
    }
    
    //MARK: save funcs
    
    // Saves the vocabs
    
    func saveVocabularyToiCloud(voc: [Vocab]) {
        print("\(#function)")
        let database = voc.first!.type == .ownVocab ? self.container.privateCloudDatabase : self.container.sharedCloudDatabase
        guard !voc.isEmpty else {
            print("No vocab to save, voc ist empty.")
            return
        }
        for i in 0..<voc.count {
            guard let url = self.saveToDisk(voc: voc[i], into: voc[i].type.rawValue) else {
                print("Couldn't get an url from saveToDisk func.")
                break
            }
            let asset = CKAsset(fileURL: url)
            
            self.fetchOrInstallRecordZones(in: database) { result in
                switch result {
                case .success(let customZone):
                    if let vocabID = voc[i].recordID {
                        self.searchSingleRecord(in: database, recordZoneID: customZone.zoneID, recordID: vocabID) { result in
                            switch result {
                            case .success(let rec):
                                rec["asset"] = asset
                                self.saveToiCloud(record: rec, to: database) { result in
                                    switch result {
                                    case .success(let recordID):
                                        print("Successfully modified already existing \(voc[i].title) in iCloud.")
                                        switch voc[i].type {
                                        case .ownVocab:
                                            if let index = self.ownVocabulary.firstIndex(where: { $0.id == voc[i].id }) {
                                                DispatchQueue.main.async {
                                                    self.ownVocabulary[index].fromiCloud = true
                                                    self.ownVocabulary[index].recordID = recordID.recordName
                                                }
                                            } else {
                                                print("No index of specific vocab found in private database.")
                                            }
                                        case .sharedVocab:
                                            if let index = self.sharedVocabulary.firstIndex(where: { $0.id == voc[i].id }) {
                                                DispatchQueue.main.async {
                                                    self.sharedVocabulary[index].fromiCloud = true
                                                    self.sharedVocabulary[index].recordID = recordID.recordName
                                                }
                                            } else {
                                                print("No index of specific vocab found in shared database.")
                                            }
                                        default: break
                                        }
                                        
                                    case .failure(let err):
                                        print("Error modifying existing \(voc[i].title) in iCloud: \(err)")
                                    }
                                }
                            case .failure(let err):
                                print("Error finding record: \(err)")
                            }
                        }
                    } else {
                        let recordID = CKRecord.ID(zoneID: customZone.zoneID)
                        let newRecord = CKRecord(recordType: "OwnVocab", recordID: recordID)
                        newRecord["asset"] = asset
                        self.saveToiCloud(record: newRecord, to: database) { result in
                            switch result {
                            case .success(let recordID):
                                print("Successfully saved \(voc[i].title) into new record in iCloud.")
                                switch voc[i].type {
                                case .ownVocab:
                                    if let index = self.ownVocabulary.firstIndex(where: { $0.id == voc[i].id }) {
                                        DispatchQueue.main.async {
                                            self.ownVocabulary[index].fromiCloud = true
                                            self.ownVocabulary[index].recordID = recordID.recordName
                                        }
                                    } else {
                                        print("No index of specific vocab found in private database.")
                                    }
                                case .sharedVocab:
                                    if let index = self.sharedVocabulary.firstIndex(where: { $0.id == voc[i].id }) {
                                        DispatchQueue.main.async {
                                            self.sharedVocabulary[index].fromiCloud = true
                                            self.sharedVocabulary[index].recordID = recordID.recordName
                                        }
                                    } else {
                                        print("No index of specific vocab found in shared database.")
                                    }
                                default: break
                                }
                            case .failure(let err):
                                print("Error saving new record to iCloud: \(err)")
                            }
                        }
                    }
                case .failure(let err):
                    print("Couldn't save \(voc[i].title): \(err)")
                }
            }
        }
    }
    
    // Saves vocabularies to iCloud
    
    func saveToiCloud(record: CKRecord, to database: CKDatabase, completion: ((Result<CKRecord.ID, Error>) -> Void)? = nil) {
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.perRecordSaveBlock = { recordID, saveResult in
            switch saveResult {
            case .success(_):
                if let completion = completion {
                    completion(.success(recordID))
                }
            case .failure(let err):
                if let completion = completion {
                    completion(.failure(err))
                }
            }
        }
        database.add(operation)
    }
    
    
    func saveToDisk(voc: Vocab, into directory: String) -> URL? {
        var url : URL?
        if let folder = self.applicationDirectory?.appendingPathComponent(directory, isDirectory: true) {
            if !FileManager.default.fileExists(atPath: folder.path) {
                do {
                    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
                    print("Folder \(directory) successfully created: \(FileManager.default.fileExists(atPath: folder.path))")
                }
                catch {
                    print("Creating directory failed: \(error)")
                }
            }
            do {
                let data = try JSONEncoder().encode(voc)
                let file = folder.appendingPathComponent("\(voc.title.replacingOccurrences(of: " ", with: "").lowercased()).json", isDirectory: false)
                try data.write(to: file, options: Data.WritingOptions.atomic)
                url = file
                print("Successfully saved \(voc.title) in \(file)")
            }
            catch {
                print("Saving to disk failed: \(error)")
            }
        }
        return url ?? nil
    }

    
    private func searchSingleRecord(in database: CKDatabase, recordZoneID: CKRecordZone.ID, recordID: String, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let id = CKRecord.ID(recordName: recordID)
        let predicate = NSPredicate(format: "recordID = %@", id)
        let query = CKQuery(recordType: "OwnVocab", predicate: predicate)
        let queryOp = CKQueryOperation(query: query)
        queryOp.zoneID = recordZoneID
        queryOp.recordMatchedBlock = { _, result in
            switch result {
            case .success(let rec):
                print("Found single record: \(rec)")
                completion(.success(rec))
            case .failure(let err):
                print("Couldn't find single record: \(err)")
            }
        }
        queryOp.queryResultBlock = { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            default: break
            }
        }
        database.add(queryOp)
    }
    
    //MARK: fetching funcs
    
    // The getting funcs are build that if there's internet connectivity, then the vocabulary is taking from iCloud and if not then it is taken from the device.
    
    func getVocabulariesfromiCloud(withZone: CKRecordZone, complete: Bool = false, completion: ((Result<Void, Error>) -> Void)? = nil) {
        print(#function)
        var lastError : Error?
        var ownVocabFromiCloud = [Vocab]()
        var sharedVocabfromiCloud = [Vocab]()
        DispatchQueue.main.async {
            self.insideRound = true
        }
        fetchPrivateAndSharedVocabs(complete: complete, fromZone: withZone) { result in
            switch result {
            case .success((let privatVocabs, let sharedVocabs)):
                ownVocabFromiCloud = privatVocabs
                sharedVocabfromiCloud = sharedVocabs
                DispatchQueue.main.async {
                    self.ownVocabulary.removeAll()
                    self.sharedVocabulary.removeAll()
                    self.basicVocabulary.removeAll()
                    for i in 0..<ownVocabFromiCloud.count {
                        ownVocabFromiCloud[i].fromiCloud = true
                    }
                    for i in 0..<sharedVocabfromiCloud.count {
                        sharedVocabfromiCloud[i].fromiCloud = true
                    }
                    self.ownVocabulary = self.rmDuplicates(vocs: ownVocabFromiCloud)
                    self.sharedVocabulary = self.rmDuplicates(vocs: sharedVocabfromiCloud)
                    self.basicVocabulary = self.getVocsFromDisk(in: .basicVocab)
                    self.insideRound = false
                    
                    if let err = lastError {
                        if let completion = completion {
                            completion(.failure(err))
                        }
                    } else {
                        if let completion = completion {
                            completion(.success(()))
                        }
                    }
                }

            case .failure(let err):
                lastError = err
            }
        }
    }
    
    func getVocsFromDisk(in directory: VocabType) -> [Vocab] {
        print(#function)
        var vocabs = [Vocab]()
        
        if let vocabUrl = self.applicationDirectory?.appendingPathComponent(directory.rawValue, isDirectory: true) {
            if let files = try? FileManager.default.contentsOfDirectory(at: vocabUrl, includingPropertiesForKeys: nil) {
                do {
                    try files.forEach { file in
                        let jsonData = try Data(contentsOf: file)
                        vocabs.append(try JSONDecoder().decode(Vocab.self, from: jsonData))
                    }
                } catch {
                    print("Couldn't not decode files in \(directory.rawValue): \(error)")
                }
            }
        }
        for i in 0..<vocabs.count {
            vocabs[i].fromiCloud = false
        }
        return vocabs
    }
    
    
    func getVocab() {
        print(#function)
        self.fetchOrInstallRecordZones(in: container.privateCloudDatabase) { result in
            switch result {
            case .success(let zone):
                print("Zone there: \(zone)")
                self.getVocabulariesfromiCloud(withZone: zone, complete: true) { result in
                    switch result {
                    case .success():
                        DispatchQueue.main.async {
                            self.insideRound = false
                            self.newWord()
                        }
                    case .failure(let err):
                        print("Couldn't catch private or shared records: \(err.localizedDescription)")
                        if let ckerror = err as? CKError {
                            if ckerror.code == CKError.notAuthenticated || ckerror.code == CKError.networkUnavailable {
                                DispatchQueue.main.async {
                                    self.showiCloudAlert = true
                                    self.insideRound = false
                                }
                            } else if ckerror.code == .serviceUnavailable {
                                DispatchQueue.main.async {
                                    self.serviceUnavailableAlert = true
                                }
                            }
                        }
                    }
                }
                
            case .failure(let err):
                print("Couldn't fetch record-zones: \(err.localizedDescription)")
                if let ckerror = err as? CKError {
                    if ckerror.code == CKError.notAuthenticated || ckerror.code == CKError.networkUnavailable {
                        DispatchQueue.main.async {
                            self.showiCloudAlert.toggle()
                        }
                    } else if ckerror.code == .serviceUnavailable {
                        DispatchQueue.main.async {
                            self.serviceUnavailableAlert = true
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.ownVocabulary = self.getVocsFromDisk(in: .ownVocab)
                    self.sharedVocabulary = self.getVocsFromDisk(in: .sharedVocab)
                    self.basicVocabulary = self.getVocsFromDisk(in: .basicVocab)
                    self.newWord()
                }
            }
        }
    }
    
    private func fetchRecords(scope: CKDatabase.Scope, zones: [CKRecordZone], complete: Bool, completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let database = container.database(with: scope)
        
        let zoneIDs = zones.map { $0.zoneID }
        var configurations : [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneConfiguration]?
        zoneIDs.forEach { zoneID in
            let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            var url : URL?
            switch scope {
            case .private:
                if let pathUrl = self.applicationDirectory?.appendingPathComponent("PrivateChangeToken") {
                    url = pathUrl
                }
            case .shared:
                if let pathUrl = self.applicationDirectory?.appendingPathComponent("SharedChangeToken") {
                    url = pathUrl
                }
            default: break
            }
            if !complete {
                config.previousServerChangeToken = self.firstTime ? nil : self.getToken(at: url ?? nil)
                print("PreviousToken: \(String(describing: config.previousServerChangeToken))")
                configurations?[zoneID] = config
            }
        }
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs,
                                                          configurationsByRecordZoneID: configurations)
        var records : [CKRecord] = []
        
        operation.recordWasChangedBlock = { _, result in
            switch result {
            case .success(let rec):
                if rec.recordType == "OwnVocab" {
                    records.append(rec)
                }
            case .failure(let err):
                print("No records fetched: \(err)")
            }
        }
        operation.fetchRecordZoneChangesResultBlock = { result in
            switch result {
            case .success():
                completion(.success(records))
            case .failure(let err):
                completion(.failure(err))
            }
        }
        operation.recordZoneChangeTokensUpdatedBlock = { _, tok, _ in
            if scope == .private {
                if let url = self.applicationDirectory?.appendingPathComponent("PrivateChangeToken"), let tok = tok {
                    self.setToken(tok, to: url)
                    self.firstTime = false
                }
            } else if scope == .shared {
                if let url = self.applicationDirectory?.appendingPathComponent("SharedChangeToken"), let tok = tok {
                    self.setToken(tok, to: url)
                    self.firstTime = false
                }
            }
        }
        operation.recordZoneFetchResultBlock = { recordZoneID, result in
            switch result {
            case .success((let tok, _, _)):
                if scope == .private {
                    if let url = self.applicationDirectory?.appendingPathComponent("PrivateChangeToken") {
                        self.setToken(tok, to: url)
                        self.firstTime = false
                    }
                } else if scope == .shared {
                    if let url = self.applicationDirectory?.appendingPathComponent("SharedChangeToken") {
                        self.setToken(tok, to: url)
                        self.firstTime = false
                    }
                }
            case .failure(let err):
                print("Couldn't fetch records in \(scope) database: \(err)")
            }

        }
        database.add(operation)
    }
    
    func fetchSingleRecord(with recordID: CKRecord.ID, in scope: CKDatabase.Scope, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let database = container.database(with: scope)
        let op = CKFetchRecordsOperation(recordIDs: [recordID])
        op.perRecordResultBlock = { rec, result in
            switch result {
            case .success(let rec):
                completion(.success(rec))
            case .failure(let err):
                completion(.failure(err))
            }
        }
        database.add(op)
    }
    
    private func fetchSharedRecords(complete: Bool, completionHandler: @escaping (Result<[CKRecord], Error>) -> Void) {
        // The first step is to fetch all available record zones in user's shared database.
        container.sharedCloudDatabase.fetchAllRecordZones { zones, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let zones = zones, !zones.isEmpty {
                // Fetch all Contacts in the set of zones in the shared database.
                self.fetchRecords(scope: .shared, zones: zones, complete: complete, completion: completionHandler)
            } else {
                // Zones nil or empty so no shared contacts.
                completionHandler(.success([]))
            }
        }
    }
    
    func fetchPrivateAndSharedVocabs(complete: Bool, fromZone: CKRecordZone, completion: @escaping (Result<([Vocab], [Vocab]), Error>) -> Void) {
        let group = DispatchGroup()
        var privatVocabs = [Vocab]()
        var sharedVocabs = [Vocab]()
        
        var lastError : Error?
        
        group.enter()
        fetchRecords(scope: .private, zones: [fromZone], complete: complete) { recordsResult in
            switch recordsResult {
            case .success(let records):
                print("\(#function) Private records from iCloud: \(records.count)")
                if !records.isEmpty {
                    privatVocabs = self.extractVocab(records: records)
                }
                group.leave()
            case .failure(let err):
                print("Fetching private records failed: \(err)")
                group.leave()
            }
        }
        
        group.enter()
        fetchSharedRecords(complete: complete) { result in
            switch result {
            case .success(let records):
                print("\(#function) Shared records from iCloud: \(records.count)")
                guard !records.isEmpty else {
                    group.leave()
                    return
                }
                var namesAndIDs = [String : String]()
                var urls = [URL]()
                records.forEach { rec in
                    guard let share = rec.share else {
                        print("Record \(rec) has no share.")
                        return
                    }
                    self.container.sharedCloudDatabase.fetch(withRecordID: share.recordID) { shareRec, err in
                        if let err = err {
                            print("Fetching shareID failed: \(err)")
                        } else {
                            if let shareRec = shareRec, let share = shareRec as? CKShare, let shareurl = share.url {
                                urls.append(shareurl)
                                let op = CKFetchShareMetadataOperation(shareURLs: urls)
                                op.perShareMetadataResultBlock = { _, result in
                                    switch result {
                                    case .success(let metadata):
                                        if let name = metadata.ownerIdentity.nameComponents?.givenName {
                                            namesAndIDs[name] = rec.recordID.recordName
                                        }
                                    case .failure(let err):
                                        print("Couldn't get the ownder name: \(err)")
                                    }
                                    sharedVocabs = self.extractVocab(records: [rec])
                                    for (name, id) in namesAndIDs {
                                        for i in 0..<sharedVocabs.count {
                                            sharedVocabs[i].type = .sharedVocab
                                            if sharedVocabs[i].recordID == id {
                                                sharedVocabs[i].owner = name
                                            }
                                        }
                                    }
                                }
                                op.fetchShareMetadataResultBlock = { result in
                                    switch result {
                                    case .failure(let err):
                                        print("Fechting metadata failed: \(err)")
                                    default: break
                                    }
                                    group.leave()
                                }
                                self.container.add(op)
                            }
                            
                        }
                    }
                }
            case .failure(let err):
                lastError = err
            }
        }
        group.notify(queue: .main) {
            if let lastError = lastError {
                completion(.failure(lastError))
            } else {
                completion(.success((privatVocabs,sharedVocabs)))
                
            }
        }
    }
    
    func extractVocab(records: [CKRecord]) -> [Vocab] {
        var vocabs = [Vocab]()
        records.forEach { record in
            if let asset = record["asset"] as? CKAsset {
                if let data = try? Data(contentsOf: asset.fileURL!) {
                    do {
                        var singleVocab = try JSONDecoder().decode(Vocab.self, from: data)
                        singleVocab.recordID = record.recordID.recordName
                        vocabs.append(singleVocab)
                    } catch {
                        print("Failed to extract vocab from record: \(record.recordID)")
                    }
                }
            }
        }
        return vocabs
    }
    
    func fetchOrInstallRecordZones(in database: CKDatabase, completion: @escaping (Result<CKRecordZone, Error>) -> Void) {
        self.subscribe(to: .private) { err in
            if let err = err {
                DispatchQueue.main.async {
                    self.showiCloudAlert = true
                }
                print("Couldn't subcribe to private db: \(err)")
            }
        }
        self.subscribe(to: .shared) { err in
            if let err = err {
                DispatchQueue.main.async {
                    self.showiCloudAlert = true
                }
                print("Couldn't subcribe to shared db: \(err)")
            }
        }
        
        database.fetchAllRecordZones { zones, err in
            var fetchedZones = [CKRecordZone]()
            if let zones = zones {
                
                if let i = zones.firstIndex(where: { $0.zoneID.zoneName == "customZone" }) {
                    completion(.success(zones[i]))
                } else {
                    let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [CKRecordZone(zoneName: "customZone")])
                    
                    createZoneOperation.perRecordZoneSaveBlock = { recordID, result in
                        switch result {
                        case .success(let zone):
                            fetchedZones.append(zone)
                        case .failure(let err):
                            print("Single zone couldn't be fetched: \(err)")
                        }
                    }
                    
                    createZoneOperation.modifyRecordZonesResultBlock = { result in
                        switch result {
                        case .success():
                            if let i = fetchedZones.firstIndex(where: { $0.zoneID == CKRecordZone.ID(zoneName: "customZone")}) {
                                print("Successfully installed customZone.")
                                completion(.success(zones[i]))
                            }
                        case .failure(let err):
                            completion(.failure(err))
                        }
                    }
                    database.add(createZoneOperation)
                }
            }
        }
    }

    // MARK: Deletion
    
    func delete(recordID: CKRecord.ID, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        let database = CKContainer.default().database(with: .private)
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
        
        operation.perRecordDeleteBlock = { recID, result in
            switch result {
            case .success():
                completion(.success(recID))
            case .failure(let err):
                completion(.failure(err))
            }
        }
        database.add(operation)
    }
    
    func deleteFileFromDisk(voc: Vocab) {
        if let path = self.applicationDirectory?.appendingPathComponent(voc.type.rawValue, isDirectory: true).appendingPathComponent("\(voc.title.replacingOccurrences(of: " ", with: "").lowercased()).json") {
            do {
                try FileManager.default.removeItem(at: path)
                print("Successfully removed file locally: \(voc.title)")
            } catch let err {
                print("Could not remove local file: \(err)")
            }
        }
    }
    
    func delete(zoneIDs: [CKRecordZone.ID]) {
        if let path = self.applicationDirectory?.appendingPathComponent(self.ownVocabulary.first!.type.rawValue, isDirectory: true).path {
            do {
                try FileManager.default.removeItem(atPath: path)
                print("Successfully deleted all ownVocabs from disk.")
            } catch {
                print("Deleting local files failed: \(error)")
            }
        }
        let database = CKContainer.default().database(with: .private)
        let op = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: zoneIDs)
        
        op.perRecordZoneDeleteBlock = { zID, result in
            switch result {
            case .success():
                print("Deleted ID: \(zID))")
                DispatchQueue.main.async {
                    self.ownVocabulary.removeAll()
                }
                UserDefaults.standard.setValue(false, forKey: "recordZoneIsCreated")
            case .failure(let err):
                print("Deleting zone with ID \(zID) failed: \(err)")
            }
        }
        database.add(op)
    }
    
    private func getToken(at url: URL?) -> CKServerChangeToken?  {
        guard let url = url else {
            print("Getting the token failed.")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let coder = try NSKeyedUnarchiver(forReadingFrom: data)
            return coder.decodeObject(of: CKServerChangeToken.self, forKey: "token")
        } catch {
            print("Getting token failed: \(error)")
        }
        return nil
    }
    
    private func setToken(_ token: CKServerChangeToken, to url: URL) {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        coder.encode(token, forKey: "token")
        let data = coder.encodedData
        do {
            try data.write(to: url)
        } catch {
            print("Saving token failed: \(error)")
        }
    }
    
    private func subscribe(to scope: CKDatabase.Scope, completion: @escaping (Error?) -> Void) {
        var key = String()
        switch scope {
        case .private:
            key = "didCreatePrivateSubscription"
        case .shared:
            key = "didCreateSharedSubscription"
        default:break
        }
        guard !UserDefaults.standard.bool(forKey: key) else {
            print(key)
            return
        }
        
        var database = String()
        switch scope {
        case .private:
            database = "privateSubscription"
        case .shared:
            database = "sharedSubscription"
        default: break
        }
        let subscription = CKDatabaseSubscription(subscriptionID: database)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "Your \(scope == .private ? "privat" : "shared") vocabularies have been changed. Have a look ;)."
        notificationInfo.shouldBadge = false
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.soundName = "default"
        subscription.notificationInfo = notificationInfo
    
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        
        operation.perSubscriptionSaveBlock = { subID, result in
            switch result {
            case .success(_):
                print("Successfully saved subscription: \(subID)) to database: \(database)")
            case .failure(let err):
                print("Couldn't saved subcription: with ID \(subID): \(err)")
            }
        }
        operation.modifySubscriptionsResultBlock = { result in
            switch result {
            case .success():
                UserDefaults.standard.setValue(true, forKey: key)
            case .failure(let err):
                DispatchQueue.main.async {
                    self.showiCloudAlert = true
                    self.insideRound = false
                }
                completion(err)
            }
        }
        operation.qualityOfService = .utility
        container.database(with: scope).add(operation)
    }
    
    private func rmDuplicates(vocs: [Vocab]) -> [Vocab] {
        var vocabIDs = [UUID]()
        var finalVocabs = [Vocab]()
        for i in 0..<vocs.count {
            if !vocabIDs.contains(vocs[i].id) {
                vocabIDs.append(vocs[i].id)
                finalVocabs.append(vocs[i])
            }
        }
        return finalVocabs
    }
}
