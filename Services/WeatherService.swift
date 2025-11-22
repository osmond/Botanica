import Foundation
import CoreLocation
import WeatherKit

/// Weather service for fetching current and forecast weather data
/// Integrates with Apple's WeatherKit for accurate, location-based weather information
class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()
    
    // MARK: - Published Properties
    @Published var currentWeather: CurrentWeather?
    @Published var forecast: Forecast<DayWeather>?
    @Published var isLoading = false
    @Published var lastError: Error?
    @Published var lastLocationUpdate: Date?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let wxService = WeatherKit.WeatherService()
    private var currentLocation: CLLocation?
    
    // MARK: - Location accuracy threshold (500 meters)
    private let locationAccuracyThreshold: CLLocationDistance = 500
    
    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Authorization
    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Public Methods
    
    /// Request weather data for current location
    func requestWeatherUpdate() async {
        await requestLocationAndWeather()
    }
    
    /// Get weather-adjusted care recommendations
    func getWeatherAdjustments(for plant: Plant) -> WeatherCareAdjustments {
        guard let current = currentWeather else {
            return WeatherCareAdjustments()
        }
        
        return WeatherCareAdjustments(
            wateringMultiplier: calculateWateringMultiplier(
                temperature: current.temperature,
                humidity: current.humidity,
                plant: plant
            ),
            lightAdjustment: calculateLightAdjustment(
                condition: current.condition,
                uvIndex: current.uvIndex
            ),
            careMessage: generateCareMessage(weather: current, plant: plant)
        )
    }
    
    /// Check if weather conditions are suitable for repotting
    func isGoodRepottingWeather() -> Bool {
        guard let current = currentWeather else { return true }
        
        // Ideal conditions: moderate temperature, low humidity, no precipitation
        let temperature = current.temperature.converted(to: .fahrenheit).value
        let humidity = current.humidity
        
        return temperature >= 65 && temperature <= 80 &&
               humidity < 0.7 &&
               current.condition != .rain &&
               current.condition != .snow
    }
    
    /// Get weekly weather summary for care planning
    func getWeeklyCareSummary() -> WeeklyCareWeather? {
        guard let forecast = forecast else { return nil }
        
        let dailyWeather = Array(forecast.prefix(7))
        
        return WeeklyCareWeather(
            averageTemperature: calculateAverageTemperature(from: dailyWeather),
            totalPrecipitation: calculateTotalPrecipitation(from: dailyWeather),
            averageHumidity: calculateAverageHumidity(from: dailyWeather),
            sunnyDays: countSunnyDays(from: dailyWeather),
            recommendations: generateWeeklyRecommendations(from: dailyWeather)
        )
    }
}

// MARK: - Private Methods
private extension WeatherService {
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationAndWeather() async {
        await MainActor.run { self.isLoading = true; self.lastError = nil }
        
        do {
            // Request location if needed
            if currentLocation == nil || shouldUpdateLocation() {
                await requestLocation()
            }
            
            guard let location = currentLocation else {
                throw WeatherError.locationUnavailable
            }
            
            // Fetch weather data
            async let currentWeatherTask = wxService.weather(for: location)
            async let forecastTask = wxService.weather(for: location, including: .daily)
            
            let (current, dailyForecast) = try await (currentWeatherTask, forecastTask)
            
            await MainActor.run {
                self.currentWeather = current.currentWeather
                self.forecast = dailyForecast
                self.lastLocationUpdate = Date()
            }
            
        } catch {
            await MainActor.run { self.lastError = error }
            print("Weather fetch error: \(error)")
        }
        await MainActor.run { self.isLoading = false }
    }
    
    func requestLocation() async {
        // Fire-and-forget request; delegate will deliver results
        locationManager.requestLocation()
    }
    
    func shouldUpdateLocation() -> Bool {
        guard let lastUpdate = lastLocationUpdate else { return true }
        return Date().timeIntervalSince(lastUpdate) > 3600 // Update every hour
    }
    
    // MARK: - Weather Calculation Methods
    
    func calculateWateringMultiplier(temperature: Measurement<UnitTemperature>, 
                                   humidity: Double, 
                                   plant: Plant) -> Double {
        let tempF = temperature.converted(to: .fahrenheit).value
        
        // Base multiplier
        var multiplier = 1.0
        
        // Temperature adjustments
        if tempF > 80 {
            multiplier += 0.3 // Hot weather = more water
        } else if tempF < 65 {
            multiplier -= 0.2 // Cool weather = less water
        }
        
        // Humidity adjustments
        if humidity < 0.3 {
            multiplier += 0.2 // Dry air = more water
        } else if humidity > 0.7 {
            multiplier -= 0.2 // Humid air = less water
        }
        
        // Plant-specific adjustments
        switch plant.lightLevel {
        case .direct, .bright:
            multiplier += 0.1 // Brighter light plants need more water
        case .low:
            multiplier -= 0.1 // Low light plants need less water
        case .medium:
            break
        }
        
        return max(0.5, min(2.0, multiplier)) // Clamp between 0.5x and 2.0x
    }
    
    func calculateLightAdjustment(condition: WeatherCondition, uvIndex: UVIndex) -> LightAdjustment {
        switch condition {
        case .clear, .mostlyClear:
            return .increaseIndoorLight
        case .cloudy, .mostlyCloudy:
            return .provideSupplementalLight
        case .rain, .snow:
            return .maximizeAvailableLight
        default:
            return .normal
        }
    }
    
    func generateCareMessage(weather: CurrentWeather, plant: Plant) -> String {
        let tempF = weather.temperature.converted(to: .fahrenheit).value
        let condition = weather.condition
        
        var messages: [String] = []
        
        // Temperature-based messages
        if tempF > 85 {
            messages.append("Hot weather - consider extra watering and humidity")
        } else if tempF < 55 {
            messages.append("Cool weather - reduce watering frequency")
        }
        
        // Condition-based messages
        switch condition {
        case .clear, .mostlyClear:
            messages.append("Bright conditions - great for photosynthesis!")
        case .cloudy, .mostlyCloudy:
            messages.append("Limited light - move plants closer to windows")
        case .rain:
            messages.append("Rainy day - good time for indoor plant care")
        default:
            break
        }
        
        return messages.joined(separator: " • ")
    }
    
    // MARK: - Weekly Summary Calculations
    
    func calculateAverageTemperature(from forecast: [DayWeather]) -> Measurement<UnitTemperature> {
        let total = forecast.reduce(into: 0.0) { sum, day in
            sum += day.highTemperature.converted(to: .fahrenheit).value
        }
        return Measurement(value: total / Double(forecast.count), unit: UnitTemperature.fahrenheit)
    }
    
    func calculateTotalPrecipitation(from forecast: [DayWeather]) -> Measurement<UnitLength> {
        let total = forecast.reduce(into: 0.0) { sum, day in
            sum += day.precipitationAmount.converted(to: .inches).value
        }
        return Measurement(value: total, unit: UnitLength.inches)
    }
    
    func calculateAverageHumidity(from forecast: [DayWeather]) -> Double {
        // DayWeather does not expose humidity; fall back to current conditions if available.
        if let current = currentWeather { return current.humidity }
        return 0.5
    }
    
    func countSunnyDays(from forecast: [DayWeather]) -> Int {
        return forecast.filter { day in
            day.condition == .clear || day.condition == .mostlyClear
        }.count
    }
    
    func generateWeeklyRecommendations(from forecast: [DayWeather]) -> [String] {
        var recommendations: [String] = []
        
        let avgTemp = calculateAverageTemperature(from: forecast).converted(to: .fahrenheit).value
        let precipitation = calculateTotalPrecipitation(from: forecast).value
        let sunnyDays = countSunnyDays(from: forecast)
        
        if avgTemp > 80 {
            recommendations.append("Hot week ahead - increase watering frequency")
        } else if avgTemp < 60 {
            recommendations.append("Cool week - reduce watering and fertilizing")
        }
        
        if precipitation > 0.5 {
            recommendations.append("Rainy week - watch for overwatering")
        } else if precipitation < 0.1 {
            recommendations.append("Dry week - pay extra attention to soil moisture")
        }
        
        if sunnyDays >= 5 {
            recommendations.append("Lots of sun this week - great growing conditions!")
        } else if sunnyDays <= 2 {
            recommendations.append("Limited sun - consider grow lights for light-loving plants")
        }
        
        return recommendations
    }
}

// MARK: - CLLocationManagerDelegate
extension WeatherService: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            // Only update if location has changed significantly
            if let current = self.currentLocation {
                let distance = location.distance(from: current)
                if distance < self.locationAccuracyThreshold {
                    return
                }
            }
            
            self.currentLocation = location
            await self.requestWeatherUpdate()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.lastError = WeatherError.locationError(error) }
        print("Location error: \(error)")
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            Task { @MainActor in if self.currentLocation == nil { manager.requestLocation() } }
        case .denied, .restricted:
            Task { @MainActor in self.lastError = WeatherError.locationPermissionDenied }
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

// MARK: - Supporting Types

enum WeatherError: LocalizedError {
    case locationUnavailable
    case locationPermissionDenied
    case locationError(Error)
    case weatherServiceError(Error)
    
    var errorDescription: String? {
        switch self {
        case .locationUnavailable:
            return "Location unavailable for weather data"
        case .locationPermissionDenied:
            return "Location permission denied"
        case .locationError(let error):
            return "Location error: \(error.localizedDescription)"
        case .weatherServiceError(let error):
            return "Weather service error: \(error.localizedDescription)"
        }
    }
}

struct WeatherCareAdjustments {
    let wateringMultiplier: Double
    let lightAdjustment: LightAdjustment
    let careMessage: String
    
    init(wateringMultiplier: Double = 1.0, 
         lightAdjustment: LightAdjustment = .normal, 
         careMessage: String = "") {
        self.wateringMultiplier = wateringMultiplier
        self.lightAdjustment = lightAdjustment
        self.careMessage = careMessage
    }
}

enum LightAdjustment {
    case normal
    case increaseIndoorLight
    case provideSupplementalLight
    case maximizeAvailableLight
    
    var message: String {
        switch self {
        case .normal:
            return "Normal light conditions"
        case .increaseIndoorLight:
            return "Move closer to bright windows"
        case .provideSupplementalLight:
            return "Consider grow lights today"
        case .maximizeAvailableLight:
            return "Maximize available natural light"
        }
    }
}

struct WeeklyCareWeather {
    let averageTemperature: Measurement<UnitTemperature>
    let totalPrecipitation: Measurement<UnitLength>
    let averageHumidity: Double
    let sunnyDays: Int
    let recommendations: [String]
}
