//
//  SceneDelegate.swift
//  Medido-SwiftUI
//
//  Created by David Mcqueeney on 2/7/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

var tele: Telem!
var autoOff = false

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        print("scene will connect to session")
        // Get the managed object context from the shared persistent container.
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        // Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
        // Add `@Environment(\.managedObjectContext)` in the views that will need the context.
        let contentView = ContentView().environment(\.managedObjectContext, context)
        
        print("creating instance of Telem()")
        tele = Telem() //create instance of @Environment object
        print("after create instance Telem()")
        
        clearChartRecData()
        //setInfoMessage(msg: "Starting up")

        //note selectedPlaneID is handled in MedidoAircraft.swift
        tele.selectedPlaneName = UserDefaults.standard.string(forKey: "selName") ?? "Unknown Aircraft"
        tele.selectedPlaneTankCap = UserDefaults.standard.double(forKey: "selTankCap")
        tele.selectedPlaneTankUnits = UserDefaults.standard.string(forKey: "selTankUnits") ?? "unk"
        tele.selectedPlaneMaxSpeed = UserDefaults.standard.double(forKey: "selSpeed")
        tele.selectedPlaneMaxPressure = UserDefaults.standard.double(forKey: "selPressure")
        tele.selectedPlaneMaxPressureUnits = UserDefaults.standard.string(forKey: "selPressureUnits") ?? "unk"
        
        print("starting up .. selName: \(tele.selectedPlaneName)")
        
        tele.isMetric = UserDefaults.standard.bool(forKey: "isMetric") // if not exist, returns false .. perfect :-)
        tele.overFlowShutoff = UserDefaults.standard.bool(forKey: "overFlowShutoff") // if not exist, returns false .. perfect :-)
        tele.isSPIpump = UserDefaults.standard.bool(forKey: "isSPIpump") // if not exist, returns false .. perfect :-)

        if tele.selectedPlaneMaxPressureUnits == "psi" {
            tele.sliderPressure = Int(10 * tele.selectedPlaneMaxPressure)
        } else if tele.selectedPlaneMaxPressureUnits == "mbar" {
            tele.sliderPressure = Int(10 * tele.selectedPlaneMaxPressure / 68.9476)
        } else {
            tele.sliderPressure = 0
        }
        
        tele.sliderSpeed = Int(tele.selectedPlaneMaxSpeed)
        
        if tele.selectedPlaneName == "Unknown Aircraft" {
            tele.selectedPlaneMaxPressure = 5.0
            tele.selectedPlaneMaxPressureUnits = "psi"
            tele.selectedPlaneTankCap = 0.0
            tele.selectedPlaneTankUnits = "oz"
            tele.selectedPlaneMaxSpeed = 100.0
            tele.sliderPressure = Int(10.0 * tele.selectedPlaneMaxPressure)
            tele.sliderSpeed = 100
        }
        
        print("tele.sliderPressure: \(tele.sliderPressure) tele.sliderSpeed: \(tele.sliderSpeed)")
        
        let savedmax = tele.maxPWM //if never set, user def will ret zero, we want the init value instead
        tele.maxPWM = UserDefaults.standard.integer(forKey: "maxPWM")
        if tele.maxPWM == 0 {
            tele.maxPWM = savedmax
        }
        
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            //window.rootViewController = UIHostingController(rootView: contentView)
            
            //
            window.rootViewController = UIHostingController(rootView: contentView.environmentObject(tele))
            
            //
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
        print("scene did disconnect")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        print("scene did become active")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        print("scene will resign active")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("scene will enter foreground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        print("scene did enter background")
    }


}

