//
//  VocabulariesView.swift
//  DENG
//
//  Created by Kersten Weise on 18.03.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import SwiftUI
import CloudKit
import UIKit

struct VocabulariesView: View {
    
    @EnvironmentObject var contentModel : ContentModel
    @Environment(\.presentationMode) var presentationMode
    @State private var ownVocViewShown = false
    @State private var editButtonPushed = false
    @State private var sharedEditButtonPushed = false
    @State private var showICloudAlert = false
    @State private var shareButtonPressedPrivate = false
    @State private var shareButtonPressedShared = false
    @State private var activeShare: CKShare?
    @State private var deleteAllAlert = false
    @State private var viewOpacity = 0.0
    
    init() {
        if #unavailable(iOS 16.0) {
            UITableView.appearance().backgroundColor = .clear
            UINavigationBar.appearance().backgroundColor = .clear
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Group {
                        sharedVocabulary
                        localVocabulary
                    }.opacity(viewOpacity)
                        .onAppear() {
                            withAnimation(.linear(duration: 1.0)) {
                                viewOpacity = 1
                            }
                        }
                    basicVocabulary
                        
                }.listRowBackground(Color.blue).listStyle(GroupedListStyle()).clearListBackground().buttonStyle(BorderlessButtonStyle())
            }.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Group {
                        if contentModel.isPreparingSharing {
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                }
            }.background(.blue)
                .navigationBarTitle("Themes").navigationBarItems(trailing: NavigationLink(destination: MyVocabularyView(title: "", list: [Word](), id: nil, recordID: nil, type: .ownVocab, owner: nil, language: .english), isActive: self.$ownVocViewShown, label: {
                Image(systemName: "plus.circle").font(.system(size: 25)).foregroundColor(Color.white)
                }))
            .alert(isPresented: $showICloudAlert, content: {
                Alert(title: Text("iCloud-Error"), message: Text("Please get to the settings of your device and enable iCloud for this App. \n\nBitte gehe zu den Einstellungen deines Geräts und aktiviere iCloud für diese App."), dismissButton: .default(Text("OK")))
            })
            
        }.accentColor(Color.white)
        .onAppear() {
            if UIApplication.shared.applicationIconBadgeNumber > 0 {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
        .onDisappear {
            self.contentModel.basicVocabulary.forEach { voc in
                let _ = self.contentModel.saveToDisk(voc: voc, into: voc.type.rawValue)
            }
        }
    }
    
    
    //MARK: Functions
    
    func shareRecord(share: CKRecord.Reference? = nil, record: CKRecord? = nil, title: String? = nil, in databaseScope: CKDatabase.Scope, completionHandler: @escaping () -> Void) {
        print("\(#function)")
        var records = [CKRecord]()
        let database = contentModel.container.database(with: databaseScope)
        DispatchQueue.main.async {
            contentModel.isPreparingSharing = true
        }
        if let share = share {
            database.fetch(withRecordID: share.recordID) { record, err in
                guard let shareRecord: CKShare = record as? CKShare else {
                    if let error = err {
                        print("Couldn't fetch shared record with id \(share.recordID): \(error)")
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.activeShare = shareRecord
                    contentModel.isPreparingSharing = false
                    completionHandler()
                }
            }
        } else if let record = record, let title = title {
            let newShare = CKShare(rootRecord: record)
            newShare[CKShare.SystemFieldKey.title] = "\(title) vocabulary to share"
            newShare.publicPermission = .readWrite
            
            let operation = CKModifyRecordsOperation(recordsToSave: [record, newShare])
            operation.perRecordSaveBlock = { recordID, result in
                switch result {
                case .success(let rec):
                    records.append(rec)
                case .failure(let err):
                    print("Couldn't create a new share: \(err)")
                }
            }
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success():
                    DispatchQueue.main.async {
                        records.forEach({ record in
                            if let shareThere = record as? CKShare {
                                self.activeShare = shareThere
                                contentModel.isPreparingSharing = false
                                completionHandler()
                            }
                        })
                    }
                case .failure(let err):
                    print("No records to share: \(err)")
                }
            }
            database.add(operation)
        }
    }
    
    private func makeString(outOf date: Date) -> String {
        var theDate = String()
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .short
        if Calendar.current.isDateInToday(date) {
            theDate = "Today, \(formatter.string(from: date))"
        } else {
            theDate = formatter.string(from: date)
        }
        return theDate
    }
    
    //MARK: Shared Vocabulary Stack
    
    private var sharedVocabulary: some View {
        Section() {
            ForEach(self.contentModel.sharedVocabulary.sorted(by: { return $0.creationDate > $1.creationDate }), id: \.id) { voc in
                Group {
                    if sharedEditButtonPushed && voc.fromiCloud {
                        NavigationLink(destination: MyVocabularyView(title: voc.title, list: voc.words, id: voc.id, recordID: voc.recordID, type: .sharedVocab, owner: voc.owner, language: voc.language).onAppear() {
                            UINavigationBar.appearance().backgroundColor = UIColor(#colorLiteral(red: 0.2148060138, green: 0.5517488729, blue: 1, alpha: 1))
                            UITableView.appearance().backgroundColor = UIColor(#colorLiteral(red: 0.2148060138, green: 0.5517488729, blue: 1, alpha: 1))
                            
                        }) {
                            HStack {
                                Text(voc.title).foregroundColor(.black).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded))
                            }
                        }
                    } else {
                        HStack() {
                            Text(voc.title).foregroundColor(.black).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded))
                            Spacer()
                            VStack {
                                Text(makeString(outOf: voc.creationDate))
                                if let owner = voc.owner {
                                    Text("from: \(owner)").foregroundColor(.black).font(.system(size: 16, weight: Font.Weight.light, design: Font.Design.rounded))
                                }
                            }
                            Button {
                                DispatchQueue.main.async {
                                    if let index = self.contentModel.sharedVocabulary.firstIndex(where: { $0.id == voc.id }) {
                                        self.contentModel.sharedVocabulary[index].checked.toggle()
                                    }
                                }
                            } label: {
                                Image(systemName: "checkmark").frame(width: 20, alignment: .center).foregroundColor(voc.checked ? .green : .gray).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded))
                            }
                            Button {
                                if let recIDName = voc.recordID {
                                    self.contentModel.container.sharedCloudDatabase.fetchAllRecordZones { zones, error in
                                        if let err = error {
                                            print("Fetching shared zones failed: \(err)")
                                        } else {
                                            if let zones = zones {
                                                if let i = zones.firstIndex(where: { $0.zoneID.zoneName == "customZone"}) {
                                                    let recordID = CKRecord.ID(recordName: recIDName, zoneID: zones[i].zoneID)
                                                    self.contentModel.fetchSingleRecord(with: recordID, in: .shared) { result in
                                                        switch result {
                                                        case .success(let rec):
                                                            self.shareRecord(share: rec.share, in: .shared) {
                                                                self.shareButtonPressedShared.toggle()
                                                            }
                                                        case .failure(let err):
                                                            print("Fetching single private record failed: \(err.localizedDescription)")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: self.contentModel.savedToiCloud ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.plus").frame(width: 30, alignment: .center).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded)).foregroundColor(.white)
                            }.sheet(isPresented: $shareButtonPressedShared) {
                                if let activeShare = self.activeShare {
                                    UIKitCloudKitSharingViewController(share: activeShare).background(.white)
                                        .onDisappear {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                self.contentModel.getVocab()
                                            }
                                        }
                                }
                            }
                        }
                    }
                }.listRowBackground(Color(#colorLiteral(red: 0.2148060138, green: 0.5517488729, blue: 1, alpha: 1)))
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 1.5)))
            }
        } header: {
            if !contentModel.sharedVocabulary.isEmpty {
                HStack {
                    Text("Shared Vocabulary").font(.headline).bold().foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        self.sharedEditButtonPushed.toggle()
                    }) {
                        Text(self.sharedEditButtonPushed ? "SELECT" : "EDIT").font(.headline).bold().foregroundColor(.yellow)
                    }
                }
                .listRowBackground(Color(.clear))
            }
        }
    }
    
    
    //MARK: Own Vocabulary Stack
    
    private var ownVocabularyHeader: some View {
        HStack {
            Text("Own Vocabulary").font(.headline).bold().foregroundColor(.white)
            Button {
                self.deleteAllAlert.toggle()
            } label: {
                Image(systemName: "xmark.circle.fill").frame(width: 20, alignment: .center).font(.system(size: 15, weight: Font.Weight.bold, design: Font.Design.rounded)).foregroundColor(Color.white)
            }.alert(isPresented: $deleteAllAlert) {
                Alert(title: Text("Attention"), message: Text("This will delete all your private vocabularies. This can't be undone!"), primaryButton: Alert.Button.default(Text("OK"), action: {
                    let zoneID = CKRecordZone(zoneName: "customZone").zoneID
                    self.contentModel.delete(zoneIDs: [zoneID])
                }), secondaryButton: Alert.Button.cancel())
            }
            Spacer()
            Button(action: {
                self.editButtonPushed.toggle()
            }) {
                Text(self.editButtonPushed ? "SELECT" : "EDIT").font(.headline).bold().foregroundColor(.yellow)
            }
        }
    }
    
    private var ownVocabulary: some View {
        ForEach(self.contentModel.ownVocabulary.sorted(by: { return $0.creationDate > $1.creationDate }), id: \.id) { voc in
            Group {
                if self.editButtonPushed && voc.fromiCloud {
                    NavigationLink(destination: MyVocabularyView(title: voc.title, list: voc.words, id: voc.id, recordID: voc.recordID, type: .ownVocab, owner: voc.owner, language: voc.language)) {
                        HStack {
                            Text(voc.title).foregroundColor(.black).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded))
                        }
                    }
                } else {
                    HStack {
                        Text(voc.title).foregroundColor(.black).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded))
                        Spacer()
                        Text(makeString(outOf: voc.creationDate))
                        Button {
                            DispatchQueue.main.async {
                                if let index = self.contentModel.ownVocabulary.firstIndex(where:  { $0.id == voc.id }) {
                                    self.contentModel.ownVocabulary[index].checked.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: "checkmark").frame(width: 20, alignment: .center).foregroundColor(voc.checked ? .green : .gray).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded))
                        }
                        Image(systemName: voc.fromiCloud ? "externaldrive.badge.icloud" : "externaldrive.badge.checkmark").frame(width: 30, alignment: .center).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded)).foregroundColor(.white)
                        Button {
                            if let recIDName = voc.recordID {
                                let recordZone = CKRecordZone(zoneName: "customZone")
                                let recordID = CKRecord.ID(recordName: recIDName, zoneID: recordZone.zoneID)
                                self.contentModel.fetchSingleRecord(with: recordID, in: .private) { result in
                                    switch result {
                                    case .success(let rec):
                                        if let shareThere = rec.share {
                                            self.shareRecord(share: shareThere, in: .private) {
                                                self.shareButtonPressedPrivate.toggle()
                                            }
                                        } else {
                                            self.shareRecord(record: rec, title: voc.title, in: .private) {
                                                self.shareButtonPressedPrivate.toggle()
                                            }
                                        }
                                    case .failure(let err):
                                        print("Fetching single private record failed: \(err.localizedDescription)")
                                    }
                                }
                                
                            }
                        } label: {
                            Image(systemName: self.contentModel.savedToiCloud ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.plus").frame(width: 30, alignment: .center).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded)).foregroundColor(.white)
                        }.sheet(isPresented: $shareButtonPressedPrivate) {
                            UIKitCloudKitSharingViewController(share: self.activeShare!).background(.white)
                                .onDisappear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        self.contentModel.getVocab()
                                    }
                                }
                        }
                    }
                }
            }
        }.onDelete { pos in
            guard let index = pos.first else {
                print("Couldn't find index for deletion")
                return
            }
            let vocab = self.contentModel.ownVocabulary[index]
            
            self.contentModel.deleteFileFromDisk(voc: vocab)
            if let recordIDName = vocab.recordID {
                let zone = CKRecordZone(zoneName: "customZone")
                let recordID = CKRecord.ID(recordName: recordIDName, zoneID: zone.zoneID)
                self.contentModel.delete(recordID: recordID) { result in
                    switch result {
                    case .success(let id):
                        print("Successfully deleted record from iCloud with id: \(id))")
                    case .failure(let err):
                        print("Could not delete record from iCloud: \(err)")
                    }
                }
                DispatchQueue.main.async {
                    self.contentModel.ownVocabulary.remove(atOffsets: pos)
                }
            }
        }
    }
    
    
    private var localVocabulary: some View {
        Section(header: self.contentModel.ownVocabulary.isEmpty ? nil : ownVocabularyHeader) {
            ownVocabulary
                .listRowBackground(Color.clear)
        }
    }
    
    
    //MARK: Basic Vocabulary Stack
    
    private var basicVocabulary: some View {
        Section(header: Text("Basics").font(.headline).bold().foregroundColor(.white))
        {
            ForEach(self.contentModel.basicVocabulary, id: \.id) { voc in
                HStack {
                    Text(voc.title).foregroundColor(.black).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded))
                    Spacer()
                    Button {
                        DispatchQueue.main.async {
                            if let index = self.contentModel.basicVocabulary.firstIndex(where: { $0.id == voc.id }) {
                                self.contentModel.basicVocabulary[index].checked.toggle()
                            }
                        }
                    } label: {
                        Image(systemName: "checkmark").frame(width: 20, alignment: .center).foregroundColor(voc.checked ? .green : .gray).font(.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded))
                    }
                }
                .listRowBackground(Color(.clear))
            }
        }
    }
}

struct VocabulariesView_Previews: PreviewProvider {
    static var previews: some View {
        VocabulariesView().environmentObject(ContentModel())
    }
}

