//
//  DraggableViewViewController.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 12/11/20.
//

import Motion
import UIKit

class DraggableViewController: UIViewController {

    let draggableView = UIView(frame: .zero)
    let spring = SpringAnimation<CGPoint>(response: 0.8, dampingRatio: 0.5)

    override func viewDidLoad() {
        super.viewDidLoad()

        draggableView.layer.masksToBounds = true
        draggableView.backgroundColor = MotionBlue
        view.addSubview(draggableView)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        draggableView.addGestureRecognizer(panGestureRecognizer)

        draggableView.center = view.center
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        draggableView.bounds.size = CGSize(width: 64.0, height: 64.0)
        draggableView.layer.cornerRadius = draggableView.bounds.size.height / 2.0
    }

    @objc private func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            spring.stop()
        case .changed:
            draggableView.center = gestureRecognizer.location(in: view)
            spring.updateValue(to: draggableView.center)
        case .ended, .cancelled:
            spring.onValueChanged { [weak self] newValue in
                self?.draggableView.center = newValue
            }
            spring.velocity = gestureRecognizer.velocity(in: view)
            spring.toValue = view.center
            spring.start()
        default:
            break
        }
    }

}

import SwiftUI

struct DraggableDemo: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> some UIViewController {
        return DraggableViewController(nibName: nil, bundle: nil)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }

}
