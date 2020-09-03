//
//  File.swift
//  
//
//  Created by Adam Bell on 8/1/20.
//

import CoreGraphics
import Foundation
import simd

// MARK: - Supported Types

public protocol SupportedSIMDType: SIMD, EquatableEnough {

}

public typealias SupportedScalar = FloatingPoint & DoubleIntializable & ExpressibleByFloatLiteral & EquatableEnough

extension SIMD2: SupportedSIMDType where Scalar: SupportedScalar {}
extension SIMD3: SupportedSIMDType where Scalar: SupportedScalar {}
extension SIMD4: SupportedSIMDType where Scalar: SupportedScalar {}
extension SIMD8: SupportedSIMDType where Scalar: SupportedScalar {}
extension SIMD16: SupportedSIMDType where Scalar: SupportedScalar {}
extension SIMD32: SupportedSIMDType where Scalar: SupportedScalar {}
extension SIMD64: SupportedSIMDType where Scalar: SupportedScalar {}

// MARK: - SIMDRepresentable

public protocol SIMDRepresentable: Comparable {

    associatedtype SIMDType: SupportedSIMDType where SIMDType.Scalar: SupportedScalar

    init(_ simdRepresentation: SIMDType)

    func simdRepresentation() -> SIMDType

    static var zero: Self { get }

}

// These single floating point conformances technically are wasteful, but it's still a single register it gets packed in, so it's "fine".
// Actually I think the compiler is smart and optimizes these to just ignore SIMD anyways. 

extension Float: SIMDRepresentable {

    public typealias SIMDType = SIMD2<Float>

    public init(_ simdRepresentation: SIMD2<Float>) {
        self = simdRepresentation[0]
    }

    public func simdRepresentation() -> SIMD2<Float> {
        return SIMD2(self, 0.0)
    }

}

extension Double: SIMDRepresentable {

    public typealias SIMDType = SIMD2<Double>

    public init(_ simdRepresentation: SIMD2<Double>) {
        self = simdRepresentation[0]
    }

    public func simdRepresentation() -> SIMD2<Double> {
        return SIMD2(self, 0.0)
    }

}

extension SIMD2: SIMDRepresentable where Self.Scalar: SupportedScalar {

    public typealias SIMDType = Self

    public init(_ simdRepresentation: Self) {
        self = simdRepresentation
    }

    public func simdRepresentation() -> SIMD2<Scalar> {
        return self
    }

}

extension SIMD3: SIMDRepresentable where Self.Scalar: SupportedScalar {

    public typealias SIMDType = Self

    public init(_ simdRepresentation: Self) {
        self = simdRepresentation
    }

    public func simdRepresentation() -> Self {
        return self
    }

}

extension SIMD4: SIMDRepresentable where Self.Scalar: SupportedScalar {

    public typealias SIMDType = Self

    public init(_ simdRepresentation: Self) {
        self = simdRepresentation
    }

    public func simdRepresentation() -> SIMD4<Scalar> {
        return self
    }

}

extension SIMD8: SIMDRepresentable where Self.Scalar: SupportedScalar {

    public typealias SIMDType = Self

    public init(_ simdRepresentation: Self) {
        self = simdRepresentation
    }

    public func simdRepresentation() -> SIMD8<Scalar> {
        return self
    }

}

extension SIMD16: SIMDRepresentable where Self.Scalar: SupportedScalar {

    public typealias SIMDType = Self

    public init(_ simdRepresentation: Self) {
        self = simdRepresentation
    }

    public func simdRepresentation() -> SIMD16<Scalar> {
        return self
    }

}

extension SIMD32: SIMDRepresentable where Self.Scalar: SupportedScalar {

    public typealias SIMDType = Self

    public init(_ simdRepresentation: Self) {
        self = simdRepresentation
    }

    public func simdRepresentation() -> SIMD32<Scalar> {
        return self
    }

}

extension SIMD64: SIMDRepresentable where Self.Scalar: SupportedScalar {

    public typealias SIMDType = Self

    public init(_ simdRepresentation: Self) {
        self = simdRepresentation
    }

    public func simdRepresentation() -> SIMD64<Scalar> {
        return self
    }

}

// MARK: - CoreGraphics Extensions

extension CGFloat: SIMDRepresentable {

    public typealias SIMDType = SIMD2<Double>

    public init(_ simdRepresentation: SIMD2<Double>) {
        self = CGFloat(simdRepresentation[0])
    }

    public func simdRepresentation() -> SIMD2<Double> {
        return SIMD2(Double(self), 0.0)
    }

}

extension CGPoint: SIMDRepresentable {

    public typealias SIMDType = SIMD2<Double>

    public init(_ simdRepresentation: SIMD2<Double>) {
        self.init(x: simdRepresentation[0], y: simdRepresentation[1])
    }

    public func simdRepresentation() -> SIMD2<Double> {
        return SIMD2(Double(x), Double(y))
    }

    public static func < (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x < rhs.x && lhs.y < rhs.y
    }

}

extension CGSize: SIMDRepresentable {

    public typealias SIMDType = SIMD2<Double>

    public init(_ simdRepresentation: SIMD2<Double>) {
        self.init(width: simdRepresentation[0], height: simdRepresentation[1])
    }

    public func simdRepresentation() -> SIMD2<Double> {
        return SIMD2(Double(width), Double(height))
    }

    public static func < (lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width < rhs.width && lhs.height < rhs.height
    }

}

extension CGRect: SIMDRepresentable {

    public typealias SIMDType = SIMD4<Double>

    public init(_ simdRepresentation: SIMD4<Double>) {
        self.init(x: simdRepresentation[0], y: simdRepresentation[1], width: simdRepresentation[2], height: simdRepresentation[3])
    }

    public func simdRepresentation() -> SIMD4<Double> {
        return SIMD4(Double(origin.x), Double(origin.y), Double(size.width), Double(size.height))
    }

    public static func < (lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.origin < rhs.origin && lhs.size < rhs.size
    }

}

