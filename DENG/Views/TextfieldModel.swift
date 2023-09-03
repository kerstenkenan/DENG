//
//  TextfieldModel.swift
//  DENG
//
//  Created by Kersten Weise on 08.01.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import Foundation
import SwiftUI

struct TextfieldModel: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    var contentModel: ContentModel
    
    var body: some View {
        switch contentModel.states {
        case .threeanswers:
                    
        case .textfield:
            return SimpleTextfield()
        case .speech:
            return SpeechView()
        }
    }
}





//extension ContentModel {   
//    
//    func arrangeViews(verticalClass: UserInterfaceSizeClass) -> some View {
//
//    }
//}
