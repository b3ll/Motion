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

    public let easingFunction: EasingFunction<CGFloat>

    public init(_ easingFunction: EasingFunction<CGFloat>) {
        self.easingFunction = easingFunction
    }

    public func path(in rect: CGRect) -> Path {
        let pointCount = rect.size.width * 3.0

        let points: [CGPoint] = stride(from: 0.0, to: pointCount, by: 1.0).map { (i) -> CGPoint in
            let percent = CGFloat(i) / CGFloat(pointCount)

            let minY = rect.size.height * 0.15
            let maxY = rect.size.height * 0.85

            let value = easingFunction.interpolate(minY...maxY, fraction: Double(percent))

            return CGPoint(x: percent * rect.size.width, y: value)
        }

        var path = Path()
        path.addLines(points)
        return path
    }

}

public struct EasingFunctionGraphView: View {

    public let easingFunction: EasingFunction<CGFloat>

    public var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)

            EasingFunctionShape(easingFunction)
                .stroke(lineWidth: 4.0)
                .foregroundColor(.blue)
                .padding(12.0)

        }
        .frame(width: 320.0, height: 320.0, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }

}

public struct SpringAnimationShape: Shape {

    public enum GraphType {
        case position
        case velocity
    }

    public let springAnimation: SpringAnimation<CGFloat>

    public let graphType: GraphType

    public let duration: CFTimeInterval

    public init(_ animation: SpringAnimation<CGFloat>, graphType: GraphType, duration: CFTimeInterval) {
        self.springAnimation = animation
        self.graphType = graphType
        self.duration = duration
    }

    public func path(in rect: CGRect) -> Path {
        let dt = 1.0 / 60.0

        springAnimation.stop()
        springAnimation.value = 0.0
        springAnimation.toValue = 1.0

        let height = rect.size.height / 2.0

        let points: [CGPoint] = stride(from: 0.0, to: duration, by: dt).map { (i) -> CGPoint in
            let percent: CGFloat = CGFloat(i / duration)

            let point: CGPoint

            switch graphType {
            case .position:
                point = CGPoint(x: rect.width * percent, y: height + ((springAnimation.toValue - springAnimation.value) * height))
            case .velocity:
                point = CGPoint(x: rect.width * percent, y: height + springAnimation.velocity * height / 3.0)
            }

            springAnimation.tick(dt)

            return point
        }

        var path = Path()
        path.addLines(points)
        return path
    }

}

public struct SpringAnimationGraphView: View {

    public let springAnimation: SpringAnimation<CGFloat>

    public let graphType: SpringAnimationShape.GraphType

    public let duration: CFTimeInterval

    public init(springAnimation: SpringAnimation<CGFloat>, graphType: SpringAnimationShape.GraphType, duration: CFTimeInterval = 3.0) {
        self.springAnimation = springAnimation
        self.graphType = graphType
        self.duration = duration
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .foregroundColor(.black)

            SpringAnimationShape(springAnimation, graphType: graphType, duration: duration)
                .stroke(lineWidth: 4.0)
                .foregroundColor(.blue)
                .padding(12.0)

            HStack {
                Text(String(format: "Friction: %.2f", springAnimation.friction))
                Text(String(format: "Stiffness: %.2f", springAnimation.stiffness))
            }
            .foregroundColor(.white)
            .padding()
        }
        .frame(height: 320.0)
    }

}

struct SwiftUIView_Previews: PreviewProvider {

    static func springAnimation(response: Double, damping: Double) -> SpringAnimation<CGFloat> {
        let springAnimation = SpringAnimation<CGFloat>()
        springAnimation.configure(response: response, damping: damping)
        return springAnimation
    }

    static let criticallyDamped = { () -> SpringAnimation<CGFloat> in
        let springAnimation = SpringAnimation<CGFloat>()
        springAnimation.friction = 10.0
        springAnimation.stiffness = 2.0
        return springAnimation
    }()

    static var previews: some View {
                Group {
            ForEach(EasingFunction<CGFloat>.allFunctions, id: \.self) { easingFunction in
                EasingFunctionGraphView(easingFunction: easingFunction)
                    .previewLayout(.sizeThatFits)
            }
        }

        if #available(iOS 14.0, macOS 11.0, *) {
            LazyVGrid(columns: [GridItem(.fixed(320)), GridItem(.fixed(320)), GridItem(.fixed(320))], alignment: .center, spacing: 2.0) {
                ForEach((1...10), id: \.self) { dampingConstant in
                    SpringAnimationGraphView(springAnimation: springAnimation(response: 1.0, damping: Double(dampingConstant) / 10.0), graphType: .position)
                        .previewLayout(.sizeThatFits)
                }

                // Critically Damped
                SpringAnimationGraphView(springAnimation: criticallyDamped, graphType: .position, duration: 30.0)
            }
            .background(Color.black)
            .previewLayout(.sizeThatFits)
        } else {
            Group {
                ForEach((1...10), id: \.self) { dampingConstant in
                    SpringAnimationGraphView(springAnimation: springAnimation(response: 1.0, damping: Double(dampingConstant) / 10.0), graphType: .position)
                        .previewLayout(.sizeThatFits)
                }

                // Critically Damped
                SpringAnimationGraphView(springAnimation: criticallyDamped, graphType: .position, duration: 30.0)
            }
        }
    }

}

#endif
