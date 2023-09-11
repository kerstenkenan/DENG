//
//  ContentView.swift
//  DENG
//
//  Created by Kersten Weise on 05.12.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import SwiftUI
import Speech
import AVFoundation
import CloudKit
import Network


struct ContentView: View {
    @State private var showingAlert1 = false
    @State private var showingAlert2 = false
    @State private var showingSpeechAlert = false
    @State private var speakerSelected = true
    @State private var showingVocabularies = false
    
    @EnvironmentObject var content : ContentModel
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
        
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea(.all)
//            Image("1600px-English_language.svg").resizable().opacity(0.02)
            
            // MARK: Top-Buttons
            GeometryReader { geo in
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            self.showingVocabularies.toggle()
                            self.content.shouldReadAloud = false
                            UIApplication.shared.applicationIconBadgeNumber = 0
                            UserDefaults.standard.set(0, forKey: "bagdeNumber")
                        }) {
                            Image(systemName: "plus.square.on.square")
                                .foregroundColor(Color.black).scaleEffect(1.2)
                                .background(Circle().frame(width: 35, height: 35))
                                .shadow(color: Color(#colorLiteral(red: 0.2096882931, green: 0.2096882931, blue: 0.2096882931, alpha: 1)), radius: 2, x: 1, y: 1)
                                .padding()
                        }.sheet(isPresented: self.$showingVocabularies, onDismiss: {
                            self.content.counter = 0
                            self.content.shouldReadAloud = true
                            self.content.vocabListIsShown = false
                            self.content.newWord()
                        }) {
                            VocabulariesView().onAppear(perform: { self.content.vocabListIsShown = true })
                        }.disabled(self.content.insideRound)
                        Button(action: {
                            self.speakerSelected.toggle()
                            self.content.shouldReadAloud = self.speakerSelected
                        }) {
                            Group {
                                self.speakerSelected ? Image(systemName: "speaker.3") : Image(systemName: "speaker.slash")
                            }
                            .scaleEffect(1.2)
                            .foregroundColor(Color.black)
                            .background(Circle().frame(width: 35, height: 35))
                            .shadow(color: Color(#colorLiteral(red: 0.2096882931, green: 0.2096882931, blue: 0.2096882931, alpha: 1)), radius: 2, x: 1, y: 1)
                            .padding()
                        }
                        Button(action: {
                            self.content.resultsanswerButtonPressed.toggle()
                            self.content.getResults()
                        }) {
                            Image("trophae").scaleEffect(0.75).foregroundColor(Color.black).background(Circle()).frame(width: 35, height: 35).shadow(color: Color(#colorLiteral(red: 0.2096882931, green: 0.2096882931, blue: 0.2096882931, alpha: 1)), radius: 2, x: 1, y: 1)
                                .padding(0.5)
                        }.sheet(isPresented: self.$content.resultsanswerButtonPressed, onDismiss: {
                            if self.content.endTitleIsShowing {
                                self.content.points = 0
                                self.content.counter = 0
                                self.content.endTitleIsShowing = false
                                self.content.newWord()
                            }
                        }) {
                            ResultView()
                        }
                    }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
                    
                    // MARK: Point-Label
                    HStack {
                        Group {
                            Text("Punkte:").fixedSize()
                            Text(String(self.content.points))
                                .frame(height: 30, alignment: .leading)
                        }.font(Font.system(size: 25, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .foregroundColor(Color(#colorLiteral(red: 0.2148060138, green: 0.5517488729, blue: 1, alpha: 1)))
                        .shadow(color: .black, radius: 3, x: 1, y: 1)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        Spacer()
                    }
                    
                    // MARK: Answer-Buttons
                    VStack {
                        Group {
                                switch content.states {
                                case .threeanswers:
                                    ThreeAnswersView(verticalSizeClass: self.verticalSizeClass)
                                case .speech:
                                    SpeechView()
                                case .textfield:
                                    SimpleTextfield()
                                }
                            }
                        }
                    // MARK: TimeFields
                    HStack {
                        TimeTextfield(content: self.content).frame(width: 85, alignment: Alignment.leading)
                        ForEach(self.content.timeButtons, id: \.id) {
                            $0
                        }
                    }
                }
            }
        }.ignoresSafeArea(.keyboard)
        .onAppear {
            print("Speaker: \(self.speakerSelected)")
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, err in
                if let err = err {
                    print("Granting user notification failed: \(err)")
                } else {
                    print("User notification granted.")
                }
                
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    OperationQueue.main.addOperation {
                        switch authStatus {
                        case .denied, .notDetermined, .restricted:
                            self.showingAlert1 = true
                        default: break
                        }
                    }
                    AVCaptureDevice.requestAccess(for: .audio) { (granted) in
                        if !granted {
                            self.showingAlert2 = true
                        }
                    }
                    
                }
            }            
        }
        .alert("Fehler", isPresented: $showingAlert1, actions:{
            Button("OK", role: .cancel, action: {})
        }, message: {
            Text("Die Spracherkennung konnte nicht initializiert werden. Ohne Spracherkennung funktioniert diese App nicht. Gehe in Einstellungen/Datenschutz/Spracherkennung & Mikrofon und erlaube jeweils die Spracherkennung und den Mikrofon-Zugriff für diese App.")
        })
        .alert("Fehler", isPresented: $showingAlert2, actions: {
            Button("OK", role: .cancel, action: {})
        }, message: {
            Text("Ohne Zugriff auf das interne Mikrophon funktioniert diese App nicht. Gehe in Einstellungen/Datenschutz/Spracherkennung & Mikrofon und erlaube jeweils die Spracherkennung und den Mikrofon-Zugriff für diese App.")
        })
        .alert("Fehler", isPresented: $content.speechNotReady, actions: {
            Button("OK", role: .cancel, action: {
                self.content.newWord()
            })
        }, message: {
            Text("Die Spracherkennung konnte nicht initialisiert werden. Bitte prüfe deine Internetverbindung.")
        })
        .alert("iCloud-Error", isPresented: $content.showiCloudAlert, actions: {
            Button("OK", role: .cancel, action: {
                self.content.newWord()
                print("Done")
            })
        }, message: {
            Text("Please get to the settings of your device and enable iCloud for this App. \n\nBitte gehe zu den Einstellungen deines Geräts und aktiviere iCloud für diese App.")
        })
        .alert("iCloud-Error", isPresented: $content.serviceUnavailableAlert, actions: {
            Button("OK", role: .cancel, action: {
                self.content.newWord()
            })
        }, message: {
            Text("Service is momentary unavailable. \n\niCloud ist momentan nicht erreichbar.")
        })
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct Light_Preview: PreviewProvider {
    static let content = ContentModel()
    static var previews: some View {
        ContentView().environment(\.colorScheme, .light)
    }
}

struct Dark_Preview: PreviewProvider {
    static let content = ContentModel()
    static var previews: some View {
        ContentView().environment(\.colorScheme, .dark)
    }
}

struct iPad_Preview: PreviewProvider {
    static let content = ContentModel()
    static var previews: some View {
        ContentView().previewDevice(.init(stringLiteral: "iPad (5th generation)"))
    }
}

struct iPhone_Preview_Landscape: PreviewProvider {
    static let content = ContentModel()
    static var previews: some View {
        ContentView().previewLayout(PreviewLayout.fixed(width: 667, height: 375))
    }
}
