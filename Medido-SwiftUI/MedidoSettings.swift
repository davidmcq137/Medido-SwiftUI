//
//  MedidoSettings.swift
//  Medido-SwiftUI
//
//  Created by David Mcqueeney on 2/8/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import SwiftUI

struct MedidoSettings: View {
    
    @State private var ppoFill: Double = Double(UserDefaults.standard.integer(forKey: "ppoFill")) / 10.0
    @State private var ppoEmpty: Double = Double(UserDefaults.standard.integer(forKey: "ppoEmpty")) / 10.0
    @State private var battCutoff: Double = Double(UserDefaults.standard.integer(forKey: "battCutoff")) / 10.0
    @EnvironmentObject var tel: Telem

    // allow +/- 10 from default value of 104 pulse per oz
    let ppoMax = 114.0
    let ppoMin = 94.0
    
    // default battery cutoff 3V per cell * 3 cells = 9V
    
    let defaults = UserDefaults.standard
    
    var body: some View {
        
        VStack (alignment: .leading){
            VStack {
                Toggle(isOn: $tel.isMetric) {
                Text("Metric Units Displayed")
              }
            }
            HStack {
                Stepper(onIncrement: {
                    if self.ppoFill + 0.1 <= self.ppoMax {
                        self.ppoFill = self.ppoFill + 0.1
                        self.defaults.set(Int(self.ppoFill*10), forKey: "ppoFill")
                    }
                }, onDecrement: {
                    if self.ppoFill - 0.1 >= self.ppoMin {
                        self.ppoFill = self.ppoFill - 0.1
                        self.defaults.set(Int(self.ppoFill*10), forKey: "ppoFill")
                    }
                }, label: { Text("Fill cal factor (PPO)")
                })
                Text(" \(ppoFill, specifier: "%0.1f")")
            }
            
            HStack {
                Stepper(onIncrement: {
                    if self.ppoEmpty + 0.1 <= self.ppoMax {
                        self.ppoEmpty = self.ppoEmpty + 0.1
                        self.defaults.set(Int(self.ppoEmpty*10), forKey: "ppoEmpty")
                    }
                }, onDecrement: {
                    if self.ppoEmpty - 0.1 >= self.ppoMin {
                        self.ppoEmpty = self.ppoEmpty - 0.1
                        self.defaults.set(Int(self.ppoEmpty*10), forKey: "ppoEmpty")
                    }
                }, label: { Text("Empty cal factor (PPO)")
                })
                Text(" \(ppoEmpty, specifier: "%0.1f")")
            }
            
            HStack {
                Stepper(onIncrement: {
                    self.battCutoff = self.battCutoff + 0.1
                    self.defaults.set(Int(self.battCutoff*10), forKey: "battCutoff")
                }, onDecrement: {
                    if self.battCutoff - 0.1 >= 0 {
                        self.battCutoff = self.battCutoff - 0.1
                        self.defaults.set(Int(self.battCutoff*10), forKey: "battCutoff")
                    }
                }, label: { Text("Power Off Voltage")
                })
                Text(" \(battCutoff, specifier: "%0.2f")")
            }
        }
    }
}

/*
 
 @State var quantity: Int = 0
 Stepper(onIncrement: {
     self.quantity += 1
 }, onDecrement: {
     self.quantity -= 1
 }, label: { Text("Quantity \(quantity)") })
 */
