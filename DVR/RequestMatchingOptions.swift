//
//  RequestMatching.swift
//  DVR
//
//  Created by Peter Nicholls on 6/07/2016.
//  Copyright © 2016 Venmo. All rights reserved.
//

public struct RequestMatching : OptionSetType {
    
    // MARK: - Properties
    
    private enum Method : Int {
        case URL = 1, Path = 2, HTTPMethod = 4, HTTPBody = 8
    }
    
    public let rawValue : Int
    
    public static let URL = RequestMatching(Method.URL)
    public static let Path = RequestMatching(Method.Path)
    public static let HTTPMethod = RequestMatching(Method.HTTPMethod)
    public static let HTTPBody = RequestMatching(Method.HTTPBody)
    
    // MARK: - Initializers
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    private init(_ direction: Method) {
        self.rawValue = direction.rawValue
    }
}