//
//  CareStatistics.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import Foundation

struct CareStatistics {
    let daysSinceLastWatering: Int
    let daysSinceLastFertilizing: Int
    let totalCareEvents: Int
    let careStreak: Int
    let currentWateringStreak: Int
    let healthScore: Double
    let totalDaysInCollection: Int
    
    init(careEvents: [CareEvent]) {
        let sortedEvents = careEvents.sorted { $0.date > $1.date }
        
        // Calculate days since last watering
        if let lastWatering = sortedEvents.first(where: { $0.type == .watering }) {
            daysSinceLastWatering = Calendar.current.dateComponents([.day], from: lastWatering.date, to: Date()).day ?? 0
        } else {
            daysSinceLastWatering = 999
        }
        
        // Calculate days since last fertilizing
        if let lastFertilizing = sortedEvents.first(where: { $0.type == .fertilizing }) {
            daysSinceLastFertilizing = Calendar.current.dateComponents([.day], from: lastFertilizing.date, to: Date()).day ?? 0
        } else {
            daysSinceLastFertilizing = 999
        }
        
        totalCareEvents = careEvents.count
        
        // Calculate care streak (consecutive days with care events)
        let calendar = Calendar.current
        let today = Date()
        var streakCount = 0
        var currentDate = today
        
        for i in 0..<30 { // Check last 30 days
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let hasEventThisDay = careEvents.contains { event in
                event.date >= dayStart && event.date < dayEnd
            }
            
            if hasEventThisDay {
                streakCount += 1
            } else if i > 0 { // Don't break on first day (today)
                break
            }
            
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        careStreak = streakCount
        currentWateringStreak = streakCount // For simplicity, use same value
        
        // Calculate health score (simplified)
        let recentEvents = careEvents.filter {
            (Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 999) < 30
        }
        healthScore = min(1.0, Double(recentEvents.count) / 10.0)
        
        // Calculate days in collection (simplified)
        if let oldestEvent = careEvents.sorted(by: { $0.date < $1.date }).first {
            totalDaysInCollection = Calendar.current.dateComponents([.day], from: oldestEvent.date, to: Date()).day ?? 0
        } else {
            totalDaysInCollection = 0
        }
    }
}

private extension TimeInterval {
    var days: Int {
        Int(self / 86400)
    }
}
