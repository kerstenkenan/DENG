//
//  SpeechViewModel.swift
//  DENG
//
//  Created by Kersten Weise on 09.01.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import Foundation
import SwiftUI
import Speech

extension ContentModel {
    func hearWord(word: String) {
        let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: self.chosenLanguage == .english ? "en-GB" : "fr-FR"))
        
        if let recognitionTask = self.recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        if let speechRecognizer = speechRecognizer  {
            if speechRecognizer.isAvailable {
                try? audioSession.setCategory(.playAndRecord)
                try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                inputNode = self.audioEngine.inputNode
                
                recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = recognitionRequest else { return }
                recognitionRequest.shouldReportPartialResults = true
                var counter = 0
                
                let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
                    counter += 1
                    if counter >= 10 {
                        timer.invalidate()
                        self.stopSpeechEngine()
                        self.newWord()
                    }
                }
                timer.fire()
                
                recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                    if let result = result {
                        var isFinal : Bool!
                        let resultString = result.bestTranscription.formattedString
                        guard let resultedWordsFromRecognizedText = self?.divideSingleWords(text: resultString) else {
                            print("\(#function) Extracting words from result failed. Pos 1")
                            self?.recognitionTask?.cancel()
                            return
                        }
                        guard let originalWordThere = self?.originalWord else {
                            print("\(#function) Getting original word failed. Pos 2")
                            self?.recognitionTask?.cancel()
                            return
                        }
                        guard let resultedWordsFromOriginal = self?.divideSingleWords(text: originalWordThere) else {
                            print("\(#function) Extracting words from original word failed. Pos 3")
                            self?.recognitionTask?.cancel()
                            return
                        }
                        if resultedWordsFromRecognizedText.count == resultedWordsFromOriginal.count {
                            isFinal = true
                        } else {
                            isFinal = false
                        }
                        if error != nil || isFinal {
                            self?.stopSpeechEngine()
                            timer.invalidate()
                            
                            guard let vocabListIsShown = self?.vocabListIsShown else { return }
                            if !vocabListIsShown {
                                self?.checkText(text: resultString, id: nil, points: 30)
                            }
                        }
                    }
                }
                
                let recordingFormat = inputNode?.outputFormat(forBus: 0)
                inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                    self.recognitionRequest?.append(buffer)
                }
                audioEngine.prepare()
                try? audioEngine.start()
            } else {
                self.speechNotReady.toggle()
            }
        }
    }
    
    func stopSpeechEngine() {
        self.session?.stopRunning()
        self.recognitionTask?.cancel()
        self.recognitionTask = nil
        self.recognitionRequest = nil
        self.inputNode?.removeTap(onBus: 0)
        self.audioEngine.stop()
        try? self.audioSession.setCategory(.playback)
    }
}
