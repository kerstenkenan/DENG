//
//  SimpleTextfield.swift
//  DENG
//
//  Created by Kersten Weise on 08.01.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import SwiftUI

struct SimpleTextfield: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @EnvironmentObject var content: ContentModel
    
    @State private var textfieldText = ""
    @State private var scEffect = 1.0
    @State private var animationOpacity = 0.0
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Group {
                    Text(self.content.shouldSpringWord ? self.content.originalWord : self.content.germanWord)
                        .font(Font.system(size: 35, weight: .heavy, design: .rounded))
                        .frame(width: geo.size.width)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundColor(self.content.wordColor)
                        .scaleEffect(self.content.shouldSpringWord ? 1.3 : 1.0)
                        .animation(.default, value: self.content.shouldSpringWord)
                    TextField("Übersetzung schreiben", text: self.$textfieldText, onCommit: {
                        self.content.checkText(text: self.textfieldText, id: nil, points: 30)
                    })
                        .padding()
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .frame(width: 320, height: 50, alignment: .center)
                        .multilineTextAlignment(.center)
                        .font(.largeTitle)
                        .background(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)))
                        .cornerRadius(25)
                        .shadow(color: .black, radius: 5, x: 1, y: 1)

                }
                .offset(y: geo.size.height < (self.content.keyboardHeight + (self.content.keyboardHeight / 4)) ? -self.content.keyboardHeight / 3 : 0)
                    .animation(.easeInOut(duration: self.content.keyboardTime), value: self.content.keyboardHeight)
            }
        }
    }
}

struct SimpleTextfield_Previews: PreviewProvider {
    static var previews: some View {
        SimpleTextfield()
    }
}
