//
//  chartRecorder.swift
//  Medido-SwiftUI
//
//  Created by David Mcqueeney on 2/20/20.
//  Copyright © 2020 David McQueeney. All rights reserved.
//

import SwiftUI

fileprivate var cwid: CGFloat = 0

struct chartRecorder: View {
    
    let aspect: CGFloat
    let hgrid: Int
    let vgrid: Int
    let XP: [Double]
    let YP: [Double]
    let ZP: [Double]
    let WP: [Double]
    let xrange: Double
    let nlabel: Int
    let ymin: Double
    let ymax: Double
    let ylabel: String
    let yvalue: Double
    let ycolor: Color
    let zmin: Double
    let zmax: Double
    let zlabel: String
    let zvalue: Double
    let zcolor: Color
    let wmin: Double
    let wmax: Double
    let wcolor: Color
    let wshow: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            /*HStack (spacing: 0){
             Text(self.ylabel).foregroundColor(self.ycolor).font(.system(size: 12))
             Text("\(self.yvalue, specifier: "%.2f")").foregroundColor(self.ycolor).font(.system(size: 12))
             Spacer()
             Text(self.zlabel).foregroundColor(self.zcolor).font(.system(size: 12))
             Text("\(self.zvalue, specifier: "%.2f")").foregroundColor(self.zcolor).font(.system(size: 12))
            }.padding(.horizontal)*/
            
            ZStack (alignment: .top){
                HStack (spacing: 0){
                    Text(self.ylabel).foregroundColor(self.ycolor).font(.system(size: 12))
                    Spacer()
                    Text(self.zlabel).foregroundColor(self.zcolor).font(.system(size: 12))
                }.offset(y: -16)
                graphRect().aspectRatio(self.aspect, contentMode: .fill)
                graphGrid(hgrid: self.hgrid, vgrid: self.vgrid).aspectRatio(self.aspect, contentMode: .fill)
                graphData(XP: self.XP, YP: self.YP, xrange: self.xrange, ymin: self.ymin, ymax: self.ymax, linewidth: 2).aspectRatio(self.aspect, contentMode: .fill).foregroundColor(self.ycolor).clipped()
                graphData(XP: self.XP, YP: self.ZP, xrange: self.xrange, ymin: self.zmin, ymax: self.zmax, linewidth: 2).aspectRatio(self.aspect, contentMode: .fill).foregroundColor(self.zcolor).clipped()
                if wshow == true {
                    graphData(XP: self.XP, YP: self.WP, xrange: self.xrange, ymin: self.wmin, ymax: self.wmax, linewidth: 2).aspectRatio(self.aspect, contentMode: .fill).foregroundColor(self.wcolor).clipped()
                }
                graphLabels(XP: self.XP, xrange: self.xrange, nlabel: self.nlabel, wid: 0, hgt: 0)
                }.padding().clipped()
        }
    }
}


private struct graphLabels: View {

    private let XP: [Double]
    private let xrange: Double
    private let nlabel: Int
    private let wid: CGFloat
    private let hgt: CGFloat
    
    init(XP: [Double], xrange: Double, nlabel: Int, wid: CGFloat, hgt: CGFloat) {
        self.XP = XP
        self.xrange = xrange
        self.nlabel = nlabel
        self.wid = wid
        self.hgt = hgt
    }
    
    var body: some View {
        HStack {
            GeometryReader { (gR) in
                ForEach(0 ... self.nlabel+1, id: \.self) { i in
                    Text(labeltext(range: self.xrange, nlab: self.nlabel, seq: i, XP: self.XP)).position(labelpos(range: self.xrange, nlab: self.nlabel, seq: i, XP: self.XP, wid: gR.size.width, hgt: gR.size.height)).font(.system(size: 10))//.clipped()
                }
            }
        }
    }
}

private func labelpos(range: Double, nlab: Int, seq: Int, XP: [Double], wid: CGFloat, hgt: CGFloat) -> CGPoint {
    //print("labelpos")
    if XP.count > 0 {
        let intPart = Double(Int(XP.first! / (range / Double(nlab)))) * (range / Double(nlab))
        let frac = (XP.first! - Double(intPart)) / (range / Double(nlab))
        let fracPix = frac * Double(wid) / Double(nlab)
        //print("seq: \(seq), XP.first: \(XP.first!), intPart: \(intPart), frac: \(frac), fracPix: \(fracPix)")
        //print("returning: \( -fracPix + Double(seq) * Double(wid) / Double(nlab))")
        //print("hgt: \(hgt) wid: \(wid)")
        return(CGPoint(x: -fracPix + Double(seq) * Double(wid) / Double(nlab), y: Double(hgt) + 10 ))
    } else {
        return(CGPoint(x:0, y:0))
    }

}

private func labeltext(range: Double, nlab: Int, seq: Int, XP: [Double]) -> String {
    //print("labeltext")
    if XP.count > 0 {
        let intPart = Double(Int(XP.first! / (range / Double(nlab)))) * range / Double(nlab)
        //let frac = (XP.first! - Double(intPart)) / 10.0
        let ilbl = Int(intPart) + seq * Int(range / Double(nlab))
        //print(XP.first!, seq, intPart, ilbl)
        let imin = ilbl / 60
        let isec = ilbl - 60 * imin
        let iminS = String(format: "%2d", imin )
        let isecS = String(format: "%02d", isec)
        return(iminS + ":" + isecS)
        //return("\(ilbl)")
    } else {
        return("")
    }
}

private struct graphRect: Shape {
    
    func path(in rect: CGRect) -> Path {
        cwid = rect.width
        //print("cwid: \(cwid)")
        //print("rect.minX, rect.maxX, rect.minY, rect.maxY, rect.width, rect.height", rect.minX, rect.maxX, rect.minY, rect.maxY, rect.width, rect.height)
        let mult = 1.0
        var path = Path()
        path.addRect(CGRect(x: rect.minX, y: rect.minY + CGFloat(1.0 - mult) * rect.height, width: rect.width, height: rect.height - CGFloat(2.0*(1.0 - mult)) * rect.height))
        return path.strokedPath(.init(lineWidth: 2, lineCap: .square))
    }
}

private struct graphGrid: Shape {
    
    let hgrid: Int
    let vgrid: Int
    
    func path(in rect: CGRect) -> Path {
        //print("graphGrid")
        var path = Path()
        for i in 1 ... vgrid {
            path.move(to: CGPoint(x: rect.minX, y:rect.minY + CGFloat(i) * rect.height/CGFloat(vgrid)))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + CGFloat(i) * rect.height/CGFloat(vgrid)))
        }
        for i in 1 ... hgrid {
            path.move(to: CGPoint(x: rect.minX + CGFloat(i) * rect.width/CGFloat(hgrid), y:rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + CGFloat(i) * rect.width/CGFloat(hgrid), y: rect.maxY))
        }
        return path.strokedPath(.init(lineWidth: 0.5, lineCap: .square, dash: [4]))
    }
}

private struct graphData: Shape {
    
    let XP: [Double]
    let YP: [Double]
    let xrange: Double
    let ymin: Double
    let ymax: Double
    let linewidth: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var xp: CGFloat
        var yp: CGFloat
        var yt: Double
        let eps = 1.0E-6

        //print("graphdata")

        for i in 0 ..< XP.count {
            //xp =  rect.minX + CGFloat( ( (xrange + 1) / xrange) * (XP[i] - XP.first!) / xrange) * rect.width
            if YP[i] == 0.0 {
                continue
            }
            xp =  rect.minX + CGFloat((XP[i] - XP.first!) / xrange) * rect.width
            let ys = (YP[i] - ymin) / (ymax - ymin)
            if ys > 1 {
                yt = (ys - eps).truncatingRemainder(dividingBy: 1)
            } else if ys < 0 {
                yt = (ys + eps).truncatingRemainder(dividingBy: 1) + 1
            } else {
                yt = ys
            }
            let ytt = yt
            
            //print(YP[i], yt, ytt)
            yp = (1.0 - CGFloat(ytt)) * rect.height
            
            if i == 0 {
                path.move(to: CGPoint(x: xp, y:yp))
            }
            //path.addLine(to: CGPoint(x: xp, y:yp))
            path.addEllipse(in: CGRect(x: xp-1, y: yp-1, width:2, height: 2))
        }
        //return path.strokedPath(.init(lineWidth: CGFloat(linewidth), lineCap: .round))
        return path//.strokedPath(.init(lineWidth: CGFloat(linewidth), lineCap: .round))
    }
}

