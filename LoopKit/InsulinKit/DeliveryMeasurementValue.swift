//
//  DeliveryMeasurementValue.swift
//  LoopKit
//
//  Created by Pete Schwamb on 9/14/18.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation
import CoreData

public protocol DeliveryMeasurementValue: TimelineValue {
    var startDate: Date { get }
    var unitVolume: Double { get }
}


struct StoredDeliveryMeasurementValue: DeliveryMeasurementValue {
    let startDate: Date
    let unitVolume: Double
    let objectIDURL: URL
}


extension DeliveryMeasurement: DeliveryMeasurementValue {
    var startDate: Date {
        return date
    }
    
    var unitVolume: Double {
        return volume
    }
    
    var storedDeliveryMeasurementValue: StoredDeliveryMeasurementValue {
        return StoredDeliveryMeasurementValue(startDate: startDate, unitVolume: unitVolume, objectIDURL: objectID.uriRepresentation())
    }
}
