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

public protocol DoubleIntializable: FloatingPoint & ExpressibleByFloatLiteral & Comparable {

    init(_ value: Double)

}

extension Float: DoubleIntializable, EquatableEnough {}
extension Double: DoubleIntializable, EquatableEnough {}
extension CGFloat: DoubleIntializable, EquatableEnough {}

// MARK: - EquatableEnough

public protocol EquatableEnough: Comparable {

    func approximatelyEqual(to: Self) -> Bool

}

public extension EquatableEnough where Self: FloatingPoint & DoubleIntializable {

    func approximatelyEqual(to other: Self) -> Bool {
        return abs(self - other) < Self(0.01)
    }

}

// MARK: - SIMD Extensions

extension SIMD2: EquatableEnough, Comparable where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD3: EquatableEnough, Comparable where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD4: EquatableEnough, Comparable where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD8: EquatableEnough, Comparable where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD16: EquatableEnough, Comparable where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD32: EquatableEnough, Comparable where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD64: EquatableEnough, Comparable where Scalar: DoubleIntializable & EquatableEnough {

    public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}
