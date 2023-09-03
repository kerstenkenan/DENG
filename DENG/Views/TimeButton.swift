//
//  TimeButton.swift
//  DENG
//
//  Created by Kersten Weise on 08.12.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import SwiftUI

class TimeButtonModel : ObservableObject {
    @Published var selected = false
}

struct TimeButton: View, Identifiable {
    var id = UUID()
    var title: String
    
    @ObservedObject var content : ContentModel
    @ObservedObject var timeButtonModel = TimeButtonModel()
        
    var body: some View {
        Button(action: {
            if self.timeButtonModel.selected {
                self.timeButtonModel.selected.toggle()
                self.content.points = 0
                self.content.insideRound = false
                self.content.t?.invalidate()
            } else {
                self.timeButtonModel.selected.toggle()
                self.content.timer(min: self.title)
            }
            
            for button in self.content.timeButtons {
                if button.id != self.id {
                    button.timeButtonModel.selected = false
                }
            }
        }) {
            Text(title)
                .lineLimit(1)
                .foregroundColor(Color.yellow)
                .font(Font.system(size: 20, weight: Font.Weight.bold, design: Font.Design.rounded))
                .minimumScaleFactor(0.5)
                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                .background(self.timeButtonModel.selected ? Color.green : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
    }
}
    
    struct TimeButton_Previews: PreviewProvider {
    static var previews: some View {
        TimeButton(title: "5min", content: ContentModel())
    }
}
