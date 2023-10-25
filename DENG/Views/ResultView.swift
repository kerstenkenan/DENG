//
//  ResultView.swift
//  DENG
//
//  Created by Kersten Weise on 15.12.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import SwiftUI

struct ResultView: View {
    @EnvironmentObject var content : ContentModel
    
    init() {
        if #unavailable(iOS 16.0) {
            UITableView.appearance().backgroundColor = .clear
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.blue.ignoresSafeArea()
                VStack() {
                    if self.content.endTitleIsShowing {
                        VStack {
                            Text("Herzlichen Glückwunsch, Du hast folgende Punktzahl erreicht: ")
                                .font(Font.system(size: 22, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .foregroundColor(Color(#colorLiteral(red: 0, green: 0.009653781208, blue: 1, alpha: 1)))
                                .multilineTextAlignment(.center)
                            Text("\(self.content.points)")
                                .font(Font.system(size: 35, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        VStack(alignment: .leading) {
                            Text("Ältere Ergebnisse")
                                .font(Font.system(size: 20, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .foregroundColor(Color(#colorLiteral(red: 0, green: 0.009653781208, blue: 1, alpha: 1)))
                                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                        }
                    }
                    if !self.content.results.isEmpty {
                        List() {
                            ForEach(self.content.results.reversed(), id: \.self) { result in
                                ResultRow(result: result).listRowBackground(Color.blue)
                            }
                        }.clearListBackground()
                    } else {
                        Spacer()
                    }
                }.navigationBarTitle(self.content.results.isEmpty ? "Keine Ergebnisse" : "Ergebnisse")
                .navigationBarItems(trailing: Button(action: {
                    self.content.deleteResults()
                }, label: {
                    Text("Liste leeren").foregroundColor(Color(#colorLiteral(red: 0, green: 0.009653781208, blue: 1, alpha: 1))).font(Font.system(size: 16, weight: .bold, design: .rounded))
                }))
            }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView()
    }
}
