import HealthKit

public class RNHealthKitCore {
    let healthStore: HKHealthStore

    public init(read: [any HealthKitType], write: [any HealthKitType]) async throws {
        healthStore = HKHealthStore()
        try await healthStore.requestAuthorization(
            toShare: Set(write.map{ $0.type }),
            read: Set(read.map{ $0.type })
        )
    }

    public func getQuantitySamplesAggregation(
        _ type: QuantityType,
        _ queryParameters: AggregationdQuantityQuery
    ) async throws -> [QuantitySample] {
        return try await withCheckedThrowingContinuation { continuation in
            let sampleType = type.type as! HKQuantityType
            let query = HKStatisticsCollectionQuery(
                quantityType: sampleType,
                quantitySamplePredicate: queryParameters.predicate,
                options: queryParameters.aggregationOption.toHKType,
                anchorDate: queryParameters.anchorDate,
                intervalComponents: queryParameters.interval
            )

            query.initialResultsHandler = { _, results, error in
                switchAndContinue(continuation: continuation, value: results, error: error) { collection in
                    return Self.enumerateStatistics(
                        collection: collection,
                        queryParameters
                    )
                }
            }
            healthStore.execute(query)
        }
    }
    
    static func enumerateStatistics(
        collection: HKStatisticsCollection,
        _ queryParameters: AggregationdQuantityQuery
    ) -> [QuantitySample] {
        var samples: [QuantitySample] = []
        let enumerationFunction = queryParameters.aggregationOption.enumeration
        collection.enumerateStatistics(from: queryParameters.startDate, to: queryParameters.endDate) { statistics, stop in
            enumerationFunction(statistics).map {
                samples.append(.init($0, queryParameters.unit, statistics.startDate, statistics.endDate))
            }
        }
        return samples
    }
    
    public func getQuantitySamples(_ type: QuantityType, _ queryParameters: QuantityQuery) async throws -> [QuantitySample] {
        return try await withCheckedThrowingContinuation { continuation in
            let sampleType = type.type as! HKQuantityType
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: queryParameters.predicate,
                limit: queryParameters.limit,
                sortDescriptors: [sortDescriptor])
            { (_, samples, error) in
                guard error == nil else {
                    continuation.resume(throwing: error!)
                    return
                }
                let quantitySamples = (samples as! [HKQuantitySample]).map {
                    QuantitySample($0, queryParameters.unit)
                }
                continuation.resume(returning: quantitySamples)
            }
            healthStore.execute(query)
        }
    }
}