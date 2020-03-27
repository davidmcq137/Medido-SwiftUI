//
//  ContentView.swift
//  BLETest
//
//  Created by David Mcqueeney on 1/11/20.
//  Copyright © 2020 David Mcqueeney. All rights reserved.
//

import SwiftUI
import Combine


struct ContentView: View {
    
    @State private var selection = 1

    //init() {
    //    UITabBar.appearance().backgroundColor = UIColor.black
    //}
    
    var body: some View {
        TabView (selection: $selection) {
            MedidoMainCombo()
                .tabItem {
                    VStack {
                        Image(systemName: "1.circle")
                        Text("Main")
                    }
            }.tag(1)
            MedidoMain()
                .tabItem {
                    VStack {
                        Image(systemName: "2.circle")
                        Text("Gauge")
                    }
            }.tag(2)
            MedidoDeviceList()
                .tabItem {
                    VStack {
                        Image(systemName: "3.circle")
                        Text("BLE Devices")
                    }
            }.tag(3)
            MedidoSettings()
                .tabItem {
                    VStack {
                        Image(systemName: "4.circle")
                        Text("Settings")
                    }
            }.tag(4)
            MedidoAircraft()
                .tabItem {
                    VStack {
                        Image(systemName: "5.circle")
                        Text("Aircraft")
                    }
            }.tag(5)
        }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

