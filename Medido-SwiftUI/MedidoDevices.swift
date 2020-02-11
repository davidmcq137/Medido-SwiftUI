//
//  MedidoDevices.swift
//  Medido-SwiftUI
//
//  Created by David Mcqueeney on 2/8/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import Foundation
import SwiftUI
import Combine


struct MedidoDeviceList: View {
    
    @State private var selectedDevice = 0
    
    @EnvironmentObject var tele: Telem
    
    let defaults = UserDefaults.standard
    
    var body: some View {
        VStack {
            Text("BLE Device UUIDs").font(.headline)
            List(tele.BLEUUIDs, id: \.self) { uuid in
                Button (action: {
                    self.defaults.set(uuid, forKey: "BLEUUID")
                    print("Set default forKey BLEUUID to \(uuid), restarting Scan")
                    BLELocation.blelocation.startScan()
                }) {
                    Text(uuid).font(.system(size: 16))
                }
            }
            Button (action: {
                self.defaults.removeObject(forKey: "BLEUUID")
            }) {
                Text("Clear stored BLE UUID")
            }.padding(50)
        }
    }
}

