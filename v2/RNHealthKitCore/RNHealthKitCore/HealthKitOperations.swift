import Foundation
import HealthKit


public struct QuantityQuery {
    let startDate: Date?
    let endDate: Date?
    let isUserEntered: Bool?
    let limit: Int
    let unit: HKUnit
    var predicate: NSPredicate {
        var predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])
        if let isUserEntered = isUserEntered {
            let value = isUserEntered ? "YES": "NO"
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[.init(format: "metadata.%K == \(value)", HKMetadataKeyWasUserEntered), predicate])
        }
        return predicate
    }
    
    public init(startDate: Date?, endDate: Date?, isUserEntered: Bool? = nil, limit: Int = HKObjectQueryNoLimit, unit: HKUnit) {
        self.startDate = startDate
        self.endDate = endDate
        self.isUserEntered = isUserEntered
        self.limit = limit
        self.unit = unit
    }
}

public struct AggregationdQuantityQuery {
    let startDate: Date
    let endDate: Date
    let interval: DateComponents
    let anchorDate: Date
    let unit: HKUnit
    let aggregationOption: AggregationOptions
    let isUserEntered: Bool?

    var predicate: NSPredicate {
        var predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])
        if let isUserEntered = isUserEntered {
            let value = isUserEntered ? "YES": "NO"
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[.init(format: "metadata.%K == \(value)", HKMetadataKeyWasUserEntered), predicate])
        }
        return predicate
    }
    
    public init(
        startDate: Date,
        endDate: Date = Date(),
        interval: DateComponents = .init(day: 1),
        anchorDate: Date = Calendar(identifier: .gregorian).startOfDay(for: Date()),
        unit: HKUnit,
        aggregationOption: AggregationOptions,
        isUserEntered: Bool? = nil
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.interval = interval
        self.anchorDate = anchorDate
        self.unit = unit
        self.aggregationOption = aggregationOption
        self.isUserEntered = isUserEntered
    }
}

public enum AggregationOptions: String {
    case discreteAverage
    case discreteMin
    case discreteMax
    case cumulativeSum
    case mostRecent
    case duration
    
    var enumeration: (HKStatistics) -> (HKQuantity?) {
        switch self {
        case .discreteAverage:
            return { statistics in return statistics.averageQuantity()}
        case .discreteMin:
            return { statistics in return statistics.minimumQuantity()}
        case .discreteMax:
            return { statistics in return statistics.maximumQuantity()}
        case .cumulativeSum:
            return { statistics in return statistics.sumQuantity()}
        case .mostRecent:
            return { statistics in return statistics.mostRecentQuantity()}
        case .duration:
            return { statistics in return statistics.duration()}
        }
    }

    var toHKType: HKStatisticsOptions {
        switch self {
        case .discreteAverage:
            return .discreteAverage
        case .discreteMin:
            return .discreteMin
        case .discreteMax:
            return .discreteMax
        case .cumulativeSum:
            return .cumulativeSum
        case .mostRecent:
            return .mostRecent
        case .duration:
            return .duration
        }
    }
}