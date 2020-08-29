//
//  EasingFunctionGraphView.swift
//  
//
//  Created by Adam Bell on 8/28/20.
//

#if canImport(SwiftUI)

import CoreGraphics
import SwiftUI

public struct EasingFunctionShape: Shape {

    let easingFunction: EasingFunction<CGFloat>

    public init(easingFunction: EasingFunction<CGFloat>) {
        self.easingFunction = easingFunction
    }

    public func path(in rect: CGRect) -> Path {
        let pointCount = rect.size.width * 3.0

        let points: [CGPoint] = stride(from: 0.0, to: pointCount, by: 1.0).map { (i) -> CGPoint in
            let percent = CGFloat(i) / CGFloat(pointCount)

            let minY = rect.size.height * 0.15
            let maxY = rect.size.height * 0.85

            let value = easingFunction.interpolate(minY...maxY, fraction: Double(percent))

            return CGPoint(x: percent * rect.size.width, y: value) //CGFloat(minY + ((maxY - minY) * value)))
        }

        var path = Path()
        path.addLines(points)
        return path
    }

}

struct EasingFunctionGraphView: View {

    let easingFunction: EasingFunction<CGFloat>

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)

            EasingFunctionShape(easingFunction: easingFunction)
                .stroke(lineWidth: 4.0)
                .foregroundColor(.blue)
                .padding(12.0)

        }
        .frame(width: 320.0, height: 320.0, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }

}

struct SwiftUIView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(EasingFunction<CGFloat>.allCases, id: \.self) { easingFunction in
            EasingFunctionGraphView(easingFunction: easingFunction)
                .previewLayout(.sizeThatFits)
        }
    }

}

#endif
