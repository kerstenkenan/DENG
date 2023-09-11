//
//  ClearListBackgroundModifier.swift
//  DENG
//
//  Created by Kersten Weise on 05.09.23.
//  Copyright © 2023 Kersten Weise. All rights reserved.
//

import SwiftUI

struct ClearListBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

extension View {
    func clearListBackground() -> some View {
        modifier(ClearListBackgroundModifier())
    }
}
