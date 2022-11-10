//
//  SwiftUIDemoView.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 11/8/22.
//

import Motion
import SwiftUI

class AnimationWrapper<T: Motion.Animation>: ObservableObject {

    init(_ animation: T) {
        self.animation = animation
    }


    var animation: T

}

struct SwiftUIDemoView: View {

    @StateObject var animationWrapper = AnimationWrapper(SpringAnimation<CGPoint>(response: 0.8, dampingRatio: 0.7))

    @State var position: CGPoint = .zero
    @GestureState var gestureTranslation: CGPoint = .zero

    let circleSize = 88.0

    var body: some View {
        Circle()
            .foregroundColor(Color(MotionBlue))
            .frame(width: circleSize, height: circleSize)
            .offset(x: position.x + gestureTranslation.x, y: position.y + gestureTranslation.y)
            .gesture(
                DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
                    .updating($gestureTranslation) { dragGesture, gestureTranslation, _ in
                        // Halt any in-flight animations.
                        animationWrapper.animation.stop()

                        gestureTranslation = translation(for: dragGesture)
                    }
                    .onEnded { dragGesture in
                        let totalTranslation = translation(for: dragGesture)

                        // Update the animator to start from the current position + whatever translation was done
                        // this allows subsequent drags to also work correctly.
                        animationWrapper.animation.updateValue(to: CGPoint(x: position.x + totalTranslation.x, y: position.y + totalTranslation.y), postValueChanged: true)
                        animationWrapper.animation.toValue = .zero
                        animationWrapper.animation.velocity = dragGesture.velocity
                        animationWrapper.animation.start()
                    }
            )
            .onAppear {
                animationWrapper.animation.onValueChanged() {  newPosition in
                    self.position = newPosition
                }
            }
    }

    private func translation(for dragGesture: DragGesture.Value) -> CGPoint {
        let halfCircleSize = circleSize / 2.0
        return CGPoint(x: dragGesture.startLocation.x + dragGesture.translation.width - halfCircleSize,
                       y: dragGesture.startLocation.y + dragGesture.translation.height - halfCircleSize)
    }

}

extension DragGesture.Value {

    /// h/t @lukaskubanek https://stackoverflow.com/questions/62906109/what-is-the-best-way-to-get-drag-velocity/73426600#73426600
    internal var velocity: CGPoint {
        let valueMirror = Mirror(reflecting: self)
        for valueChild in valueMirror.children {
            if valueChild.label == "velocity" {
                let velocityMirror = Mirror(reflecting: valueChild.value)
                for velocityChild in velocityMirror.children {
                    if velocityChild.label == "valuePerSecond" {
                        if let velocity = velocityChild.value as? CGSize {
                            return CGPoint(x: velocity.width, y: velocity.height)
                        }
                    }
                }
            }
        }
        assertionFailure("Unable to retrieve velocity from \(Self.self)")
        return .zero
    }

}

struct SwiftUIDemoView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIDemoView()
    }
}
