//
//  DecayViewController.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 12/12/20.
//

import Motion
import UIKit

class ScrollViewController: UIViewController {

    let scrollView = CustomCustomScrollView(frame: .zero)
    let label = UILabel(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        label.font = UIFont.monospacedSystemFont(ofSize: 12.0, weight: .regular)
        label.text = try? String(contentsOfFile: Bundle.main.path(forResource: "ScrollViewContents", ofType: "txt")!)
        label.numberOfLines = 0

        scrollView.scrollsHorizontally = false
        scrollView.addSubview(label)

        view.addSubview(scrollView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        label.frame.size = label.sizeThatFits(CGSize(width: view.bounds.size.width, height: .greatestFiniteMagnitude))
        scrollView.frame = view.bounds
        scrollView.contentSize = CGSize(width: view.bounds.size.width, height: label.bounds.size.height)
    }

}

import SwiftUI

struct ScrollViewDemo: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> some UIViewController {
        return ScrollViewController(nibName: nil, bundle: nil)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

}
