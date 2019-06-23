//
//  XMLStream.swift
//  PerfectXML
//
//  Created by Kyle Jessup on 2018-03-12.
//

import Foundation
import libxml2

public protocol XMLStreamDataProvider {
    mutating func getData(maxCount: Int) throws -> Data?
    mutating func close()
}

public struct XMLStreamError: Error {
    public let description: String
    public init(_ d: String) {
        description = d
    }
}

extension String {
    init?(_ p: UnsafePointer<xmlChar>?) {
        guard let n = p else {
            return nil
        }
        guard let s = n.withMemoryRebound(to: Int8.self, capacity: 0, { String(validatingUTF8: $0) }) else {
            return nil
        }
        self = s
    }
    init(_ p: UnsafePointer<xmlChar>?, default: String) {
        guard let n = p else {
            self = `default`
            return
        }
        guard let s = n.withMemoryRebound(to: Int8.self, capacity: 0, { String(validatingUTF8: $0) }) else {
            self = `default`
            return
        }
        self = s
    }
    init(_ p: UnsafePointer<xmlChar>?, count: Int, default: String) {
        guard let n = p else {
            self = `default`
            return
        }
        let a = (0..<count).map { Int8(n[$0]) } + [0]
        guard let s = String(validatingUTF8: a) else {
            self = `default`
            return
        }
        self = s
    }
}


func asContext(_ a: AnyObject) -> UnsafeMutableRawPointer {
    return Unmanaged.passUnretained(a).toOpaque()
}

func fromContext<A: AnyObject>(_ type: A.Type, _ context: UnsafeMutableRawPointer) -> A {
    return Unmanaged<A>.fromOpaque(context).takeUnretainedValue()
}

func fromContext<A: AnyObject>(_ type: A.Type, _ context: UnsafeMutableRawPointer?) -> A? {
    guard let context = context else {
        return nil
    }
    return Unmanaged<A>.fromOpaque(context).takeUnretainedValue()
}

public class XMLStream {
    public enum NodeType: Int {
        case none = 0, element, attribute, text, cdata, entityReference,
        entity, processingInstruction, comment, document, documentType, fragment,
        notation, whitespace, significantWhitespace, endElement, endEntity, xmlDeclaration
    }
    public struct NodeDescriptor {
        let readerPtr: xmlTextReaderPtr
        init(_ r: xmlTextReaderPtr) {
            readerPtr = r
        }
    }
    
    var dataProvider: XMLStreamDataProvider
    var readerPtr: xmlTextReaderPtr?
    
    public init(provider: XMLStreamDataProvider) {
        dataProvider = provider
    }
    deinit {
        if let r = readerPtr {
            xmlFreeTextReader(r)
        }
    }
    
    private func getReaderPtr() throws -> xmlTextReaderPtr {
        if let r = readerPtr {
            return r
        }
        let readCallback: xmlInputReadCallback = {
            context, buffer, bufferSize -> Int32 in
            guard let context = context, let buffer = buffer else {
                return -1
            }
            let me = fromContext(XMLStream.self, context)
            do {
                guard let data = try me.dataProvider.getData(maxCount: Int(bufferSize)) else {
                    return 0
                }
                _ = data.withUnsafeBytes {
                    memcpy(buffer, $0.bindMemory(to: UInt8.self).baseAddress!, data.count)
                }
                return Int32(data.count)
            } catch {
                return -1
            }
        }
        let closeCallback: xmlInputCloseCallback = {
            context in
            guard let context = context else {
                return -1
            }
            let me = fromContext(XMLStream.self, context)
            me.dataProvider.close()
            return 0
        }
        guard let reader = xmlReaderForIO(readCallback,
                                          closeCallback,
                                          asContext(self),
                                          "/",
                                          "utf8",
                                          Int32(XML_PARSE_NONET.rawValue | XML_PARSE_NOCDATA.rawValue | XML_PARSER_SUBST_ENTITIES.rawValue)) else {
                                            throw XMLStreamError("Unable to allocate XML reader.")
        }
        readerPtr = reader
        return reader
    }
    
    public func next() throws -> NodeDescriptor? {
        let reader = try getReaderPtr()
        let readRes = xmlTextReaderRead(reader)
        switch readRes {
        case 0:
            return nil
        case -1:
            throw XMLStreamError("Error calling xmlTextReaderRead.")
        default:
            return NodeDescriptor(reader)
        }
    }
    
    public func nextSibling() throws -> NodeDescriptor? {
        let reader = try getReaderPtr()
        let readRes = xmlTextReaderNext(reader)
        switch readRes {
        case 0:
            return nil
        case -1:
            throw XMLStreamError("Error calling xmlTextReaderNext.")
        default:
            return NodeDescriptor(reader)
        }
    }
    
    public func namespaceURI(prefix: String) -> String? {
        return String(xmlTextReaderLookupNamespace(readerPtr, prefix))
    }
}

public extension XMLStream.NodeDescriptor {
    var type: XMLStream.NodeType? {
        return XMLStream.NodeType(rawValue: Int(xmlTextReaderNodeType(readerPtr)))
    }
    var localName: String? {
        return String(xmlTextReaderConstLocalName(readerPtr))
    }
    var name: String? {
        return String(xmlTextReaderConstName(readerPtr))
    }
    var namespaceURI: String? {
        return String(xmlTextReaderConstNamespaceUri(readerPtr))
    }
    var prefix: String? {
        return String(xmlTextReaderConstPrefix(readerPtr))
    }
    var value: String? {
        return String(xmlTextReaderConstValue(readerPtr))
    }
    var content: String? {
        guard let n = xmlTextReaderReadString(readerPtr) else {
            return nil
        }
        defer {
            xmlFree(n)
        }
        return n.withMemoryRebound(to: Int8.self, capacity: 0) {
            return String(validatingUTF8: $0)
        }
    }
    var isEmpty: Bool {
        return xmlTextReaderIsEmptyElement(readerPtr) == 1
    }
    var attributeCount: Int {
        return Int(xmlTextReaderAttributeCount(readerPtr))
    }
    var depth: Int {
        return Int(xmlTextReaderDepth(readerPtr))
    }
}

public extension XMLStream.NodeDescriptor {
    func getAttribute(_ name: String, namespaceURI: String? = nil) -> String? {
        if let ns = namespaceURI {
            return String(xmlTextReaderGetAttributeNs(readerPtr, name, ns))
        }
        return String(xmlTextReaderGetAttribute(readerPtr, name))
    }
}
