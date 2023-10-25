//
//  SpeechView.swift
//  DENG
//
//  Created by Kersten Weise on 09.01.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import SwiftUI

struct SpeechView: View {
    @EnvironmentObject var content: ContentModel
    
    var body: some View {
        HStack {
            VStack {
                self.arrangeViews()
                Text("Sprich das Wort nach. Hier zählt die richtige Aussprache").font(Font.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(Color.white).multilineTextAlignment(.center).lineLimit(nil).minimumScaleFactor(0.8).padding()
            }.onAppear {
                if self.content.recognitionTask == nil {
                    self.content.hearWord(word: self.content.originalWord)
                }
            }
        }
    }
    
    func arrangeViews() -> AnyView {
        return AnyView (
            GeometryReader { geo in
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Text(self.content.originalWord).font(Font.system(size: 35, weight: .heavy, design: .rounded))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(self.content.wordColor)
                            .scaleEffect(self.content.shouldSpringWord ? 1.5 : 1)
                            .animation(Animation.interpolatingSpring(mass: 1, stiffness: 1, damping: 0.5, initialVelocity: 0.5).speed(6), value: self.content.shouldSpringWord)
                            .minimumScaleFactor(0.8)
                        Image(systemName: "mic").font(.system(size: geo.size.height / 2))
                            .foregroundColor(self.content.speechNotReady ? Color.red : Color.green)
                        Spacer()
                    }
                    Spacer()
                }
            })
    }
}

struct SpeechView_Previews: PreviewProvider {
    static var previews: some View {
        SpeechView()
    }
}
