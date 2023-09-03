//
//  ThreeAnswersView.swift
//  DENG
//
//  Created by Kersten Weise on 12.03.23.
//  Copyright © 2023 Kersten Weise. All rights reserved.
//

import SwiftUI

struct ThreeAnswersView: View {
    var verticalSizeClass: UserInterfaceSizeClass?
    @EnvironmentObject var contentModel: ContentModel
    
    var body: some View {
        Group {
            if verticalSizeClass == .regular {
                Spacer()
                HStack {
                    Group {
                        if contentModel.showGermanWord {
                            ForEach(contentModel.imageArr.reversed(), id: \.self) { sig in
                                Text(sig).font(.system(size: 30)).foregroundColor(Color.white)
                            }
                        } else {
                            ForEach(contentModel.imageArr, id: \.self) { sig in
                                Text(sig).font(.system(size: 30)).foregroundColor(Color.white)
                            }
                        }
                    }
                }
                Text(contentModel.showGermanWord ? contentModel.germanWord : contentModel.englishWord).font(Font.system(size: 35, weight: .heavy, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .foregroundColor(contentModel.wordColor)
                ForEach(contentModel.answerButtons, id: \.id) {
                    $0
                }
                Spacer()
            } else {
                HStack {
                    VStack {
                        HStack {
                            if contentModel.showGermanWord {
                                ForEach(contentModel.imageArr.reversed(), id: \.self) { sig in
                                    Text(sig).font(.system(size: 30)).foregroundColor(Color.white).minimumScaleFactor(0.5)
                                }
                            } else {
                                ForEach(contentModel.imageArr, id: \.self) { sig in
                                    Text(sig).font(.system(size: 30)).foregroundColor(Color.white).minimumScaleFactor(0.5)
                                }
                            }
                        }
                        Text(contentModel.showGermanWord ? contentModel.germanWord : contentModel.englishWord)
                            .font(Font.system(size: 35, weight: .heavy, design: .rounded))
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.center)
                            .foregroundColor(contentModel.wordColor)
                            .padding()
                    }
                    Spacer()
                    VStack {
                        ForEach(contentModel.answerButtons, id: \.id) {
                            $0
                        }
                    }
                }
            }
        }
    }
}

struct ThreeAnswersView_Previews: PreviewProvider {
    static var previews: some View {
        ThreeAnswersView()
    }
}

