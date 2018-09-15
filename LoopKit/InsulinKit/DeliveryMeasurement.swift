//
//  DeliveryMeasurement.swift
//  LoopKit
//
//  Created by Pete Schwamb on 9/14/18.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation
import CoreData


class DeliveryMeasurement: NSManagedObject {
    
    var volume: Double! {
        get {
            willAccessValue(forKey: "volume")
            defer { didAccessValue(forKey: "volume") }
            return primitiveVolume?.doubleValue
        }
        set {
            willChangeValue(forKey: "volume")
            defer { didChangeValue(forKey: "volume") }
            primitiveVolume = newValue != nil ? NSNumber(value: newValue) : nil
        }
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        createdAt = Date()
    }
}
