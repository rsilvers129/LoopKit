//
//  DeliveryMeasurement+CoreDataProperties.swift
//  LoopKit
//
//  Created by Pete Schwamb on 9/14/18.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation
import CoreData


extension DeliveryMeasurement {
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<DeliveryMeasurement> {
        return NSFetchRequest<DeliveryMeasurement>(entityName: "DeliveryMeasurement")
    }
    
    @NSManaged var createdAt: Date!
    @NSManaged var date: Date!
    @NSManaged var primitiveVolume: NSNumber?
    @NSManaged var raw: Data?
    
}
