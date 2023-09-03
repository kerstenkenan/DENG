//
//  ICloudSharingView.swift
//  DENG
//
//  Created by Kersten Weise on 02.11.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import SwiftUI

class ICloudSharingViewModel: ObservableObject {
    
    
    @Published var errorText = " "
    func sendEmail(address: String, contentModel: ContentModel) -> Bool {
        var valid = false
        if address.isEmail {
            contentModel.emailaddress = address
            valid = true
            print(contentModel.emailaddress)
        } else {
            errorText = "Please enter a valid email address."
        }
        return valid
    }
}

struct ICloudSharingView: View {
    @ObservedObject var model = ICloudSharingViewModel()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var contentModel : ContentModel
    @State var emailaddress = ""
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.blue, .white]), startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack {
                Image(systemName: "cloud").font(.system(size: 210)).foregroundColor(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))).shadow(color: .gray, radius: 5, x: 2, y: 2)
                Text("Share").font(.system(size: 40, weight: .heavy, design: .rounded)).foregroundColor(Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1))).offset(x: 0, y: -90)
                VStack (alignment: .leading) {
                    Text("Please enter the email address (Apple-ID) of the person with whom you would like to share the vocabulary").foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))).font(.system(size: 24, weight: .bold, design: .rounded)).minimumScaleFactor(0.4)
                    HStack {
                        TextField("Enter here", text: $emailaddress).autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/).textFieldStyle(RoundedBorderTextFieldStyle()).font(.system(size: 26)).minimumScaleFactor(0.6)
                        Button("Share") {
                            let valid = model.sendEmail(address: self.emailaddress, contentModel: contentModel)
                            if valid {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }.foregroundColor(.white).font(.system(size: 16, weight: .bold)).frame(width: 60, height: 35, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/).padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)).background(Color.green).cornerRadius(14)
                    }.padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                    
                    Text(model.errorText).font(.system(size: 22)).foregroundColor(.red)
                }
            }.padding()
        }.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}

struct ICloudSharingView_Previews: PreviewProvider {
    static var previews: some View {
        ICloudSharingView()
    }
}

extension String {
    var isEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
}
