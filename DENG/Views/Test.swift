//
//  Test.swift
//  DENG
//
//  Created by Kersten Weise on 05.09.23.
//  Copyright © 2023 Kersten Weise. All rights reserved.
//

import SwiftUI

struct Test: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.blue.ignoresSafeArea(.all)
                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            }
        }
    }
}

struct Test_Previews: PreviewProvider {
    static var previews: some View {
        Test()
    }
}
