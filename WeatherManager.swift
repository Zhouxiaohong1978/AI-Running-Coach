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
        switch condition {
        case .clear: return "晴天"
        case .mostlyClear: return "大部晴朗"
        case .partlyCloudy: return "局部多云"
        case .mostlyCloudy: return "大部多云"
        case .cloudy: return "阴天"
        case .rain, .heavyRain: return "雨"
        case .drizzle, .freezingDrizzle: return "小雨"
        case .snow, .heavySnow, .flurries: return "雪"
        case .sleet, .freezingRain, .wintryMix: return "雨夹雪"
        case .thunderstorms, .strongStorms, .isolatedThunderstorms, .scatteredThunderstorms: return "雷雨"
        case .foggy: return "雾"
        case .haze: return "霾"
        case .windy, .breezy: return "大风"
        case .hot: return "高温"
        case .blizzard, .blowingSnow: return "暴风雪"
        case .hurricane, .tropicalStorm: return "台风"
        case .smoky: return "烟雾"
        case .blowingDust: return "扬尘"
        case .sunShowers: return "太阳雨"
        default: return "晴天"
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
