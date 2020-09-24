//
//  EquatableEnough.swift
//  
//
//  Created by Adam Bell on 8/2/20.
//

import CoreGraphics
import Foundation
import simd

// MARK: - FloatingPointInitializable

/**
 I hate that this has to exist, I really want to get rid of it.
 It really only exists so that when working with Scalars and SIMD, one can convert to / from them using Doubles or Floating point numbers.
 Technically there shouldn't be any overhead by this, it's just to make the compiler believe that it's ok to convert types.
 */
public protocol FloatingPointInitializable: FloatingPoint & ExpressibleByFloatLiteral & Comparable {

    init(_ value: Float)
    init(_ value: Double)

}

extension Float: FloatingPointInitializable, EquatableEnough {}
extension Double: FloatingPointInitializable, EquatableEnough {}
extension CGFloat: FloatingPointInitializable, EquatableEnough {}

// MARK: - EquatableEnough

public protocol EquatableEnough: Comparable {

    func approximatelyEqual(to: Self) -> Bool

}

public extension EquatableEnough {

    @inlinable static var epsilon: Double {
        return 0.001
    }

}

public extension EquatableEnough where Self: FloatingPointInitializable {

    @inlinable static var epsilon: Self {
        return 0.001
    }

}

public extension EquatableEnough where Self: SupportedSIMD {

    @inlinable static var epsilon: Scalar {
        return .epsilon
    }

}

public extension EquatableEnough where Self: FloatingPoint & FloatingPointInitializable {

    @inlinable func approximatelyEqual(to other: Self) -> Bool {
        return abs(self - other) < .epsilon
    }

}

// MARK: - SIMD Extensions

extension SIMD2: EquatableEnough, Comparable where Scalar: FloatingPointInitializable & EquatableEnough {

    @inlinable public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD3: EquatableEnough, Comparable where Scalar: FloatingPointInitializable & EquatableEnough {

    @inlinable public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD4: EquatableEnough, Comparable where Scalar: FloatingPointInitializable & EquatableEnough {

    @inlinable public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD8: EquatableEnough, Comparable where Scalar: FloatingPointInitializable & EquatableEnough {

    @inlinable public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD16: EquatableEnough, Comparable where Scalar: FloatingPointInitializable & EquatableEnough {

    @inlinable public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD32: EquatableEnough, Comparable where Scalar: FloatingPointInitializable & EquatableEnough {

    @inlinable public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}

extension SIMD64: EquatableEnough, Comparable where Scalar: FloatingPointInitializable & EquatableEnough {

    @inlinable public func approximatelyEqual(to other: Self) -> Bool {
        return self.indices.reduce(true) {
            return $0 && self[$1].approximatelyEqual(to: other[$1])
        }
    }

    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.indices.reduce(true) {
            return $0 && lhs[$1] < rhs[$1]
        }
    }

}
