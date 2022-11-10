//
//  ViewController.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 8/25/20.
//

import Motion
import UIKit

internal class BouncyView: UIView {

    lazy var spring: SpringAnimation<CGFloat> = {
        let animation = SpringAnimation<CGFloat>(initialValue: 1.0)
        animation.configure(response: 0.4, dampingRatio: 0.4)
        animation.onValueChanged(disableActions: true) { [weak self] (newValue) in
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
        spring.velocity = 50.0
        spring.start()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        spring.toValue = 1.0
        spring.velocity = 0.0
        spring.start()
    }

}

class BouncyViewController: UIViewController {

    fileprivate var bouncyView: BouncyView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.bouncyView = BouncyView(frame: .zero)
        bouncyView.backgroundColor = MotionBlue
        view.addSubview(bouncyView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bouncyView.bounds = CGRect(x: 0.0, y: 0.0, width: 88.0, height: 88.0)
        bouncyView.layer.position = CGPoint(x: view.bounds.size.width / 2.0, y: view.bounds.size.height / 2.0)
    }

}

import SwiftUI

public struct BouncyDemo: UIViewControllerRepresentable {

    public func makeUIViewController(context: Context) -> some UIViewController {
        return BouncyViewController(nibName: nil, bundle: nil)
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

}
