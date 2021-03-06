import Foundation

open class MessagePackEncoder {

    open var userInfo: [CodingUserInfoKey : Any] = [:]

    public init() {}

    open func encode<T : Encodable>(_ value : T) throws -> Data {
        let encoder = _MsgPackEncdoer()
        var data : Data = Data()

        do {
            let topLevel = try encoder.box(value)

            if let dict = topLevel as? NSDictionary {
                let count = dict.count
                if count <= 15 {
                    let header = UInt8(0b10000000 | count)
                    data.append(header)
                } else if count <= (2 << 15) - 1 {
                    let header = [0xde, UInt8(count >> 8), UInt8(count & 0xff)]
                    data.append(contentsOf: header)
                } else if count <= (2 << 31) - 1 {
                    let header = [0xdf, UInt8(count >> 24), UInt8(count >> 16), UInt8(count >> 8), UInt8(count & 0xff)]
                    data.append(contentsOf: header)
                }
                for (key, value) in dict {
                    data.append(contentsOf: key as! [UInt8])
                    data.append(contentsOf: value as! [UInt8])
                }
            } else if let array = topLevel as? NSArray {
                let count = array.count
                if count <= 15 {
                    let header = UInt8(0b10010000 | count)
                    data.append(header)
                } else if count <= (2 << 15) - 1 {
                    let header = [0xdc, UInt8(count >> 8), UInt8(count & 0xff)]
                    data.append(contentsOf: header)
                } else if count <= (2 << 31) - 1 {
                    let header = [0xdd, UInt8(count >> 24), UInt8(count >> 16), UInt8(count >> 8), UInt8(count & 0xff)]
                    data.append(contentsOf: header)
                }
                for value in array {
                    data.append(contentsOf: value as! [UInt8])
                }
            }
        } catch let e {
            throw e
        }

        return data
    }
}

fileprivate class _MsgPackEncdoer : Encoder {
    fileprivate var storage : _MsgPackEncodingStorage
    public var codingPath: [CodingKey]

    public var userInfo: [CodingUserInfoKey : Any]

    init(codingPath: [CodingKey] = [], userInfo : [CodingUserInfoKey : Any] = [:]) {
        self.codingPath = codingPath
        self.storage = _MsgPackEncodingStorage()
        self.userInfo = userInfo
    }

    fileprivate var canEncodeNewValue: Bool {
        return self.storage.count == self.codingPath.count
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let topContainer : NSMutableDictionary
        if self.canEncodeNewValue {
            topContainer = self.storage.pushKeyedContainer()
        } else {
            guard let container = self.storage.containers.last as? NSMutableDictionary else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
            topContainer = container
        }

        let container = _MsgPackKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let topContainer : NSMutableArray
        if self.canEncodeNewValue {
            topContainer = self.storage.pushUnkeyedContainer()
        } else {
            guard let container = self.storage.containers.last as? NSMutableArray else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }
            topContainer = container
        }

        return _MsgPackUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

fileprivate struct _MsgPackEncodingStorage {
    private(set) var containers : [NSObject] = []

    init() {}

    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate mutating func pushKeyedContainer() -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()
        self.containers.append(dictionary)
        return dictionary
    }

    fileprivate mutating func pushUnkeyedContainer() -> NSMutableArray {
        let array = NSMutableArray()
        self.containers.append(array)
        return array
    }

    fileprivate mutating func push(container: NSObject) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() -> NSObject {
        precondition(self.containers.count > 0, "Empty container stack.")
        return self.containers.popLast()!
    }
}



fileprivate typealias KeyedContainer = (key: [UInt8], value : [UInt8])

fileprivate struct _MsgPackKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K
    private let encoder : _MsgPackEncdoer
    private let container : NSMutableDictionary
    private(set) public var codingPath: [CodingKey]


    fileprivate init(referencing encoder: _MsgPackEncdoer, codingPath: [CodingKey], wrapping container : NSMutableDictionary) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    mutating func encodeNil(forKey key: K) throws {
        container[encoder.box(key.stringValue)] = [0xc0]
    }

    mutating func encode(_ value: Bool, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: Int, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: Int8, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: Int16, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: Int32, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: Int64, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: UInt, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: UInt8, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: UInt16, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: UInt32, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: UInt64, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: Float, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: Double, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode(_ value: String, forKey key: K) throws {
        container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        self.codingPath.append(key)
        defer {
            self.codingPath.removeLast()
        }
        try container[encoder.box(key.stringValue)] = encoder.box(value)
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let dictionary = NSMutableDictionary()
        self.container[encoder.box(key.stringValue)] = dictionary

        self.codingPath.append(key)
        defer {
            self.codingPath.removeLast()
        }

        let container = _MsgPackKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)

        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        let array = NSMutableArray()
        self.container[encoder.box(key.stringValue)] = array

        self.codingPath.append(key)
        defer {
            self.codingPath.removeLast()
        }

        return _MsgPackUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }

    mutating func superEncoder() -> Encoder {
        return _MsgPackReferencingEncoder(referencing: self.encoder, at: _MsgPackKey.super, wrapping: self.container)
    }

    mutating func superEncoder(forKey key: K) -> Encoder {
        return _MsgPackReferencingEncoder(referencing: self.encoder, at: key, wrapping: self.container)
    }
}


fileprivate struct _MsgPackUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    private let encoder : _MsgPackEncdoer
    private let container : NSMutableArray
    private(set) public var codingPath: [CodingKey]

    public var count: Int {
        return self.container.count
    }

    fileprivate init(referencing encoder : _MsgPackEncdoer, codingPath : [CodingKey], wrapping container : NSMutableArray) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    

    mutating func encode(_ value: Int) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: Int8) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: Int16) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: Int32) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: Int64) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: UInt) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: UInt8) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: UInt16) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: UInt32) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: UInt64) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: Float) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: Double) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: String) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encode<T>(_ value: T) throws where T : Encodable {
       try self.container.add(self.encoder.box(value))
    }

    mutating func encode(_ value: Bool) throws {
       self.container.add(self.encoder.box(value))
    }

    mutating func encodeNil() throws {
        self.container.add([0xc0])
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        self.codingPath.append(_MsgPackKey(index: self.count))
        defer {
            self.codingPath.removeLast()
        }

        let dictionary =  NSMutableDictionary()
        let container = _MsgPackKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)

        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self.codingPath.append(_MsgPackKey(index: self.count))
        defer {
            self.codingPath.removeLast()
        }

        let array = NSMutableArray()

        return _MsgPackUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }

    mutating func superEncoder() -> Encoder {
        return _MsgPackReferencingEncoder(referencing: self.encoder, at: self.container.count, wrapping: self.container)
    }


}

extension _MsgPackEncdoer : SingleValueEncodingContainer {
    fileprivate func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
    }

    public func encodeNil() throws {
        assertCanEncodeNewValue()
        self.storage.push(container: [0xc0] as NSArray)
    }

    public func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value) as NSArray)
    }

    public func encode<T>(_ value: T) throws where T : Encodable {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value) as! NSArray)
    }
}

extension _MsgPackEncdoer {
    fileprivate func box(_ value : Bool) -> [UInt8] { return value ? [0xc3] : [0xc2] }
    fileprivate func box(_ value: UInt) -> [UInt8] { return MemoryLayout<UInt>.size == 4 ? box((UInt32(value))) : box((UInt64(value)))}
    fileprivate func box(_ value : UInt8) -> [UInt8] {
        switch value {
        case 0x00...0x7f:
            return [value]
        default:
            return [0xcc, value]
        }
    }
    fileprivate func box(_ value : UInt16) -> [UInt8] {
        if value <= UInt8.max {
            return self.box(UInt8(value))
        }
        return [0xcd, UInt8(value >> 8 & 0xff), UInt8(value & 0xff)]
    }
    fileprivate func box(_ value : UInt32) -> [UInt8] {
        if value <= UInt16.max {
            return self.box(UInt16(value))
        }
        return [0xce, UInt8(value >> 24 & 0xff), UInt8(value >> 16 & 0xff), UInt8(value >> 8 & 0xff), UInt8(value & 0xff)]
    }
    fileprivate func box(_ value : UInt64) -> [UInt8] {
        if value <= UInt32.max {
            return self.box(UInt32(value))
        }
        return [0xcf, UInt8(value >> 56 & 0xff), UInt8(value >> 48 & 0xff), UInt8(value >> 40 & 0xff), UInt8(value >> 32 & 0xff), UInt8(value >> 24 & 0xff), UInt8(value >> 16 & 0xff), UInt8(value >> 8 & 0xff), UInt8(value & 0xff)]
    }

    fileprivate func box(_ value: Int) -> [UInt8] {
        return MemoryLayout<Int>.size == 4 ? box((Int32(value))) : box((Int64(value)))
    }
    fileprivate func box(_ value : Int8) -> [UInt8] {
        let value = UInt8(value)
        switch value {
        case 0x00...0x7f:
            fallthrough
        case 0xe0...0xff:
             return [value]
        default:
            return [0xd0, value]
        }
    }
    fileprivate func box(_ value : Int16) -> [UInt8] {
        if Int8.min <= value && value <= Int8.max {
            return self.box(Int8(value))
        }
        return [0xd1, UInt8(value >> 8 & 0xff), UInt8(value & 0xff)]
    }
    fileprivate func box(_ value : Int32) -> [UInt8] {
        if Int16.min <= value && value <= Int16.max {
            return self.box(Int16(value))
        }
        return [0xd2, UInt8(value >> 24 & 0xff), UInt8(value >> 16 & 0xff), UInt8(value >> 8 & 0xff), UInt8(value & 0xff)]
    }
    fileprivate func box(_ value : Int64) -> [UInt8] {
        if Int32.min <= value && value <= Int32.max {
            return self.box(Int32(value))
        }
        return [0xd3, UInt8(value >> 56 & 0xff), UInt8(value >> 48 & 0xff), UInt8(value >> 40 & 0xff), UInt8(value >> 32 & 0xff), UInt8(value >> 24 & 0xff), UInt8(value >> 16 & 0xff), UInt8(value >> 8 & 0xff), UInt8(value & 0xff)]
    }

    fileprivate func box(_ value : Float) -> [UInt8] {
        let bitPattern = value.bitPattern

        return [0xca, UInt8(bitPattern >> 24 & 0xff), UInt8(bitPattern >> 16 & 0xff), UInt8(bitPattern >> 8 & 0xff), UInt8(bitPattern & 0xff)]
    }

    fileprivate func box(_ value : Double) -> [UInt8] {
        let bitPattern = value.bitPattern

        return [0xcb, UInt8(bitPattern >> 56 & 0xff), UInt8(bitPattern >> 48 & 0xff), UInt8(bitPattern >> 40 & 0xff), UInt8(bitPattern >> 32 & 0xff), UInt8(bitPattern >> 24 & 0xff), UInt8(bitPattern >> 16 & 0xff), UInt8(bitPattern >> 8 & 0xff), UInt8(bitPattern & 0xff)]
    }

    fileprivate func box(_ value: String) -> [UInt8] {
        var container : [UInt8] = []
        let count = value.utf8.count

        if count < 32 {
            container += [UInt8(0b10100000 | count)]
            let utf8 = value.utf8.map() { $0 }
            container += utf8
        } else if count < 256 {
            container += [0xd9, UInt8(count)]
            let utf8 = value.utf8.map() { $0 }
            container += utf8
        } else if count < 65536 {
            container += [0xda, UInt8(count >> 8 & 0xff), UInt8(count & 0xff)]
            let utf8 = value.utf8.map() { $0 }
            container += utf8
        } else if count < 4294967296 {
            container += [0xda, UInt8(count >> 24 & 0xff), UInt8(count >> 16 & 0xff), UInt8(count >> 8 & 0xff), UInt8(count & 0xff)]
            let utf8 = value.utf8.map() { $0 }
            container += utf8
        }

        return container
    }

    fileprivate func box(_ value : Data) throws -> [UInt8] {
        var data = Data()
        var count = value.count
        switch count {
        case (2 << 7) - 1:
            data += [0xc4, UInt8(count)]
        case (2 << 15) - 1:
            data += [0xc5, UInt8(count >> 8), UInt8(count & 0xff)]
        case (2 << 31) - 1:
            data += [0xc6, UInt8(count >> 24), UInt8(count >> 16), UInt8(count >> 8), UInt8(count & 0xff)]
        default:
            fatalError()
        }

        data += value
        count = data.count
        var array = [UInt8](repeating: 0, count: count)
        data.copyBytes(to: &array, count: count)

        return array
    }

    fileprivate func box(_ value : [UInt8]) throws -> [UInt8] {
        var data : [UInt8] = []
        let count = value.count
        switch count {
        case (2 << 7) - 1:
            data += [0xc4, UInt8(count)]
        case (2 << 15) - 1:
            data += [0xc5, UInt8(count >> 8), UInt8(count & 0xff)]
        case (2 << 31) - 1:
            data += [0xc6, UInt8(count >> 24), UInt8(count >> 16), UInt8(count >> 8), UInt8(count & 0xff)]
        default:
            fatalError()
        }

        data += value

        return data
    }

    fileprivate func box(_ value : Date) throws -> [UInt8] {
        let seconds = UInt32(value.timeIntervalSinceNow)

        return [0xd6, 0xff] + self.box(seconds)
    }

    fileprivate func box<T : Encodable>(_ value : T) throws -> NSObject? {
        let depth = self.storage.count
        try value.encode(to: self)
        guard self.storage.count > depth else {
            return nil
        }
        return self.storage.popContainer()
    }
}

fileprivate class _MsgPackReferencingEncoder : _MsgPackEncdoer {
    private enum Reference {
        case array(NSMutableArray, Int)
        case dictionary(NSMutableDictionary, String)
    }

    fileprivate let encoder : _MsgPackEncdoer
    private let reference : Reference

    fileprivate init(referencing encoder : _MsgPackEncdoer, at index : Int, wrapping array : NSMutableArray) {
        self.encoder = encoder
        self.reference = .array(array, index)
        super.init(codingPath: encoder.codingPath)

        self.codingPath.append(_MsgPackKey(index: index))
    }

    fileprivate init(referencing encoder : _MsgPackEncdoer, at key : CodingKey, wrapping dictionary : NSMutableDictionary) {
        self.encoder = encoder
        self.reference = .dictionary(dictionary, key.stringValue)
        super.init(codingPath: encoder.codingPath)

        self.codingPath.append(key)
    }

    fileprivate override var canEncodeNewValue: Bool {
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }

    deinit {
        let value: Any
        switch self.storage.count {
        case 0: value = NSDictionary()
        case 1: value = self.storage.popContainer()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }

        switch self.reference {
        case .array(let array, let index):
            array.insert(value, at: index)

        case .dictionary(let dictionary, let key):
            dictionary[NSString(string: key)] = value
        }
    }
}

fileprivate struct _MsgPackKey : CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    public init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    fileprivate static let `super` = _MsgPackKey(stringValue: "super")!
}

