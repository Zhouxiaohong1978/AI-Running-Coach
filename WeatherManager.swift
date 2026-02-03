// WeatherManager.swift
import Foundation
import CoreLocation

@MainActor
class WeatherManager: ObservableObject {
    static let shared = WeatherManager()

    @Published var currentWeather: WeatherInfo? = .default  // 默认晴天 24°C
    @Published var isLoading = false

    // OpenWeatherMap API Key
    private let apiKey = "b7305666b739b24b9d516f93114e7a96"
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"

    private init() {}

    // 获取天气信息（使用 OpenWeatherMap API）
    func fetchWeather(for location: CLLocation) async {
        guard apiKey != "YOUR_API_KEY_HERE" else {
            print("⚠️ [WeatherManager] 请先配置 OpenWeatherMap API Key")
            return
        }

        isLoading = true

        do {
            // 构建 URL
            var components = URLComponents(string: baseURL)!
            components.queryItems = [
                URLQueryItem(name: "lat", value: "\(location.coordinate.latitude)"),
                URLQueryItem(name: "lon", value: "\(location.coordinate.longitude)"),
                URLQueryItem(name: "appid", value: apiKey),
                URLQueryItem(name: "units", value: "metric"),  // 摄氏度
                URLQueryItem(name: "lang", value: "zh_cn")      // 中文
            ]

            guard let url = components.url else {
                throw URLError(.badURL)
            }

            // 发送请求
            print("🌐 [WeatherManager] 请求URL: \(url.absoluteString)")
            let (data, httpResponse) = try await URLSession.shared.data(from: url)

            // 打印响应状态
            if let httpResponse = httpResponse as? HTTPURLResponse {
                print("📡 [WeatherManager] HTTP状态码: \(httpResponse.statusCode)")
            }

            // 打印原始响应
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 [WeatherManager] 原始响应: \(jsonString)")
            }

            // 解析响应
            let response = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)

            // 转换为 WeatherInfo
            let weatherInfo = WeatherInfo(
                conditionCode: response.weather.first?.id ?? 800,
                conditionDescription: response.weather.first?.description ?? "晴天",
                temperature: response.main.temp,
                humidity: response.main.humidity / 100.0,
                windSpeed: response.wind.speed
            )

            self.currentWeather = weatherInfo
            self.isLoading = false

            print("✅ [WeatherManager] 获取天气成功: \(weatherInfo.conditionText), \(Int(weatherInfo.temperature))°C")
        } catch {
            print("❌ [WeatherManager] 获取天气失败: \(error.localizedDescription)")
            // 保持默认天气数据
            self.isLoading = false
        }
    }
}

// MARK: - OpenWeatherMap API Models

struct OpenWeatherResponse: Codable {
    let weather: [WeatherCondition]
    let main: MainInfo
    let wind: WindInfo

    struct WeatherCondition: Codable {
        let id: Int
        let main: String
        let description: String
    }

    struct MainInfo: Codable {
        let temp: Double
        let humidity: Double
    }

    struct WindInfo: Codable {
        let speed: Double
    }
}

// MARK: - Weather Models

struct WeatherInfo {
    let conditionCode: Int               // OpenWeatherMap 天气代码
    let conditionDescription: String     // 天气描述
    let temperature: Double              // 温度（摄氏度）
    let humidity: Double                 // 湿度（0-1）
    let windSpeed: Double                // 风速（m/s）

    var emoji: String {
        // OpenWeatherMap 天气代码映射
        // https://openweathermap.org/weather-conditions
        switch conditionCode {
        case 200..<300:  // 雷雨
            return "⛈️"
        case 300..<400:  // 毛毛雨
            return "🌧️"
        case 500..<600:  // 雨
            return "🌧️"
        case 600..<700:  // 雪
            return "❄️"
        case 701:        // 雾
            return "🌫️"
        case 711:        // 烟雾
            return "🌫️"
        case 721:        // 霾
            return "🌫️"
        case 731, 751, 761:  // 沙尘
            return "🌫️"
        case 741:        // 大雾
            return "🌫️"
        case 771:        // 狂风
            return "💨"
        case 781:        // 龙卷风
            return "🌪️"
        case 800:        // 晴天
            return "☀️"
        case 801:        // 少云
            return "🌤️"
        case 802:        // 局部多云
            return "⛅"
        case 803, 804:   // 多云、阴天
            return "☁️"
        default:
            return "🌤️"
        }
    }

    var conditionText: String {
        return conditionDescription
    }

    var displayText: String {
        return "\(conditionText), \(Int(temperature))°C"
    }

    static var `default`: WeatherInfo {
        WeatherInfo(
            conditionCode: 800,
            conditionDescription: "晴天",
            temperature: 24,
            humidity: 0.65,
            windSpeed: 3.0
        )
    }
}
