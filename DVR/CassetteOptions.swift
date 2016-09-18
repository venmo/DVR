//
//  CassetteOptions.swift
//  DVR
//
//  Created by Peter Nicholls on 6/07/2016.
//  Copyright © 2016 Venmo. All rights reserved.
//

public struct CassetteOptions {
    
    // MARK: - Properties
    
    public let requestMatching: RequestMatching
    
    // MARK: - Initializers
    
    public init(requestMatching: RequestMatching = [.URL, .Path, .HTTPMethod, .HTTPBody]) {
        self.requestMatching = requestMatching
    }
}
