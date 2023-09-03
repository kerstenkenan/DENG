//
//  TimeTextfield.swift
//  DENG
//
//  Created by Kersten Weise on 10.12.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import SwiftUI

struct TimeTextfield: View {
    @ObservedObject var content: ContentModel
    
    var body: some View {
        Text(content.time)
        .font(Font.system(size: 20, weight: .bold, design: .rounded))
        .foregroundColor(Color(#colorLiteral(red: 0.2148060138, green: 0.5517488729, blue: 1, alpha: 1)))
        .shadow(color: .black, radius: 2, x: 1, y: 1)
        .fixedSize()
        .padding()
    }
}

struct TimeTextfield_Previews: PreviewProvider {
    static var previews: some View {
        TimeTextfield(content: ContentModel())
    }
}
