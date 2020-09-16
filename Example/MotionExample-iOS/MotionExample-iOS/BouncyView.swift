//
//  BouncyView.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 8/25/20.
//

import Motion
import UIKit

class BouncyView: UIView {

    lazy var spring: SpringAnimation<CGFloat> = {
        let animation = SpringAnimation<CGFloat>(initialValue: 1.0)
        animation.configure(response: 0.4, dampingRatio: 0.4)
        animation.valueChanged(disableActions: true) { [weak self] (newValue) in
            self?.layer.transform = CATransform3DMakeScale(newValue, newValue, 1.0)
        }
        return animation
    }()

    override var bounds: CGRect {
        didSet {
            self.layer.cornerRadius = bounds.size.width / 2.0
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        spring.toValue = 0.5
        spring.start()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        spring.toValue = 1.0
        spring.velocity = -50.0
        spring.start()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        spring.toValue = 1.0
        spring.velocity = 0.0
        spring.start()
    }

}
