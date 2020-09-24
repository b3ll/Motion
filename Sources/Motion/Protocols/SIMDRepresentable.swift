//
//  File.swift
//  
//
//  Created by Adam Bell on 8/1/20.
//

import CoreGraphics
import Foundation
import simd
import RealModule

// MARK: - Supported Types

public protocol SupportedSIMD: SIMD, SIMDRepresentable, EquatableEnough where Scalar: SupportedScalar {}

public protocol SupportedScalar: SIMDScalar, FloatingPointInitializable, EquatableEnough, RealModule.Real {
    static func exp(_ x: Self) -> Self
    static func sin(_ x: Self) -> Self
    static func cos(_ x: Self) -> Self
    static func pow(_ x: Self, _ n: Int) -> Self
}

extension Float: SupportedScalar {}
extension Double: SupportedScalar {}

extension SIMD2: SupportedSIMD where Scalar: SupportedScalar {}
extension SIMD3: SupportedSIMD where Scalar: SupportedScalar {}
extension SIMD4: SupportedSIMD where Scalar: SupportedScalar {}
extension SIMD8: SupportedSIMD where Scalar: SupportedScalar {}
extension SIMD16: SupportedSIMD where Scalar: SupportedScalar {}
extension SIMD32: SupportedSIMD where Scalar: SupportedScalar {}
extension SIMD64: SupportedSIMD where Scalar: SupportedScalar {}

// MARK: - SIMDRepresentable

public protocol SIMDRepresentable: Comparable {

    associatedtype SIMDType: SupportedSIMD = Self

    init(_ simdRepresentation: SIMDType)

    func simdRepresentation() -> SIMDType

    static var zero: Self { get }

}

extension SIMDRepresentable where SIMDType == Self {

    @inlinable public init(_ simdRepresentation: SIMDType) {
        self = simdRepresentation
    }

    @inlinable public func simdRepresentation() -> Self {
        return self
    }

}

extension SIMD2: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD3: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD4: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD8: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD16: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD32: SIMDRepresentable where Scalar: SupportedScalar {}
extension SIMD64: SIMDRepresentable where Scalar: SupportedScalar {}

// These single floating point conformances technically are wasteful, but it's still a single register it gets packed in, so it's "fine".
// Actually I think the compiler is smart and optimizes these anyways.

extension Float: SIMDRepresentable {

    public typealias SIMDType = SIMD2<Float>

    @inlinable public init(_ simdRepresentation: SIMD2<Float>) {
        self = simdRepresentation[0]
    }

    @inlinable public func simdRepresentation() -> SIMD2<Float> {
        return SIMD2(self, 0.0)
    }

}

extension Double: SIMDRepresentable {

    public typealias SIMDType = SIMD2<Double>

    @inlinable public init(_ simdRepresentation: SIMD2<Double>) {
        self = simdRepresentation[0]
    }

    @inlinable public func simdRepresentation() -> SIMD2<Double> {
        return SIMD2(self, 0.0)
    }

}

// MARK: - CoreGraphics Extensions

extension CGFloat: SIMDRepresentable {

    public typealias SIMDType = SIMD2<CGFloat.NativeType>

    @inlinable public init(_ simdRepresentation: SIMD2<CGFloat.NativeType>) {
        self = CGFloat(simdRepresentation[0])
    }

    @inlinable public func simdRepresentation() -> SIMD2<CGFloat.NativeType> {
        return SIMD2(CGFloat.NativeType(self), 0.0)
    }

}

extension CGPoint: SIMDRepresentable {

    public typealias SIMDType = SIMD2<CGFloat.NativeType>

    @inlinable public init(_ simdRepresentation: SIMD2<CGFloat.NativeType>) {
        self.init(x: simdRepresentation[0], y: simdRepresentation[1])
    }

    @inlinable public func simdRepresentation() -> SIMD2<CGFloat.NativeType> {
        return SIMD2(CGFloat.NativeType(x), CGFloat.NativeType(y))
    }

    @inlinable public static func < (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x < rhs.x && lhs.y < rhs.y
    }

}

extension CGSize: SIMDRepresentable {

    public typealias SIMDType = SIMD2<CGFloat.NativeType>

    @inlinable public init(_ simdRepresentation: SIMD2<CGFloat.NativeType>) {
        self.init(width: simdRepresentation[0], height: simdRepresentation[1])
    }

    @inlinable public func simdRepresentation() -> SIMD2<CGFloat.NativeType> {
        return SIMD2(CGFloat.NativeType(width), CGFloat.NativeType(height))
    }

    @inlinable public static func < (lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width < rhs.width && lhs.height < rhs.height
    }

}

extension CGRect: SIMDRepresentable {

    public typealias SIMDType = SIMD4<CGFloat.NativeType>

    @inlinable public init(_ simdRepresentation: SIMD4<CGFloat.NativeType>) {
        self.init(x: simdRepresentation[0], y: simdRepresentation[1], width: simdRepresentation[2], height: simdRepresentation[3])
    }

    @inlinable public func simdRepresentation() -> SIMD4<Double> {
        return SIMD4(CGFloat.NativeType(origin.x), CGFloat.NativeType(origin.y), CGFloat.NativeType(size.width), CGFloat.NativeType(size.height))
    }

    @inlinable public static func < (lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.origin < rhs.origin && lhs.size < rhs.size
    }

}
