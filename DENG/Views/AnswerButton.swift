//
//  AnswerButton.swift
//  DENG
//
//  Created by Kersten Weise on 30.12.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import SwiftUI

struct AnswerButton: View, Identifiable {
    @ObservedObject var content : ContentModel
    @State private var answerButtonPressed = false

    
    var id = UUID()
    var title = "Title"
    var backgroundColor = Color(#colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1))


    var body: some View {
        Button(action: {
            self.answerButtonPressed.toggle()
            self.content.checkText(text: self.title, id: self.id, points: 10)
        }) {
            Text(self.title).padding()
                .foregroundColor(Color.black)
                .font(.system(size: 25))
                .minimumScaleFactor(0.5)
                .frame(minWidth: 280, minHeight: 50)
                .lineLimit(1)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(radius: 5)
                .padding(.bottom)
                .padding(.leading)
                .padding(.trailing)
        }.disabled(self.answerButtonPressed)
    }
}

struct AnswerButton_Previews: PreviewProvider {
    static let content = ContentModel()
    static var previews: some View {
        AnswerButton(content: content)
    }
}
