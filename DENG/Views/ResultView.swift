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
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.blue]
        UINavigationBar.appearance().backgroundColor = UIColor(#colorLiteral(red: 0.2148060138, green: 0.5517488729, blue: 1, alpha: 1))
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = UIColor(#colorLiteral(red: 0.2148060138, green: 0.5517488729, blue: 1, alpha: 1))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Image("trophae").frame(width: 250, height: 250).scaleEffect(3.5).foregroundColor(.yellow).rotationEffect(Angle.init(degrees: 20))
                if self.content.endTitleIsShowing {
                    VStack {
                        Text("Herzlichen Glückwunsch, Du hast folgende Punktzahl erreicht: ")
                            .font(Font.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(#colorLiteral(red: 0, green: 0.009653781208, blue: 1, alpha: 1)))
                            .multilineTextAlignment(.center)
                            .padding()
                        Text("\(self.content.points)")
                            .font(Font.system(size: 35, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                VStack(alignment: .leading) {
                    if self.content.endTitleIsShowing {
                        Text("Ältere Ergebnisse")
                            .font(Font.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(#colorLiteral(red: 0, green: 0.009653781208, blue: 1, alpha: 1)))
                            .padding()
                    }
                    List() {
                        ForEach(self.content.results.reversed(), id: \.self) { result in
                            ResultRow(result: result).listRowBackground(Color(#colorLiteral(red: 0.2148060138, green: 0.5517488729, blue: 1, alpha: 1)))
                        }
                    }
                }
            }.navigationBarTitle(self.content.results.isEmpty ? "Keine Ergebnisse" : "Ergebnisse")
                .navigationBarItems(trailing: Button(action: {
                    self.content.deleteResults()
                }, label: {
                    Text("Liste leeren").foregroundColor(Color(#colorLiteral(red: 0, green: 0.009653781208, blue: 1, alpha: 1))).font(Font.system(size: 16, weight: .bold, design: .rounded))
                }))
                .background(Color(#colorLiteral(red: 0.2148060138, green: 0.5517488729, blue: 1, alpha: 1)))
            
        }.navigationViewStyle(StackNavigationViewStyle()).edgesIgnoringSafeArea(.all)
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView()
    }
}
