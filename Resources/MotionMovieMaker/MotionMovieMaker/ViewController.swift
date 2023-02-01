//
//  ViewController.swift
//  MotionMovieMaker
//
//  Created by Adam Bell on 1/28/23.
//

import Decomposed
import Motion
import UIKit

class ViewController: UIViewController {

    let serialRenderQueue = DispatchQueue(label: "animationRenderQueue", qos: .userInitiated)

    lazy private var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)

        let fontSize: CGFloat = 285
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        let roundedFont: UIFont
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            roundedFont = UIFont(descriptor: descriptor, size: fontSize)
        } else {
            roundedFont = systemFont
        }
        label.font = roundedFont
        label.textColor = .label
        label.minimumScaleFactor = 1.0
        label.adjustsFontSizeToFitWidth = false

        return label
    }()

    lazy private var oLabel: UILabel = {
        let label = UILabel(frame: .zero)

        label.font = self.titleLabel.font
        label.text = "O"
        return label
    }()

    // See Sonic 2's intro for the inspiration :)
    let motionAnimation = SpringAnimation<CGFloat>(response: 0.5, dampingRatio: 0.575)

    let bouncyView = BouncyView(frame: .zero)

    private var frameNumber: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        titleLabel.text = "M    TION"
        view.addSubview(titleLabel)

        view.addSubview(bouncyView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        motionAnimation.onValueChanged(disableActions: true) { [unowned self] newValue in
            bouncyView.layer.position.x = newValue
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        view.layoutIfNeeded()

        zoomRight(animated: false, completion: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.startAnimation()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        oLabel.sizeToFit()

        titleLabel.sizeToFit()
        titleLabel.layer.position = CGPoint(x: view.bounds.size.width / 2.0, y: view.bounds.size.height / 2.0)

        // Size the bouncy view based on the o's size in the font.
        let bouncyViewSize = min(oLabel.bounds.size.width, oLabel.bounds.size.height)
        bouncyView.bounds.size = CGSize(width: bouncyViewSize, height: bouncyViewSize)
        bouncyView.layer.position.y = view.bounds.size.height / 2.0
    }

    func startAnimation() {
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // This is… definitely something.
        renderDelayFrames(count: 60) {
            self.zoomLeft(velocity: -100.0) {
                self.zoomRight(velocity: 100.0) {
                    self.settleInMiddle(velocity: 100.0) {
                        self.renderDelayFrames(count: 8 * 60    ) {
                            print("Done rendering: \(URL.documentsDirectory.absoluteString)")
                        }
                    }
                }
            }
        }
    }

    func zoomLeft(animated: Bool = true, velocity: CGFloat? = nil, completion: (() -> Void)?) {
        motionAnimation.configure(response: 0.6, dampingRatio: 1.0)

        zoom(to: -bouncyView.bounds.size.width * 4.0,
             animated: animated,
             velocity: velocity,
             resolvesUponReachingToValue: true,
             completion: completion)
    }

    func zoomRight(animated: Bool = true, velocity: CGFloat? = nil, completion: (() -> Void)?) {
        motionAnimation.configure(response: 0.6, dampingRatio: 1.0)

        zoom(to: view.bounds.size.width + (bouncyView.bounds.size.width * 4.0),
             animated: animated,
             velocity: velocity,
             resolvesUponReachingToValue: true,
             completion: completion)
    }

    func settleInMiddle(animated: Bool = true, velocity: CGFloat? = nil, completion: (() -> Void)?) {
        motionAnimation.configure(response: 0.6, dampingRatio: 0.675)

        bouncyView.layer.filters = nil

        zoom(to: titleLabel.frame.minX + bouncyView.bounds.size.width + 150.0,
             animated: animated,
             velocity: velocity,
             resolvesUponReachingToValue: false,
             completion: completion)
    }

    private func zoom(to value: CGFloat, animated: Bool = true, velocity: CGFloat? = nil, resolvesUponReachingToValue: Bool = false, completion: (() -> Void)?) {
        if !animated {
            motionAnimation.completion = nil
            motionAnimation.stop()

            motionAnimation.updateValue(to: value, postValueChanged: true)
            completion?()
            return
        }

        motionAnimation.velocity = velocity ?? motionAnimation.velocity
        motionAnimation.toValue = value
        motionAnimation.resolvesUponReachingToValue = resolvesUponReachingToValue
        motionAnimation.completion = completion

        renderUntilResolved()
    }

    private func renderUntilResolved() {
        if motionAnimation.hasResolved() {
            return
        }


        // Tick the animation manually after rendering each frame.
        motionAnimation.tick(frame: .init(1.0 / 60.0))

        renderToDisk(frameNumber: frameNumber) {
            self.frameNumber += 1

            self.renderUntilResolved()
        }
    }

    private var delayFramesRemaining: Int = 0

    private func renderDelayFrames(count: Int, completion: @escaping () -> Void) {
        self.delayFramesRemaining = count
        renderDelayFrame(framesRemaining: &delayFramesRemaining, completion: completion)
    }

    private func renderDelayFrame(framesRemaining: UnsafeMutablePointer<Int>, completion: @escaping () -> Void) {
        if framesRemaining.pointee == 0 {
            completion()
            return
        }

        renderToDisk(frameNumber: frameNumber) {
            self.frameNumber += 1

            framesRemaining.pointee -= 1

            self.renderDelayFrame(framesRemaining: framesRemaining, completion: completion)
        }
    }

    private func renderToDisk(frameNumber: Int, completion: @escaping () -> Void) {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        // TOOD: For some reason this just fails to render random frames, figure out why.
        serialRenderQueue.async {
            guard let pngData = image.pngData() else { fatalError("Failed to generate pngData") }

            do {
                try pngData.write(to: .documentsDirectory.appending(path: "\(String(format: "%03d", frameNumber)).png"))
            } catch {
                fatalError(error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion()
            }
        }
    }

}
