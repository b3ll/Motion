//
//  AnimationGroup.swift
//  
//
//  Created by Adam Bell on 9/1/20.
//

import Foundation

public class AnimationGroup<Value: SIMDRepresentable>: Animation<Value> {

    let animations: [AnyAnimation]

    init(animations: [Animation<Value>]) {
        self.animations = animations.map { AnyAnimation($0) }
    }

    public override func hasResolved() -> Bool {
        return animations.reduce(true) { (result, animation) -> Bool in
            return result && animation.hasResolved()
        }
    }

    // MARK: - Disabled API

    @available(*, unavailable, message: "Not Supported in AnimationGroup.")
    public override var value: Value {
        get { return .zero }
        set { }
    }

    @available(*, unavailable, message: "Not Supported in AnimationGroup.")
    public override var toValue: Value {
        get { return .zero }
        set { }
    }

    @available(*, unavailable, message: "Not Supported in AnimationGroup.")
    public override var _valueChanged: ValueChangedCallback? {
        get { return nil }
        set { }
    }

    @available(*, unavailable, message: "Not Supported in AnimationGroup.")
    public override func valueChanged(disableActions: Bool = false, _ valueChangedCallback: ValueChangedCallback?) { }

    // MARK: - DisplayLinkObserver

    public override func tick(_ dt: CFTimeInterval) {
        if dt > 1.0 {
            return
        }

        animations.forEach { $0.tick(dt) }

        if !hasResolved() {
            completion?(true)
        }
    }

}
