//
//  Gauge.swift
//  BLETest
//
//  Created by David Mcqueeney on 1/13/20.
//  Copyright © 2020 David Mcqueeney. All rights reserved.
//

import SwiftUI


struct Gauge: View {
    
    private let value: Double
    private let fmtstr: String
    private let title: String
    private let units: String
    private let labels: [Double]
    private let minValue: Double
    private let maxValue: Double
    private let showBug: Bool
    private let bugValue: Double

    init(value: Double, fmtstr: String, title: String, units: String, labels: [Double], minValue: Double, maxValue: Double, showBug: Bool, bugValue: Double) {
        self.value = value
        self.fmtstr = fmtstr
        self.title = title
        self.units = units
        self.minValue = minValue
        self.maxValue = maxValue
        self.labels = labels
        self.showBug = showBug
        self.bugValue = bugValue
    }

    var body: some View {
        VStack (alignment: .center) {
            ZStack {
                GaugeArc()//.border(Color.red)
                Needle()
                    .rotationEffect(needleAngle(value: self.value, minValue: self.minValue, maxValue: self.maxValue), anchor: .center)
                if showBug == true && self.bugValue != 0.0 {
                    Bug()
                        .rotationEffect(needleAngle(value: self.bugValue, minValue: self.minValue, maxValue: self.maxValue), anchor: .center).foregroundColor(Color.black)
                }
                DrawLabels(labels: self.labels, value: self.value, fmtstr: fmtstr, minValue: self.minValue, maxValue: self.maxValue, legend: title, units: units)//.border(Color.yellow)
                DrawTicks(count: self.labels.count, width: 0, center: 0).foregroundColor(Color.black)
                DrawFineTicks(count: self.labels.count, width: 0, center: 0).foregroundColor(Color.black)
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
        let length1 = min(Double(rect.maxX), Double(rect.maxY)) / 4.0 * 1.30
        let length2 = min(Double(rect.maxX), Double(rect.maxY)) / 4.0 * 1.18
        
        //print("Ticks \(rect.minX) \(rect.midX) \(rect.maxX) \(rect.minY), \(rect.midY) \(rect.maxY)")
        for i in 1 ... count {
            theta  = (3 * .pi / 4) - ((6.0 * .pi) / 4.0) * Double(i-1) / Double(count-1) + .pi
            //print("i \(i), theta \(theta * 180 / .pi)")
            point1 = CGPoint(x: length1 * sin(theta) + Double(rect.midX), y: length1 * cos(theta) + Double(rect.midY) )
            point2 = CGPoint(x: length2 * sin(theta) + Double(rect.midX), y: length2 * cos(theta) + Double(rect.midY) )
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
        let length1 = min(Double(rect.maxX), Double(rect.maxY)) / 4.0 * 1.30
        let length2 = min(Double(rect.maxX), Double(rect.maxY)) / 4.0 * 1.22
        
        //print("count: \(count)")
        //print("width: \(width)")
        //print("Fine Ticks \(rect.minX) \(rect.midX) \(rect.maxX) \(rect.minY), \(rect.midY) \(rect.maxY)")
        
        for i in 1 ... (5*(count-1)) {
            theta  = (3 * .pi / 4) - ((6.0 * .pi) / 4.0) * (Double(i) / 5.0) / (Double(5*(count-1)) / 5.0) + .pi
            //print("i \(i), theta \(theta * 180 / .pi)")
            point1 = CGPoint(x: length1 * sin(theta) + Double(rect.midX), y: length1 * cos(theta) + Double(rect.midY))
            point2 = CGPoint(x: length2 * sin(theta) + Double(rect.midX), y: length2 * cos(theta) + Double(rect.midY))
            p.move(to: point1)
            p.addLine(to: point2)
        }

        //p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        //p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        //p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        //p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))

        
        return p.strokedPath(.init(lineWidth: 1, lineCap: .square ))
    }
}


struct DrawLabels: View {
    
    let labels: [Double]
    let value: Double
    let fmtstr: String
    let minValue: Double
    let maxValue: Double
    let legend: String
    let units: String
    
    var body: some View {
        ZStack {
            GeometryReader { gr in
                //Text("\(gr.size.width), \(gr.size.height)")
                ForEach((0 ..< self.labels.count), id: \.self) {
                    //th = -3 * .pi / 4 + $0 * 2 * (3 * .pi / 4)/5
                    //xp = 150 / 2 - 150 / 2 * sin(th)
                    //yp = 150 / 2 - 150 / 2 * cos(th)
                    Text(String(format: self.fmtstr, self.labels[$0])).position(labelPoint(value: self.labels[$0], length: 0.88*min(Double(gr.size.width), Double(gr.size.height)) / 2.0, centerX: Double(gr.size.width) / 2.0, centerY: Double(gr.size.height) / 2.0, minValue: self.minValue, maxValue: self.maxValue)).font(.system(size: 12))
                    //Text("\(self.labels[$0])").position(labelPoint(value: self.labels[$0], length: 0.88*min(Double(gr.size.width), Double(gr.size.height)) / 2.0, centerX: Double(gr.size.width) / 2.0, centerY: Double(gr.size.height) / 2.0, minValue: self.minValue, maxValue: self.maxValue)).font(.system(size: 12))
                }
                Text(self.units).position(CGPoint(x: gr.size.width/2, y: 0.55 * gr.size.width / 2.0 + gr.size.height / 2.0)).font(.system(size: 15))
                Text(self.legend).position(CGPoint(x: gr.size.width/2, y: 0.76 * gr.size.width / 2.0 + gr.size.height / 2.0)).font(.system(size: 18))
            }
        }
    }
}

struct GaugeArc : Shape {
    func path(in rect: CGRect) -> Path {
        //print("GaugeArc \(rect.minX) \(rect.midX) \(rect.maxX) \(rect.minY), \(rect.midY) \(rect.maxY)")
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y:rect.midY), radius: min(rect.midX, rect.midY)*0.65, startAngle: .degrees(-135-90-10), endAngle: .degrees(135-90+10), clockwise: false)
        return p.strokedPath(.init(lineWidth: min(rect.maxX, rect.maxY)/16, lineCap: .round))
    }
}

struct Needle: Shape {

    func path(in rect: CGRect) -> Path {

        var path = Path()
        let eps: CGFloat = 0.03 * min(rect.maxX, rect.maxY)
        let lenscale: CGFloat = 0.55
        let len: CGFloat = lenscale * min((rect.maxX - rect.minX), (rect.maxY - rect.minY)) / CGFloat(2.0)
        //print("Needle \(rect.minX) \(rect.midX) \(rect.maxX) \(rect.minY), \(rect.midY) \(rect.maxY)")
        path.addEllipse(in: CGRect(x: rect.midX - eps, y: rect.midY - eps, width: eps*2, height: eps*2))
        path.move(to: CGPoint(x: Double(-eps + rect.midX), y: Double(0 + rect.midY)))
        path.addLine(to: CGPoint(x: Double(-eps/5 + rect.midX), y: Double(-len + rect.midY)))
        path.addLine(to: CGPoint(x: Double( eps/5 + rect.midX), y: Double(-len + rect.midY)))
        path.addLine(to: CGPoint(x: Double(eps+rect.midX), y: Double(0+rect.midY)))
        path.addLine(to: CGPoint(x: Double(-eps + rect.midX), y: Double(0 + rect.midY)))

        return path
    }
}

struct Bug: Shape {

    func path(in rect: CGRect) -> Path {

        var path = Path()
        let epsW: CGFloat = 0.025 * min(rect.maxX, rect.maxY)
        let epsH: CGFloat = -0.06 * min(rect.maxX, rect.maxY)
        let lenscale: CGFloat = 0.55
        let len: CGFloat = lenscale * min((rect.maxX - rect.minX), (rect.maxY - rect.minY)) / CGFloat(2.0)
        //print("Needle \(rect.minX) \(rect.midX) \(rect.maxX) \(rect.minY), \(rect.midY) \(rect.maxY)")
        
        path.move(to: CGPoint(x: Double(-epsW + rect.midX), y: Double(-len + epsH + rect.midY)))
        path.addLine(to: CGPoint(x: Double(rect.midX), y: Double(-len + rect.midY)))
        path.addLine(to: CGPoint(x: Double(epsW+rect.midX), y: Double(-len + epsH + rect.midY)))
        //return path.strokedPath(.init(lineWidth: CGFloat(2), lineCap: .round))
        return path
    }
}

private func CGRotate (x: Double, y: Double, x0: Double, y0: Double, rotation: Double) -> CGPoint {
    let ss = sin(rotation)
    let cs = cos(rotation)
    return CGPoint(x: x * cs - y * ss + x0, y: x * ss + y * cs + y0)
}

private func labelPoint(value: Double, length: Double, centerX: Double, centerY: Double, minValue: Double, maxValue: Double) -> CGPoint {
    let a: Double = Double(labelAngle(value: value, minValue: minValue, maxValue: maxValue))
    let p: CGPoint = CGPoint(x: length*sin(a) + centerX, y: length*cos(a) + centerY)
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
