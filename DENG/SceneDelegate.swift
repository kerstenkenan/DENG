//
//  SceneDelegate.swift
//  DENG
//
//  Created by Kersten Weise on 05.12.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import UIKit
import SwiftUI
import CloudKit
import Network

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let contentModel = (UIApplication.shared.delegate as! AppDelegate).content
    private let queue = DispatchQueue(label: "Internetmonitor")
    private let monitor = NWPathMonitor()
    static var gotInternetOnce = false
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).       
    
        // Create the SwiftUI view that provides the window contents.

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            self.makeWindow(scene: windowScene)
        }
        
//        if let metaData = connectionOptions.cloudKitShareMetadata?.participantStatus {
//            if metaData == .pending {
//                let acceptOp = CKAccep
//            }
//        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
        
//        content.saveVocabularies(toiCloud: true)
        monitor.cancel()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        monitor.pathUpdateHandler = { path in
            switch path.status {
            case .satisfied:
                if !SceneDelegate.gotInternetOnce {
                    DispatchQueue.main.async {
                        self.contentModel.getVocab()
                        SceneDelegate.gotInternetOnce = true
                    }
                }
            case .unsatisfied:
                SceneDelegate.gotInternetOnce = false
                DispatchQueue.main.async {
                    for i in 0..<self.contentModel.ownVocabulary.count {
                        self.contentModel.ownVocabulary[i].fromiCloud = false
                    }
                    for i in 0..<self.contentModel.sharedVocabulary.count {
                        self.contentModel.sharedVocabulary[i].fromiCloud = false
                    }
                    self.contentModel.basicVocabulary = self.contentModel.getVocsFromDisk(in: .basicVocab)
                    self.contentModel.newWord()
                }
            default: break
            }
        }
        monitor.start(queue: queue)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
//        self.contentModel.saveVocabularyToiCloud(voc: self.contentModel.ownVocabulary)
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
    }
    
    func makeWindow(scene: UIWindowScene) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView().environmentObject(contentModel)
        
        // Use a UIHostingController as window root view controller.
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        print(#function)
        // Accept the share. If successful, schedule a fetch of the
            // share's root record.

            
            // Create a reference to the share's container so the operation
            // executes in the correct context.
            let container = CKContainer(identifier: cloudKitShareMetadata.containerIdentifier)
            
            // Create the operation using the metadata the caller provides.
            let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
                
            debugPrint("Accepting CloudKit Share with metadata: \(cloudKitShareMetadata)")
        
            operation.perShareResultBlock = { metadata, result in
                let rootRecordID = metadata.hierarchicalRootRecordID
                
                switch result {
                case .success(_):
                    print("Accepted CloudKit share for root record ID: \(String(describing: rootRecordID))")
                case .failure(let err):
                    debugPrint("Error accepting share with root record ID: \(String(describing: rootRecordID)), \(err)")
                }
                self.contentModel.getVocab()
            }
                
            // If the operation fails, return the error to the caller.
            // Otherwise, return the record ID of the share's root record.
            operation.acceptSharesResultBlock = { result in
                switch result {
                case .success():
                    print("Sucessfully accepted the share")
                case .failure(let err):
                    print("Error accepting CKShare: \(err)")
                }
            }
            // Set an appropriate QoS and add the operation to the
            // container's queue to execute it.
            operation.qualityOfService = .userInitiated
            container.add(operation)
        
    }

}
