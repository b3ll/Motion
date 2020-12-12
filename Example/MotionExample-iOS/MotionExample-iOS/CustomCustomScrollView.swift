//
//  CustomCustomScrollView.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 12/12/20.
//

import Foundation
import UIKit
import Motion

/// Extremely basic port of https://github.com/ole/CustomScrollView to test `DecayAnimation`
public class CustomCustomScrollView: UIView {

    public var contentSize: CGSize = .zero
    public var scrollsVertically: Bool = true
    public var scrollsHorizontally: Bool = true

    private var startBounds: CGRect = .zero

    public override var bounds: CGRect {
        didSet {
            updateBoundsAndBounceIfNeeded()
        }
    }

    private let bounceAnimation = SpringAnimation<CGPoint>()
    private let decayAnimation = DecayAnimation<CGPoint>()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInitForCustomCustomScrollView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInitForCustomCustomScrollView()
    }

    func commonInitForCustomCustomScrollView() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGestureRecognizer)
    }

    // MARK: - Interaction

    @objc func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
        switch panGestureRecognizer.state {
        case .began:
            bounceAnimation.stop()
            decayAnimation.stop()
            self.startBounds = bounds
        case .changed:
            var translation = panGestureRecognizer.translation(in: self)
            var bounds = self.startBounds

            if !scrollsHorizontally {
                translation.x = 0.0
            }

            if !scrollsVertically {
                translation.y = 0.0
            }

//            let newBoundsOriginX = bounds.origin.x - translation.x
//            let minBoundsOriginX: CGFloat = 0.0
//            let maxBoundsOriginX = contentSize.width - bounds.size.width
//            let constrainedBoundsOriginX = max(minBoundsOriginX, min(newBoundsOriginX, maxBoundsOriginX))
//            bounds.origin.x = constrainedBoundsOriginX + (newBoundsOriginX - constrainedBoundsOriginX) / 2
//
//            let newBoundsOriginY = bounds.origin.y - translation.y
//            let minBoundsOriginY: CGFloat = 0.0
//            let maxBoundsOriginY = contentSize.height - bounds.size.height
//            let constrainedBoundsOriginY = max(minBoundsOriginY, min(newBoundsOriginY, maxBoundsOriginY))
//            bounds.origin.y = constrainedBoundsOriginY + (newBoundsOriginY - constrainedBoundsOriginY) / 2

            bounds.origin.x = rubberband(bounds.origin.x - translation.x, range: contentSize.width)
            bounds.origin.y = rubberband(bounds.origin.y - translation.y, range: contentSize.height)

            bounceAnimation.updateValue(to: bounds.origin)

            self.bounds = bounds
        case .ended:
            var velocity = panGestureRecognizer.velocity(in: self)
            if !scrollsHorizontally {
                velocity.x = 0.0
            }

            if !scrollsVertically {
                velocity.y = 0.0
            }

            velocity.x *= -1.0
            velocity.y *= -1.0

            decayAnimation.velocity = velocity
            decayAnimation.updateValue(to: bounds.origin)
            decayAnimation.onValueChanged { [weak self] newValue in
                self?.bounds.origin = newValue
            }
            decayAnimation.start()
        default:
            break
        }
    }

    private func updateBoundsAndBounceIfNeeded() {
        let outsideBoundsMinimum = (bounds.origin.x < 0.0) || (bounds.origin.y < 0.0)
        let outsideBoundsMaximum = bounds.origin.x > contentSize.width - bounds.size.width || bounds.origin.y > contentSize.height - bounds.size.height

        if outsideBoundsMinimum || outsideBoundsMaximum {
            if decayAnimation.enabled {
                let target: CGPoint
                if outsideBoundsMinimum {
                    target = CGPoint(x: max(bounds.origin.x, 0.0), y: max(bounds.origin.y, 0.0))
                } else /* if outsideBoundsMaximum* */ {
                    target = CGPoint(x: min(bounds.origin.x, contentSize.width - bounds.size.width), y: min(bounds.origin.y, contentSize.height - bounds.size.height))
                }

                bounceAnimation.configure(stiffness: 193.41, damping: 26.70)
                bounceAnimation.updateValue(to: bounds.origin)
                bounceAnimation.toValue = target
                bounceAnimation.velocity = decayAnimation.velocity
                bounceAnimation.onValueChanged { [weak self] newValue in
                    self?.bounds.origin = newValue
                }

                bounceAnimation.start()
                decayAnimation.stop()
            }
        }
    }

}
