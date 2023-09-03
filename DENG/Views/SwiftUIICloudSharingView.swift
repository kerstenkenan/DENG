//
//  SwiftUIICloudSharingView.swift
//  DENG
//
//  Created by Kersten Weise on 11.11.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import SwiftUI
import CloudKit

struct SwiftUIICloudSharingView: View {
    
    @EnvironmentObject var contentModel: ContentModel
    
    let share: CKShare
    var body: some View {
        ZStack {
            Color(.white).edgesIgnoringSafeArea(.all)
            VStack {
                UIKitCloudKitSharingViewController(share: share)
            }
        }.onAppear() {
            UINavigationBar.appearance().backgroundColor = UIColor.white
            UITableView.appearance().backgroundColor = UIColor.white
        }
    }
}

//struct SwiftUIICloudSharingView_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIICloudSharingView(share: nil)
//    }
//}
