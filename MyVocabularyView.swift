//
//  MyVocabularyView.swift
//  DENG
//
//  Created by Kersten Weise on 20.04.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import SwiftUI
import CloudKit
import Network

class MyVocabularyModel : ObservableObject {
    @Published var title : String = ""
    @Published var list = [Word]()
    @Published var allFilled = false
    @Published var showAlert = false
    @Published var original : String = ""
    @Published var german : String = ""
}

struct MyVocabularyView: View {
    @StateObject var model = MyVocabularyModel()
    @EnvironmentObject var contentModel : ContentModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var presentAlert = false
    @State private var somethingChanged = false
    @State private var animationOpacity = 0.0
    
    var title: String
    var list: [Word]
    var id: UUID?
    var recordID: String?
    var type: VocabType
    var owner: String?
    var language: Language
    
    init(title: String, list: [Word], id: UUID?, recordID: String?, type: VocabType, owner: String?, language: Language) {
        self.title = title
        self.list = list
        if let id = id {
            self.id = id
        }
        if let recordID = recordID {
            self.recordID = recordID
        }
        self.type = type
        if let owner = owner {
            self.owner = owner
        }
        self.language = language
        
        if #unavailable(iOS 16.0) {
            UITableView.appearance().backgroundColor = .clear
        }
    }
    
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            VStack {
                VStack {
                    Text("Own vocabulary").font(.largeTitle).foregroundColor(.white).bold().minimumScaleFactor(0.3)
                    TextField("Enter title here", text: self.$model.title, onEditingChanged: { changed in
                        if changed {
                            self.somethingChanged = true
                        }
                    }).foregroundColor(.white).font(.largeTitle).multilineTextAlignment(.center).minimumScaleFactor(0.3)
                }
                VStack {
                    Divider()
                    HStack {
                        TextField(self.contentModel.chosenLanguage == .english ? "Word" : "Mot", text: self.$model.original, onCommit: {
                            self.model.list.append(Word(original: self.$model.original.wrappedValue, german: self.$model.german.wrappedValue))
                            self.model.original = ""
                            self.model.german = ""
                            self.somethingChanged = true
                        }).foregroundColor(Color.white).autocapitalization(.none).disableAutocorrection(true)
                        Spacer()
                        TextField("Übersetzung", text: self.$model.german, onCommit: {
                            self.model.list.append(Word(original: self.$model.original.wrappedValue, german: self.$model.german.wrappedValue))
                            self.model.original = ""
                            self.model.german = ""
                            self.somethingChanged = true
                        }).multilineTextAlignment(.trailing).foregroundColor(Color.white).autocapitalization(.none).disableAutocorrection(true)
                    }
                    Divider()
                    HStack {
                        Spacer()
                        Button(action: {
                            if !self.model.original.isEmpty && !self.model.german.isEmpty {
                                self.model.list.append(Word(original: self.$model.original.wrappedValue, german: self.$model.german.wrappedValue))
                                self.model.original = ""
                                self.model.german = ""
                                self.somethingChanged = true
                                UIApplication.shared.endEditing()
                            }
                        }) {
                            Image(systemName: "plus.circle").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(Color.yellow)
                        }
                    }
                }.padding()
                if self.model.list.isEmpty {
                    Spacer()
                } else {
                    List {
                        ForEach(self.model.list, id: \.id) { row in
                            HStack {
                                Text("\(row.original)").foregroundColor(.white)
                                Spacer()
                                Text("\(row.german)").foregroundColor(.white)
                            }.padding().listRowBackground(Color.blue)
                        }.onDelete { pos in
                            self.model.list.remove(atOffsets: pos)
                            self.somethingChanged = true
                        }
                        .listStyle(GroupedListStyle())
                    }
                    .clearListBackground()
                }
            }.onAppear {
                self.model.title = self.title
                self.model.list = self.list
            }
            .onDisappear {
                if self.somethingChanged {
                    let newVoc = Vocab(id: self.id ?? UUID(), title: self.model.title.isEmpty ? "No title" : self.model.title, type: self.type, words: self.model.list, language: language, checked: false, owner: self.owner, recordID: self.recordID, fromiCloud: false)
                    if let idThere = self.id {
                        switch type {
                        case .ownVocab:
                            if let index = self.contentModel.ownVocabulary.firstIndex(where: { idThere == $0.id }) {
                                DispatchQueue.main.async {
                                    self.contentModel.ownVocabulary.remove(at: index)
                                    self.contentModel.ownVocabulary.insert(newVoc, at: index)
                                    self.contentModel.saveVocabularyToiCloud(voc: [self.contentModel.ownVocabulary[index]])
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.contentModel.ownVocabulary.append(newVoc)
                                    self.contentModel.saveVocabularyToiCloud(voc: [self.contentModel.ownVocabulary.last!])
                                }
                            }
                            
                        case .sharedVocab:
                            if let index = self.contentModel.sharedVocabulary.firstIndex(where: { idThere == $0.id }) {
                                DispatchQueue.main.async {
                                    self.contentModel.sharedVocabulary.remove(at: index)
                                    self.contentModel.sharedVocabulary.insert(newVoc, at: index)
                                    self.contentModel.saveVocabularyToiCloud(voc: [self.contentModel.sharedVocabulary[index]])
                                }
                            }
                        default: break
                        }
                    } else {
                        self.contentModel.ownVocabulary.append(newVoc)
                        self.contentModel.saveVocabularyToiCloud(voc: [newVoc])
                    }
                }
            }
        }
        .alert(isPresented: $presentAlert, content: {
            Alert(title: Text("Hey there!"), message: Text("Please fill in all text field"), dismissButton: .default(Text("OK")))
        })
    }
}


struct MyVocabularyView_Previews: PreviewProvider {
    static var previews: some View {
        MyVocabularyView(title: "title", list: [Word(original: "test", german: "Test")], id: UUID(), recordID: "Bla", type: .ownVocab, owner: "Kersten", language: .english)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
