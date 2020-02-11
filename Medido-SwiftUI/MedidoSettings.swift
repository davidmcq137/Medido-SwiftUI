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

    // allow +/- 10 from default value of 104 pulse per oz
    let ppoMax = 114.0
    let ppoMin = 94.0
    
    let defaults = UserDefaults.standard
    
    var body: some View {
        
        VStack{
            HStack {
                Stepper(onIncrement: {
                    if self.ppoFill + 0.1 <= self.ppoMax {
                        self.ppoFill = self.ppoFill + 0.1
                        self.defaults.set(Int(self.ppoFill*10), forKey: "ppoFill")
                        writeValue(data: String(format: "(CalFactFill: %d)", Int(self.ppoFill*10)))
                    }
                }, onDecrement: {
                    if self.ppoFill - 0.1 >= self.ppoMin {
                        self.ppoFill = self.ppoFill - 0.1
                        self.defaults.set(Int(self.ppoFill*10), forKey: "ppoFill")
                        writeValue(data: String(format: "(CalFactFill: %d)", Int(self.ppoFill*10)))
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
                        writeValue(data: String(format: "(CalFactEmpty: %d)", Int(self.ppoEmpty*10)))
                    }
                }, onDecrement: {
                    if self.ppoEmpty - 0.1 >= self.ppoMin {
                        self.ppoEmpty = self.ppoEmpty - 0.1
                        self.defaults.set(Int(self.ppoEmpty*10), forKey: "ppoEmpty")
                        writeValue(data: String(format: "(CalFactEmpty: %d)", Int(self.ppoEmpty*10)))
                    }
                }, label: { Text("Empty cal factor (PPO)")
                })
                Text(" \(ppoEmpty, specifier: "%0.1f")")
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
