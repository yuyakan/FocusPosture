//  DoubleArrayTransformer.swift
//  Balance
//
//  Created by KoichiroUeki on 2025/08/30.
//

import Foundation
import SwiftData

/// A value transformer that converts an array of Double to/from Data for storage in SwiftData.
@objc(DoubleArrayTransformer)
final class DoubleArrayTransformer: ValueTransformer {
    
    /// Register this transformer with the given name so SwiftData can use it.
    /// - Parameter name: The name to register the transformer under.
    static func register(_ name: String) {
        let transformer = DoubleArrayTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: NSValueTransformerName(name))
    }
    
    /// Transform an array of Double into Data
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    /// This transformer allows reverse transformations
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    /// Convert [Double] to Data
    override func transformedValue(_ value: Any?) -> Any? {
        guard let doubleArray = value as? [Double] else { return nil }
        
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: doubleArray, requiringSecureCoding: true)
        } catch {
            print("Error encoding [Double]: \(error)")
            return nil
        }
    }
    
    /// Convert Data back to [Double]
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSNumber.self], from: data) as? [Double]
        } catch {
            print("Error decoding [Double]: \(error)")
            return nil
        }
    }
}
