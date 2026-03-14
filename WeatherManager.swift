// WeatherManager.swift
import Foundation
import CoreLocation
import WeatherKit

@MainActor
class WeatherManager: ObservableObject {
    static let shared = WeatherManager()

    @Published var currentWeather: WeatherInfo? = .default
    @Published var isLoading = false

    private let service = WeatherService.shared

    private init() {}

    func fetchWeather(for location: CLLocation) async {
        isLoading = true

        do {
            let weather = try await service.weather(for: location)
            let current = weather.currentWeather

            let weatherInfo = WeatherInfo(
                condition: current.condition,
                temperature: current.temperature.converted(to: .celsius).value,
                humidity: current.humidity,
                windSpeed: current.wind.speed.converted(to: .metersPerSecond).value
            )

            self.currentWeather = weatherInfo
            self.isLoading = false

            print("✅ [WeatherManager] 获取天气成功: \(weatherInfo.conditionText), \(Int(weatherInfo.temperature))°C")
        } catch {
            print("❌ [WeatherManager] 获取天气失败: \(error.localizedDescription)")
            self.isLoading = false
        }
    }
}

// MARK: - Weather Models

struct WeatherInfo {
    let condition: WeatherCondition
    let temperature: Double
    let humidity: Double
    let windSpeed: Double

    /// 是否属于雨天（包括小雨/大雨/雷雨/毛毛雨）
    var isRainy: Bool {
        switch condition {
        case .rain, .heavyRain, .drizzle, .freezingDrizzle, .sunShowers,
             .thunderstorms, .strongStorms, .isolatedThunderstorms, .scatteredThunderstorms:
            return true
        default:
            return false
        }
    }

    var emoji: String {
        switch condition {
        case .blizzard, .heavySnow:
            return "🌨️"
        case .blowingSnow, .snow, .flurries, .sleet, .freezingRain, .wintryMix:
            return "❄️"
        case .thunderstorms, .strongStorms, .isolatedThunderstorms, .scatteredThunderstorms:
            return "⛈️"
        case .rain, .heavyRain, .freezingDrizzle:
            return "🌧️"
        case .drizzle, .sunShowers:
            return "🌦️"
        case .hurricane, .tropicalStorm:
            return "🌪️"
        case .windy, .breezy:
            return "💨"
        case .haze, .foggy, .smoky, .blowingDust:
            return "🌫️"
        case .clear, .hot:
            return "☀️"
        case .mostlyClear:
            return "🌤️"
        case .partlyCloudy:
            return "⛅"
        case .mostlyCloudy, .cloudy:
            return "☁️"
        default:
            return "🌤️"
        }
    }

    var conditionText: String {
        let isEN = LanguageManager.shared.currentLocale == "en"
        switch condition {
        case .clear:             return isEN ? "Clear" : "晴天"
        case .mostlyClear:       return isEN ? "Mostly Clear" : "大部晴朗"
        case .partlyCloudy:      return isEN ? "Partly Cloudy" : "局部多云"
        case .mostlyCloudy:      return isEN ? "Mostly Cloudy" : "大部多云"
        case .cloudy:            return isEN ? "Cloudy" : "阴天"
        case .rain, .heavyRain:  return isEN ? "Rain" : "雨"
        case .drizzle, .freezingDrizzle: return isEN ? "Drizzle" : "小雨"
        case .snow, .heavySnow, .flurries: return isEN ? "Snow" : "雪"
        case .sleet, .freezingRain, .wintryMix: return isEN ? "Sleet" : "雨夹雪"
        case .thunderstorms, .strongStorms, .isolatedThunderstorms, .scatteredThunderstorms: return isEN ? "Thunderstorms" : "雷雨"
        case .foggy:             return isEN ? "Foggy" : "雾"
        case .haze:              return isEN ? "Haze" : "霾"
        case .windy, .breezy:    return isEN ? "Windy" : "大风"
        case .hot:               return isEN ? "Hot" : "高温"
        case .blizzard, .blowingSnow: return isEN ? "Blizzard" : "暴风雪"
        case .hurricane, .tropicalStorm: return isEN ? "Typhoon" : "台风"
        case .smoky:             return isEN ? "Smoky" : "烟雾"
        case .blowingDust:       return isEN ? "Dusty" : "扬尘"
        case .sunShowers:        return isEN ? "Sun Showers" : "太阳雨"
        default:                 return isEN ? "Clear" : "晴天"
        }
    }

    var displayText: String {
        return "\(conditionText), \(Int(temperature))°C"
    }

    static var `default`: WeatherInfo {
        WeatherInfo(
            condition: .clear,
            temperature: 24,
            humidity: 0.65,
            windSpeed: 3.0
        )
    }
}
