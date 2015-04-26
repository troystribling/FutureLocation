//
//  Logger.swift
//  FutureLocation
//
//  Created by Troy Stribling on 2/22/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//
import Foundation

public class Logger {
    public class func debug(message:String? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
#if DEBUG
        if let message = message {
            println("\(file):\(function):\(line): \(message)")
        } else {
            println("\(file):\(function):\(line)")
        }
#endif
    }
    
}
