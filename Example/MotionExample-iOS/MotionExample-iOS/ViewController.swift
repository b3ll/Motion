//
//  ViewController.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 8/25/20.
//

import UIKit

class ViewController: UIViewController {

    var bouncyView: BouncyView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.bouncyView = BouncyView(frame: .zero)
        bouncyView.backgroundColor = .blue
        view.addSubview(bouncyView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bouncyView.bounds = CGRect(x: 0.0, y: 0.0, width: 88.0, height: 88.0)
        bouncyView.layer.position = CGPoint(x: view.bounds.size.width / 2.0, y: view.bounds.size.height / 2.0)
    }

}

