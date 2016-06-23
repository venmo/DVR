import Foundation

private let CRLF = "\r\n"


private protocol FormDataType {
    var data: NSData { get }
}


internal struct BodyPart: FormDataType {
    private let headers: [String: String]
    let name: String
    let fileName: String?
    let mimeType: String?
    let rawData: NSData

    static func serialize(parameters: [String: String]) -> [BodyPart] {
        return parameters.flatMap {
            return BodyPart(name: $0, value: $1)
        }
    }

    init(name: String, fileName: String, mimeType: String, data: NSData) {
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
        self.rawData = data

        self.headers = [
            "Content-Disposition" : "form-data; name=\"\(name)\"; filename=\"\(fileName)\"",
            "Content-Type" : mimeType
        ]
    }

    init?(name: String, value: String) {
        guard let data = value.dataUsingEncoding(NSUTF8StringEncoding) else { return nil }
        self.rawData = data
        self.fileName = nil
        self.mimeType = nil
        self.name = name
        self.headers = ["Content-Disposition" : "form-data; name=\"\(name)\""]
    }

    var data: NSData {
        let headerString = headers.reduce("") {
            return $0 + "\($1.0): \($1.1)\(CRLF)"
            } + "\(CRLF)"

        let data = NSMutableData()
        guard let headerData = headerString.dataUsingEncoding(NSUTF8StringEncoding) else { return NSData() }
        data.appendData(headerData)
        data.appendData(self.rawData)
        return NSData(data: data)
    }
}


private enum FormDataKind {
    case BoundaryData(Boundary)
    case BodyPartData(BodyPart)
}


private enum Boundary: FormDataType {
    case Initial(String)
    case Encapsulated(String)
    case Final(String)

    var boundaryValue: String {
        switch self {
        case .Initial(let string): return "--\(string)\(CRLF)"
        case .Encapsulated(let string): return "\(CRLF)--\(string)\(CRLF)"
        case .Final(let string): return "\(CRLF)--\(string)--\(CRLF)"
        }
    }

    var data: NSData {
        return boundaryValue.dataUsingEncoding(NSUTF8StringEncoding)!
    }
}


internal struct FormData {
    private let formData: [FormDataType]
    let contentLength: UInt
    let data: NSData

    init(bodyParts: [BodyPart], boundaryValue: String) {
        var formData: [FormDataType] = [Boundary.Initial(boundaryValue)]

        bodyParts.forEach {
            formData.append($0)
            formData.append(Boundary.Encapsulated(boundaryValue))
        }

        formData.removeLast()
        formData.append(Boundary.Final(boundaryValue))

        self.formData = formData
        self.contentLength = bodyParts.reduce(0) { $0 + UInt($1.data.length) }

        let data = NSMutableData()
        for formDatum in self.formData {
            data.appendData(formDatum.data)
        }
        self.data = NSData(data: data)
    }
}
