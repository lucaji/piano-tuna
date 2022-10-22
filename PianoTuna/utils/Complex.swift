//from https://github.com/gongzhang/swift-complex-number/blob/master/ComplexNumber.playground/Sources/Complex.swift

//let c1 = 3 + 2 * 𝒊  // 3 + 2𝒊
//let c2 = 1 - 4 * 𝒊  // 1 - 4𝒊
//print(c1 * c2 - (2 - 4 * 𝒊)) // prints 9.0-6.0𝒊

import Foundation

public let 𝒊 = Complex(0, 1)

public struct Complex: Equatable, Hashable, CustomStringConvertible, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    
    /// The real part of the complex number.
    public var x: Double = 0
    
    /// The imaginary part of the complex number.
    public var y: Double = 0
    
    public init() {}
    
}

extension Complex {
    
    public var real: Double { get { return x } set { x = newValue } }
    public var imaginary: Double { get { return y } set { y = newValue } }
    
    public init (_ real: Double, _ imagine: Double) {
        self.x = real
        self.y = imagine
    }
    
    public init (real: Double) {
        self.init(real, 0)
    }
    
    public init(integerLiteral value: Int) {
        self.init(real: Double(value))
    }
    
    public init(floatLiteral value: Double) {
        self.init(real: value)
    }
    
    public init (imagine: Double) {
        self.init(0, imagine)
    }
    
    public subscript(index: Int) -> Double {
        switch index {
        case 0: return x
        case 1: return y
        default: fatalError("only 0 and 1 are allowed")
        }
    }
    
    public var radiusSquare: Double { return x * x + y * y }
    public var radius: Double { return sqrt(radiusSquare) }
    public var arg: Double { return atan2(y, x) }
    
    //public var hashValue: Int {
    //    return x.hashValue &+ y.hashValue
    //}
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x.hashValue)
        hasher.combine(y.hashValue)
    }
        
    public var description: String {
        if x != 0 {
            if y > 0 {
                return "\(x)+\(y)𝒊"
            } else if y < 0 {
                return "\(x)-\(-y)𝒊"
            } else {
                return "\(x)"
            }
        } else {
            if y == 0 {
                return "0"
            } else {
                return "\(y)𝒊"
            }
        }
    }
    
}

public extension Complex {
    static func ==(lhs: Complex, rhs: Complex) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    func conjugate() -> Complex {
        return Complex(x, -y)
    }
    
    
    func add(_ n: Complex) -> Complex {
        return Complex(x + n.x, y + n.y)
    }
    
    
    func subtract(_ n: Complex) -> Complex {
        return Complex(x - n.x, y - n.y)
    }
    
    
    func multiply(_ n: Double) -> Complex {
        return Complex(x * n, y * n)
    }
    
    
    func multiply(_ n: Complex) -> Complex {
        return Complex(x * n.x - y * n.y, x * n.y + y * n.x)
    }
    
    
    func divide(_ n: Complex) -> Complex {
        return self.multiply((n.conjugate().divide(n.radiusSquare)))
    }
    
    func divide(_ n: Double) -> Complex {
        return Complex(x / n, y / n)
    }
    
    
    func power(_ n: Double) -> Complex {
        return pow(radiusSquare, n / 2) * Complex(cos(n * arg), sin(n * arg))
    }
    
    
    func power(_ n: Int) -> Complex {
        switch n {
        case 0: return 1
        case 1: return self
        case -1: return Complex(real: 1).divide(self)
        case 2: return self.multiply(self)
        case -2: return Complex(real: 1).divide(self.multiply(self))
        default: return power(Double(n))
        }
    }
    
    func magnitude() -> Double {
        return sqrt(x*x + y*y)
    }
    
    mutating func conjugateInPlace() {
        y = -y
    }
    
    mutating func addInPlace(_ n: Complex) {
        x += n.x
        y += n.y
    }
    
    mutating func subtractInPlace(_ n: Complex) {
        x -= n.x
        y -= n.y
    }
    
    mutating func multiplyInPlace(_ n: Double) {
        x *= n
        y *= n
    }
    
    mutating func multiplyInPlace(_ n: Complex) {
        self = self.multiply(n)
    }
    
    mutating func divideInPlace(_ n: Complex) {
        self = self.divide(n)
    }
    
    mutating func divideInPlace(_ n: Double) {
        x /= n
        y /= n
    }
    
}

