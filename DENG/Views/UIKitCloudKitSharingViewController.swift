//
//  ICloudSharingCtrlView.swift
//  DENG
//
//  Created by Kersten Weise on 07.11.20.
//  Copyright © 2020 Kersten Weise. All rights reserved.
//

import CloudKit
import UIKit
import SwiftUI
import Foundation

struct UIKitCloudKitSharingViewController: UIViewControllerRepresentable {
    let share: CKShare
    
    func makeUIViewController(context: Context) -> some UIViewController  {
        let sharingController = UICloudSharingController(share: share, container: CKContainer.default())
        sharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
        sharingController.delegate = context.coordinator
        sharingController.modalPresentationStyle = .none        
        return sharingController
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
    
    func makeCoordinator() -> UIKitCloudKitSharingViewController.Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        @EnvironmentObject var content: ContentModel
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            debugPrint("Error saving share: \(error)")
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "Share Vocabulary"
        }
    }
}
    
