//
//  String.swift
//  ExSwift
//
//  Created by pNre on 03/06/14.
//  Copyright (c) 2014 pNre. All rights reserved.
//

import Foundation

public extension String {

    /**
        String length
    */
    var length: Int { return self.characters.count }
    
    /**
        self.capitalizedString shorthand
    */
    var capitalized: String { return capitalizedString }
    
    /**
        Returns the substring in the given range
        
        :param: range
        :returns: Substring in range
    */
    subscript (range: Range<Int>) -> String? {
        if range.startIndex < 0 || range.endIndex > self.length {
            return nil
        }

        let range = Range(start: advance(startIndex, range.startIndex), end: advance(startIndex, range.endIndex))

        return self[range]
    }

    /**
        Equivalent to at. Takes a list of indexes and returns an Array
        containing the elements at the given indexes in self.
        
        :param: firstIndex
        :param: secondIndex
        :param: restOfIndexes
        :returns: Charaters at the specified indexes (converted to String)
    */
    subscript (firstIndex: Int, secondIndex: Int, restOfIndexes: Int...) -> [String] {
        return at([firstIndex, secondIndex] + restOfIndexes)
    }

    /**
        Gets the character at the specified index as String. 
        If index is negative it is assumed to be relative to the end of the String.
        
        :param: index Position of the character to get
        :returns: Character as String or nil if the index is out of bounds
    */
    subscript (index: Int) -> String? {
        if let char = Array(arrayLiteral:self).get(index) {
            return String(char)
        }

        return nil
    }

    /**
        Takes a list of indexes and returns an Array containing the elements at the given indexes in self.
    
        :param: indexes Positions of the elements to get
        :returns: Array of characters (as String)
    */
    func at (indexes: Int...) -> [String] {
        return indexes.map { self[$0]! }
    }

    /**
        Takes a list of indexes and returns an Array containing the elements at the given indexes in self.
    
        :param: indexes Positions of the elements to get
        :returns: Array of characters (as String)
    */
    func at (indexes: [Int]) -> [String] {
        return indexes.map { self[$0]! }
    }

    /**
        Inserts a substring at the given index in self.
    
        :param: index Where the new string is inserted
        :param: string String to insert
        :returns: String formed from self inserting string at index
    */
    func insert (index: Int, _ string: String) -> String {
        //  Edge cases, prepend and append
        if index > length {
            return self + string
        } else if index < 0 {
            return string + self
        }
        
        return self[0..<index]! + string + self[index..<length]!
    }

    /**
        Strips whitespaces from the beginning of self.
    
        :returns: Stripped string
    */
    func ltrimmed () -> String {
        if let range = rangeOfCharacterFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet().invertedSet) {
            return self[range.startIndex..<endIndex]
        }
        
        return self
    }

    /**
        Strips whitespaces from the end of self.
    
        :returns: Stripped string
    */
    func rtrimmed () -> String {
        if let range = rangeOfCharacterFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet().invertedSet, options: NSStringCompareOptions.BackwardsSearch) {
            return self[startIndex..<range.endIndex]
        }
        
        return self
    }

    /**
        Strips whitespaces from both the beginning and the end of self.
    
        :returns: Stripped string
    */
    func trimmed () -> String {
        return ltrimmed().rtrimmed()
    }

    /**
        Costructs a string using random chars from a given set.
    
        :param: length String length. If < 1, it's randomly selected in the range 0..16
        :param: charset Chars to use in the random string
        :returns: Random string
    */
    static func random (var length len: Int = 0, charset: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {

        if len < 1 {
            len = Int.random(max: 16)
        }

        var result = String()
        let max = charset.length - 1

        len.times {
            result += charset[Int.random(0, max: max)]!
        }

        return result

    }

}

/**
    Repeats the string first n times
*/
public func * (first: String, n: Int) -> String {
    var result = String()

    n.times {
        result += first
    }

    return result
}
