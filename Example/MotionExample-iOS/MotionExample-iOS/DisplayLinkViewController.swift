//
//  ViewController.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 8/25/20.
//

import Motion
import UIKit

fileprivate class DisplayLinkView: UIView {

    var scale: CGPoint = CGPoint(x: 1.0, y: 1.0)

    lazy var animation: DisplayLinkAnimation<CGPoint> = {
        let animation = DisplayLinkAnimation<CGPoint>()
        animation.valueType = .accumulatedTime
        animation.onValueChanged(disableActions: true) { [weak self] (newValue) in
            guard let self = self else { return }
            self.scale = CGPoint(x: 1.0 + newValue.x, y: 1.0 + newValue.y)
            self.layer.transform = CATransform3DMakeScale(self.scale.x, self.scale.y, 1.0)
            self.superview?.setNeedsLayout()
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

        animation.start()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        animation.stop(resolveImmediately: true, postValueChanged: true)
        reset()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        animation.stop(resolveImmediately: true, postValueChanged: true)
        reset()
    }


    private func reset() {
        self.scale = CGPoint(x: 1.0, y: 1.0)

        CADisableActions {
            self.layer.transform = CATransform3DMakeScale(self.scale.x, self.scale.y, 1.0)
        }
    }

}

class DisplayLinkViewController: UIViewController {

    fileprivate var bouncyView: DisplayLinkView!
    fileprivate var timeElapsedLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.bouncyView = DisplayLinkView(frame: .zero)
        bouncyView.backgroundColor = MotionBlue
        view.addSubview(bouncyView)

        self.timeElapsedLabel = UILabel(frame: .zero)
        timeElapsedLabel.font = .preferredFont(forTextStyle: .subheadline)
        view.addSubview(timeElapsedLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bouncyView.bounds = CGRect(x: 0.0, y: 0.0, width: 88.0, height: 88.0)
        bouncyView.layer.position = CGPoint(x: view.bounds.size.width / 2.0, y: view.bounds.size.height / 2.0)

        timeElapsedLabel.text = "Time elapsed since press: \(bouncyView.animation.value)"
        timeElapsedLabel.sizeToFit()
        timeElapsedLabel.bounds.size.width = view.bounds.size.width
        timeElapsedLabel.layer.position = CGPoint(x: view.bounds.size.width / 2.0, y: (view.bounds.size.height / 2.0) + (bouncyView.bounds.size.height * bouncyView.scale.y))
    }

}

import SwiftUI

public struct DisplayLinkDemo: UIViewControllerRepresentable {

    public func makeUIViewController(context: Context) -> some UIViewController {
        return DisplayLinkViewController(nibName: nil, bundle: nil)
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

}
