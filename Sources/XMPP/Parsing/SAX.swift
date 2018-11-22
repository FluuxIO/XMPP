//
//  SAX.swift
//  PerfectXML
//
//  Created by Kyle Jessup on 2018-03-13.
//

import libxml2

public struct SAXError: Error {
    public let description: String
    public init(_ d: String) {
        description = d
    }
}

public protocol SAXDelegate: AnyObject {
    func startDocument()
    func endDocument()
    func processingInstruction(target: String, data: String)
    func entityDecl(name: String, type: Int, pubicId: String, systemId: String, content: String)
    func unparsedEntityDecl(name: String, pubicId: String, systemId: String, notationName: String)
    func notationDecl(name: String, pubicId: String, systemId: String)
    func attributeDecl(elem: String, fullName: String, type: Int, def: Int, defaultValue: String?, tree: xmlEnumerationPtr?)
    func elementDecl(name: String, type: Int, content: xmlElementContentPtr?)
    func reference(name: String)
    func comment(_ c: String)
    func startElementNs(localName: String,
                        prefix: String?,
                        uri: String?,
                        namespaces: [SAXDelegateNamespace],
                        attributes: [SAXDelegateAttribute])
    func endElementNs(localName: String,
                      prefix: String?,
                      uri: String?)
    func characters(_ c: String)
    func ignorableWhitespace(_ c: String)
    func cdataBlock(_ c: String)
}

public struct SAXDelegateNamespace {
    public let prefix: String?
    public let uri: String
}

public struct SAXDelegateAttribute {
    public let localName: String
    public let prefix: String?
    public let nsUri: String?
    public let value: String
}

/// Default implimentations do nothing
public extension SAXDelegate {
    func startDocument() {}
    func endDocument() {}
    func processingInstruction(target: String, data: String) {}
    func entityDecl(name: String, type: Int, pubicId: String, systemId: String, content: String) {}
    func unparsedEntityDecl(name: String, pubicId: String, systemId: String, notationName: String) {}
    func notationDecl(name: String, pubicId: String, systemId: String) {}
    func attributeDecl(elem: String, fullName: String, type: Int, def: Int, defaultValue: String?, tree: xmlEnumerationPtr?) {}
    func elementDecl(name: String, type: Int, content: xmlElementContentPtr?) {}
    func reference(name: String) {}
    func comment(_ c: String) {}
    func startElementNs(localName: String,
                        prefix: String?,
                        uri: String?,
                        namespaces: [SAXDelegateNamespace],
                        attributes: [SAXDelegateAttribute]) {}
    func endElementNs(localName: String,
                      prefix: String?,
                      uri: String?) {}
    func characters(_ c: String) {}
    func ignorableWhitespace(_ c: String) {}
    func cdataBlock(_ c: String) {}
}

public class SAXParser {
    var handler = xmlSAXHandler()
    weak var delegate: SAXDelegate?
    var parserCtxt: xmlParserCtxtPtr?
    public init(delegate d: SAXDelegate) {
        delegate = d
        
    }
    deinit {
        if let c = parserCtxt {
            xmlFreeParserCtxt(c)
        }
    }
    private func getCtxt() throws -> xmlParserCtxtPtr {
        if let c = parserCtxt {
            return c
        }
        try setHandlerFuncs()
        guard let c = xmlCreatePushParserCtxt(&handler,
                                              asContext(self), nil, 0, nil) else {
                                                throw SAXError("Unable to allocate XML parser.")
        }
        parserCtxt = c
        return c
    }
    public func pushData(_ d: [UInt8]) throws {
        let ctx = try getCtxt()
        let code = UnsafePointer(d).withMemoryRebound(to: Int8.self, capacity: d.count) {
            return xmlParseChunk(ctx, $0, Int32(d.count), 0)
        }
        guard 0 == code else {
            throw SAXError("Error parsing chunk: \(code).")
        }
    }
    public func finish() throws {
        xmlParseChunk(try getCtxt(), nil, 0, 0)
    }
    
    private static func ptr2AryNamespaces(_ ptr: UnsafeMutablePointer<UnsafePointer<xmlChar>?>?, count: Int) -> [SAXDelegateNamespace] {
        guard let ptr = ptr else {
            return []
        }
        var ret: [SAXDelegateNamespace] = []
        for i in stride(from: 0, to: count*2, by: 2) {
            let ptr1 = ptr[i]
            let ptr2 = ptr[i+1]
            ret.append(.init(prefix: String(ptr1), uri: String(ptr2, default: "")))
        }
        return ret
    }
    
    private static func ptr2AryAttributes(_ ptr: UnsafeMutablePointer<UnsafePointer<xmlChar>?>?, count: Int) -> [SAXDelegateAttribute] {
        guard let ptr = ptr else {
            return []
        }
        var ret: [SAXDelegateAttribute] = []
        for i in stride(from: 0, to: count*5, by: 5) {
            let namePtr = ptr[i]
            let prefixPtr = ptr[i+1]
            let nsUri = ptr[i+2]
            let value: String
            if let valueStartPtr = ptr[i+3],
                let valueEndPtr = ptr[i+4] {
                if valueEndPtr.pointee == 0 {
                    value = String(valueStartPtr, default: "")
                } else {
                    let valueLen = valueEndPtr - valueStartPtr
                    value = String(valueStartPtr, count: valueLen, default: "")
                }
            } else {
                value = ""
            }
            ret.append(.init(
                localName: String(namePtr, default: ""),
                prefix: String(prefixPtr),
                nsUri: String(nsUri),
                value: value))
        }
        return ret
    }
    
    private func setHandlerFuncs() throws {
        handler.startElement = nil
        handler.endElement = nil
        handler.startElementNs = {
            a, b, c, d, e, f, g, h, i in
            fromContext(SAXParser.self, a)?.delegate?.startElementNs(localName: String(b, default: ""),
                                                                     prefix: String(c),
                                                                     uri: String(d),
                                                                     namespaces: SAXParser.ptr2AryNamespaces(f, count: Int(e)),
                                                                     attributes: SAXParser.ptr2AryAttributes(i, count: Int(g)))
        }
        handler.endElementNs = {
            fromContext(SAXParser.self, $0)?.delegate?.endElementNs(
                localName: String($1) ?? "no name",
                prefix: String($2),
                uri: String($3))
        }
        handler.serror = nil
        handler.internalSubset = { _, _, _, _ in }
        handler.externalSubset = { _, _, _, _ in }
        handler.isStandalone = { _ in return 1 }
        handler.hasInternalSubset = { _ in return 0 }
        handler.hasExternalSubset = { _ in return 0 }
        handler.resolveEntity = { _, _, _ in return nil }
        handler.getEntity = { xmlGetPredefinedEntity($1) }
        handler.getParameterEntity = { _, _ in return nil }
        handler.entityDecl = {
            fromContext(SAXParser.self, $0)?.delegate?.entityDecl(name: String($1, default: ""),
                                                                  type: Int($2),
                                                                  pubicId: String($3, default: ""),
                                                                  systemId: String($4, default: ""),
                                                                  content: String($5, default: ""))
        }
        handler.attributeDecl = {
            fromContext(SAXParser.self, $0)?.delegate?.attributeDecl(elem: String($1, default: ""),
                                                                     fullName: String($2, default: ""),
                                                                     type: Int($3),
                                                                     def: Int($4),
                                                                     defaultValue: String($5),
                                                                     tree: $6)
        }
        handler.elementDecl = {
            fromContext(SAXParser.self, $0)?.delegate?.elementDecl(name: String($1, default: ""), type: Int($2), content: $3)
        }
        handler.notationDecl = {
            fromContext(SAXParser.self, $0)?.delegate?.notationDecl(name: String($1, default: ""), pubicId: String($2, default: ""), systemId: String($3, default: ""))
        }
        handler.unparsedEntityDecl = {
            fromContext(SAXParser.self, $0)?.delegate?.unparsedEntityDecl(name: String($1, default: ""),
                                                                          pubicId: String($2, default: ""),
                                                                          systemId: String($3, default: ""),
                                                                          notationName: String($4, default: ""))
        }
        handler.setDocumentLocator = { _, _ in }
        handler.startDocument = { fromContext(SAXParser.self, $0)?.delegate?.startDocument() }
        handler.endDocument = {    fromContext(SAXParser.self, $0)?.delegate?.endDocument() }
        handler.reference = { fromContext(SAXParser.self, $0)?.delegate?.reference(name: String($1, default: "")) }
        handler.characters = { fromContext(SAXParser.self, $0)?.delegate?.characters(String($1, count: Int($2), default: "")) }
        handler.cdataBlock = { fromContext(SAXParser.self, $0)?.delegate?.cdataBlock(String($1, count: Int($2), default: "")) }
        handler.ignorableWhitespace = { fromContext(SAXParser.self, $0)?.delegate?.ignorableWhitespace(String($1, default: "")) ; _ = $2 };
        handler.processingInstruction = { fromContext(SAXParser.self, $0)?.delegate?.processingInstruction(target: String($1, default: ""), data: String($2, default: "")) }
        handler.comment = { fromContext(SAXParser.self, $0)?.delegate?.comment(String($1, default: "")) }
        handler.warning = nil//xmlParserWarning;
        handler.error = nil//xmlParserError;
        handler.fatalError = nil//xmlParserError;
        
        handler.initialized = 0xDEEDBEAF
    }
}


