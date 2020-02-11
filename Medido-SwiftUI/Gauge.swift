//
//  Gauge.swift
//  BLETest
//
//  Created by David Mcqueeney on 1/13/20.
//  Copyright © 2020 David Mcqueeney. All rights reserved.
//
import SwiftUI
import Combine

struct Gauge: View {
    
    private let value: Double
    private let title: String
    private let labels: [Int]
    private let minValue: Double
    private let maxValue: Double

    init(value: Double, title: String, labels: [Int], minValue: Double, maxValue: Double) {
        self.value = value
        self.title = title
        self.minValue = minValue
        self.maxValue = maxValue
        self.labels = labels
    }

    var body: some View {
        GeometryReader { gR in
            ZStack {
                GaugeArc().frame(width:gR.size.width, height:gR.size.height)//.foregroundColor(.yellow)
                Needle()
                    .frame(width: gR.size.width , height: gR.size.height)
                    .rotationEffect(needleAngle(value: self.value, minValue: self.minValue, maxValue: self.maxValue), anchor: .center)
                DrawLabels(labels: self.labels, value: self.value, minValue: self.minValue, maxValue: self.maxValue)
                DrawTicks(count: self.labels.count, width: gR.size.width, center: gR.size.width / 2).foregroundColor(Color.black)
                DrawFineTicks(count: self.labels.count, width: gR.size.width, center: gR.size.width / 2).foregroundColor(Color.black)
                Text(self.title).position(CGPoint(x: gR.size.width/2, y: 0.8*gR.size.height)).font(.system(size: 14))
            }
        }
    }
}
    
struct DrawTicks: Shape {
    
    let count: Int
    let width: CGFloat
    let center: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var theta: Double
        var point1: CGPoint
        var point2: CGPoint
        let length1 = Double(width / 4.0) * 1.30
        let length2 = Double(width / 4.0) * 1.18
        
        //print("count: \(count)")
        //print("width: \(width)")
        
        for i in 1 ... count {
            theta  = (3 * .pi / 4) - ((6.0 * .pi) / 4.0) * Double(i-1) / Double(count-1) + .pi
            //print("i \(i), theta \(theta * 180 / .pi)")
            point1 = CGPoint(x: length1 * sin(theta) + Double(center), y: length1 * cos(theta) + Double(center) )
            point2 = CGPoint(x: length2 * sin(theta) + Double(center), y: length2 * cos(theta) + Double(center) )
            p.move(to: point1)
            p.addLine(to: point2)
        }
        
        return p.strokedPath(.init(lineWidth: 3, lineCap: .square ))
    }
}

struct DrawFineTicks: Shape {
    
    let count: Int
    let width: CGFloat
    let center: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var theta: Double
        var point1: CGPoint
        var point2: CGPoint
        let length1 = Double(width / 4.0) * 1.30
        let length2 = Double(width / 4.0) * 1.24
        
        //print("count: \(count)")
        //print("width: \(width)")
        
        for i in 1 ... (5*(count-1)) {
            theta  = (3 * .pi / 4) - ((6.0 * .pi) / 4.0) * (Double(i) / 5.0) / (Double(5*(count-1)) / 5.0) + .pi
            //print("i \(i), theta \(theta * 180 / .pi)")
            point1 = CGPoint(x: length1 * sin(theta) + Double(center), y: length1 * cos(theta) + Double(center) )
            point2 = CGPoint(x: length2 * sin(theta) + Double(center), y: length2 * cos(theta) + Double(center) )
            p.move(to: point1)
            p.addLine(to: point2)
        }
        
        return p.strokedPath(.init(lineWidth: 2, lineCap: .square ))
    }
}


struct DrawLabels: View {
    
    let labels: [Int]
    let value: Double
    let minValue: Double
    let maxValue: Double
    
    var body: some View {
        GeometryReader { gR in
            ZStack {
                ForEach((0 ..< self.labels.count), id: \.self) {
                    //th = -3 * .pi / 4 + $0 * 2 * (3 * .pi / 4)/5
                    //xp = 150 / 2 - 150 / 2 * sin(th)
                    //yp = 150 / 2 - 150 / 2 * cos(th)
                    Text("\(self.labels[$0])").position(labelPoint(value: self.labels[$0], length: 0.80*Double(gR.size.height/2), center: Double(gR.size.height/2), minValue: self.minValue, maxValue: self.maxValue )).font(.system(size: 12))
                }
            }
        }
    }
}

struct GaugeArc : Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y:rect.midY), radius: rect.midX*0.6, startAngle: .degrees(-135-90-10), endAngle: .degrees(135-90+10), clockwise: false)
        return p.strokedPath(.init(lineWidth: rect.maxX/18, lineCap: .round))
    }
}

struct Needle: Shape {

    func path(in rect: CGRect) -> Path {

        var path = Path()
        let eps: CGFloat = 0.03
        let lenscale: CGFloat = 0.50
        let len: CGFloat = lenscale * (rect.maxX - rect.minX) / CGFloat(2.0)

        path.addEllipse(in: CGRect(x: rect.midX - eps*rect.maxX, y: rect.midY - eps*rect.maxY, width: eps*rect.maxX*2, height: eps*rect.maxY*2))
        path.move(to: CGPoint(x: Double(-eps*rect.maxX + rect.midX), y: Double(0 + rect.midY)))
        path.addLine(to: CGPoint(x: Double(-eps/5*rect.maxX + rect.midX), y: Double(-len + rect.midY)))
        path.addLine(to: CGPoint(x: Double( eps/5*rect.maxX + rect.midX), y: Double(-len + rect.midY)))
        path.addLine(to: CGPoint(x: Double(eps*rect.maxX+rect.midX), y: Double(0+rect.midY)))
        path.addLine(to: CGPoint(x: Double(-eps*rect.maxX + rect.midX), y: Double(0 + rect.midY)))

        return path
    }
}

private func CGRotate (x: Double, y: Double, x0: Double, y0: Double, rotation: Double) -> CGPoint {
    let ss = sin(rotation)
    let cs = cos(rotation)
    return CGPoint(x: x * cs - y * ss + x0, y: x * ss + y * cs + y0)
}

private func labelPoint(value: Int, length: Double, center: Double, minValue: Double, maxValue: Double) -> CGPoint {
    let a: Double = Double(labelAngle(value: Double(value), minValue: minValue, maxValue: maxValue))
    let p: CGPoint = CGPoint(x: length*sin(a) + center, y: length*cos(a) + center)
    return p
}

private func labelAngle(value: Double, minValue: Double, maxValue: Double) -> Double {
    let theta: Double = (3.0 * .pi / 4.0) - 6.0 * .pi / 4.0 * (value - minValue) / (maxValue-minValue) + .pi
    return theta
}

private func needleAngle(value: Double, minValue: Double, maxValue: Double) -> Angle {
    let theta = -(3 * .pi / 4) + 6 * .pi / 4 * (value - minValue) / (maxValue-minValue)
    return Angle(radians: theta)
}

//
// test version of ContentView
//
//struct ContentView: View {
//    @State private var sliderValue: Double = 0
//    private var title: String = "EGT"
//    private let maxValue: Double = 100
//    private let lblstr: [Int] = [0,20,40,60,80,100]
//
//    var body: some View {
//        VStack {
//            ZStack {
//                Gauge(value: $sliderValue.wrappedValue, title: title, labels: lblstr, minValue: 0, maxValue: 100).frame(width:200, height:200).foregroundColor(.blue)
//            }
//            Slider(value: $sliderValue,
//            in: 0...maxValue)
//            .padding(30)
//        }
//    }
//}
