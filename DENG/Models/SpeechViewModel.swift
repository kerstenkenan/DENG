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
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        if let speechRecognizer = self.speechRecognizer  {
            if speechRecognizer.isAvailable {
                try? audioSession.setCategory(.playAndRecord)
                try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                self.inputNode = audioEngine.inputNode
                
                self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
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
                        if result.bestTranscription.formattedString.count < word.count   {
                            isFinal = false
                        } else {
                            isFinal = true
                        }
                        if error != nil || isFinal {
                            self?.stopSpeechEngine()
                            timer.invalidate()
                            
                            guard let vocabListIsShown = self?.vocabListIsShown else { return }
                            if !vocabListIsShown {
                                let charSet : [Character] = ["!",".",",","/",":", "?"]
                                
                                let blankResult = (result.bestTranscription.formattedString.lowercased()).filter { !charSet.contains($0) }
                                print(blankResult)
                                if blankResult.contains(word.lowercased()) {
                                    self?.wordColor = Color.green
                                    self?.shouldSpringWord = true
                                    self?.win?.play()
                                    self?.countPoints(points: 30, handler: {
                                        self?.newWord()
                                    })
                                } else {
                                    self?.gameover?.play()
                                    self?.wordColor = Color.red
                                    self?.shouldSpringWord = true
                                    if (self?.shouldReadAloud)! {
                                        self?.readAloud(word: (self?.englishWord)!)
                                    }
                                    self?.countPoints(points: -30, handler: {
                                        self?.newWord()
                                        
                                    })
                                }
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
