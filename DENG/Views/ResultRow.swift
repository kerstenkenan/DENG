//
//  ResultRow.swift
//  DENG
//
//  Created by Kersten Weise on 03.01.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import SwiftUI

struct ResultRow: View {
    var result : Score
    
    var body: some View {
        GeometryReader { geometry in
            HStack() {
                Group {
                    Text("\(self.result.date)")
                    Text("\(String(self.result.points)) Punkte")
                    Text("\(String(self.result.minutes)) gespielt").multilineTextAlignment(.trailing)
                }
                .frame(width: geometry.size.width / 3)
                .font(Font.system(size: geometry.size.width < 500 ? 16 : 30, weight: .bold, design: .rounded))
                .foregroundColor(Color(#colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)))
                .lineLimit(1)
            }.frame(width: geometry.size.width, height: 50)
        }
    }
}

struct ResultRow_Previews: PreviewProvider {
    static var previews: some View {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "DE")
        return ResultRow(result: Score(date: formatter.string(from: Date()), points: 100, minutes: "20min"))
    }
    
    struct iPadPreview: PreviewProvider {
        static var previews: some View {
            ResultRow(result: Score(date: "15.01.2020", points: 100, minutes: "20min")).previewDevice(.init(stringLiteral: "iPad (5th generation)"))
        }
    }
}
