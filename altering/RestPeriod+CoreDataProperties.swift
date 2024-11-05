//
//  RestPeriod+CoreDataProperties.swift
//  Altered
//
//  Created by Andrew, Elias on 10/22/24.
//
//

import Foundation
import CoreData


extension RestPeriod {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RestPeriod> {
        return NSFetchRequest<RestPeriod>(entityName: "RestPeriod")
    }

    @NSManaged public var explanation: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?

}

extension RestPeriod : Identifiable {

}
