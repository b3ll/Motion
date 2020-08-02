//
//  EquatableEnough.swift
//  
//
//  Created by Adam Bell on 8/2/20.
//

import CoreGraphics
import Foundation

// MARK: - DoubleInitializable

// I hate that this has to exist, I really want to get rid of it.

public protocol DoubleIntializable: FloatingPoint {

    init(_ value: Double)

}

extension Float: DoubleIntializable, EquatableEnough {}
extension Double: DoubleIntializable, EquatableEnough {}
extension CGFloat: DoubleIntializable, EquatableEnough {}

// MARK: - EquatableEnough

public protocol EquatableEnough {

    func approximatelyEqual(to: Self) -> Bool

}

public extension EquatableEnough where Self: FloatingPoint & DoubleIntializable {

    func approximatelyEqual(to other: Self) -> Bool {
        return abs(self - other) < Self(0.01)
    }

}

// MARK: - SIMD Extensions

extension SIMD2: EquatableEnough where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

}

extension SIMD3: EquatableEnough where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

}

extension SIMD4: EquatableEnough where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

}

extension SIMD8: EquatableEnough where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

}

extension SIMD16: EquatableEnough where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

}

extension SIMD32: EquatableEnough where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

}

extension SIMD64: EquatableEnough where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

}
