//
//  WeatherManager.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import CoreLocation

// MARK: - 天气条件枚举
enum WeatherCondition: String, Codable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case snowy = "snowy"
    case foggy = "foggy"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .sunny: return "晴天"
        case .cloudy: return "多云"
        case .rainy: return "雨天"
        case .snowy: return "雪天"
        case .foggy: return "雾天"
        case .unknown: return "未知"
        }
    }
    
    var iconSymbol: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "snowflake"
        case .foggy: return "cloud.fog.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - 天气数据
struct WeatherData {
    let condition: WeatherCondition
    let temperature: Double         // 摄氏度
    let humidity: Double            // 湿度百分比 0-100
    let windSpeed: Double           // 风速 km/h
    let weatherText: String         // 天气描述文字
    let location: CLLocation?
    let fetchTime: Date
    
    /// 转换为 WeatherInfo（用于成就检测）
    var asWeatherInfo: WeatherInfo {
        WeatherInfo(condition: condition.rawValue, temperature: temperature)
    }
}

// MARK: - QWeather API 响应模型
struct QWeatherResponse: Codable {
    let code: String
    let updateTime: String?
    let now: QWeatherNow?
}

struct QWeatherNow: Codable {
    let obsTime: String?     // 观测时间
    let temp: String         // 温度
    let feelsLike: String?   // 体感温度
    let icon: String         // 图标代码
    let text: String         // 天气描述 (晴、多云、雨等)
    let wind360: String?     // 风向角度
    let windDir: String?     // 风向
    let windScale: String?   // 风力等级
    let windSpeed: String    // 风速 km/h
    let humidity: String     // 湿度
    let precip: String?      // 降水量
    let pressure: String?    // 气压
    let vis: String?         // 能见度
    let cloud: String?       // 云量
    let dew: String?         // 露点温度
}

// MARK: - 天气管理器
@MainActor
class WeatherManager: ObservableObject {
    static let shared = WeatherManager()
    
    // MARK: - 发布的属性
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - QWeather API 配置
    private let apiHost = "ma3h2qt5y2.re.qweatherapi.com"
    private let apiKey = "Q173DD9FF9"
    
    private init() {}
    
    // MARK: - 获取当前天气
    
    /// 根据位置获取天气 (使用和风天气 QWeather API)
    /// - Parameter location: 当前位置
    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        
        // 构建请求 URL
        // 格式: https://{host}/v7/weather/now?location={lon},{lat}
        let lon = String(format: "%.2f", location.coordinate.longitude)
        let lat = String(format: "%.2f", location.coordinate.latitude)
        let urlString = "https://\(apiHost)/v7/weather/now?location=\(lon),\(lat)&lang=zh"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "无效的 URL"
            isLoading = false
            return
        }
        
        // 创建请求并添加认证头
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // 启用 gzip 压缩
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查 HTTP 状态码
            if let httpResponse = response as? HTTPURLResponse {
                print("WeatherManager: HTTP 状态码 \(httpResponse.statusCode)")
            }
            
            // 解析响应
            let decoder = JSONDecoder()
            let qweatherResponse = try decoder.decode(QWeatherResponse.self, from: data)
            
            // 检查 API 返回码
            guard qweatherResponse.code == "200", let now = qweatherResponse.now else {
                errorMessage = "API 错误: \(qweatherResponse.code)"
                print("WeatherManager: \(errorMessage ?? "")")
                
                #if DEBUG
                currentWeather = mockWeatherData(for: location)
                #endif
                
                isLoading = false
                return
            }
            
            // 解析天气数据
            let condition = mapQWeatherCondition(text: now.text, icon: now.icon)
            let temperature = Double(now.temp) ?? 0
            let humidity = Double(now.humidity) ?? 0
            let windSpeed = Double(now.windSpeed) ?? 0
            
            currentWeather = WeatherData(
                condition: condition,
                temperature: temperature,
                humidity: humidity,
                windSpeed: windSpeed,
                weatherText: now.text,
                location: location,
                fetchTime: Date()
            )
            
            print("WeatherManager: 获取天气成功 - \(now.text), \(Int(temperature))°C")
            
        } catch {
            errorMessage = "获取天气失败: \(error.localizedDescription)"
            print("WeatherManager: \(errorMessage ?? "")")
            print("WeatherManager: 错误详情 - \(error)")
            
            // 使用模拟数据（开发/测试用）
            #if DEBUG
            currentWeather = mockWeatherData(for: location)
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - 映射 QWeather 天气条件
    
    /// 根据天气描述文字和图标代码映射到 WeatherCondition
    private func mapQWeatherCondition(text: String, icon: String) -> WeatherCondition {
        // 优先使用图标代码判断（更准确）
        if let iconCode = Int(icon) {
            switch iconCode {
            case 100...103:
                // 100: 晴, 101: 多云, 102: 少云, 103: 晴间多云
                return iconCode == 100 ? .sunny : .cloudy
            case 104, 150...154:
                // 104: 阴, 150-154: 夜间多云/阴
                return .cloudy
            case 300...399:
                // 300-399: 各种雨
                return .rainy
            case 400...499:
                // 400-499: 各种雪
                return .snowy
            case 500...515:
                // 500-515: 雾/霾
                return .foggy
            default:
                break
            }
        }
        
        // 备用：使用文字判断
        if text.contains("晴") { return .sunny }
        if text.contains("云") || text.contains("阴") { return .cloudy }
        if text.contains("雨") || text.contains("雷") || text.contains("阵") { return .rainy }
        if text.contains("雪") || text.contains("冰") { return .snowy }
        if text.contains("雾") || text.contains("霾") || text.contains("沙") || text.contains("尘") { return .foggy }
        
        return .unknown
    }
    
    // MARK: - 模拟数据（开发用）
    
    #if DEBUG
    private func mockWeatherData(for location: CLLocation) -> WeatherData {
        // 根据当前时间模拟不同天气
        let hour = Calendar.current.component(.hour, from: Date())
        let condition: WeatherCondition
        let temperature: Double
        let text: String
        
        switch hour {
        case 6..<10:
            condition = .cloudy
            temperature = 18.0
            text = "多云"
        case 10..<16:
            condition = .sunny
            temperature = 25.0
            text = "晴"
        case 16..<20:
            condition = .cloudy
            temperature = 22.0
            text = "多云"
        default:
            condition = .cloudy
            temperature = 15.0
            text = "阴"
        }
        
        return WeatherData(
            condition: condition,
            temperature: temperature,
            humidity: 65.0,
            windSpeed: 10.0,
            weatherText: text,
            location: location,
            fetchTime: Date()
        )
    }
    
    /// 手动设置天气（测试用）
    func setMockWeather(condition: WeatherCondition, temperature: Double) {
        currentWeather = WeatherData(
            condition: condition,
            temperature: temperature,
            humidity: 50.0,
            windSpeed: 8.0,
            weatherText: condition.displayName,
            location: nil,
            fetchTime: Date()
        )
    }
    #endif
}
