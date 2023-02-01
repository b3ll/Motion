//
//  BouncyView.swift
//  MotionMovieMaker
//
//  Created by Adam Bell on 1/28/23.
//

import Motion
import UIKit

public let MotionBlue = UIColor(red: 0.0/255.0, green: 212.0/255.0, blue: 255.0/255.0, alpha: 1.0)

public class BouncyView: UIView {

    lazy var spring: SpringAnimation<CGFloat> = {
        let animation = SpringAnimation<CGFloat>(initialValue: 1.0)
        animation.configure(response: 0.4, dampingRatio: 0.4)
        animation.onValueChanged(disableActions: true) { [weak self] (newValue) in
            self?.layer.transform = CATransform3DMakeScale(newValue, newValue, 1.0)
        }
        return animation
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = MotionBlue
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var bounds: CGRect {
        didSet {
            self.layer.cornerRadius = bounds.size.width / 2.0
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        spring.toValue = 0.5
        spring.start()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        spring.toValue = 1.0
        spring.velocity = 50.0
        spring.start()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        spring.toValue = 1.0
        spring.velocity = 0.0
        spring.start()
    }

}
