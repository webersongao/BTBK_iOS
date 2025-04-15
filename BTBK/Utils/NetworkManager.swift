import Foundation
import Alamofire

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    // 基础URL
//    private let baseURL = "https://www.btbk.org/mobile_api"
    private let baseURL = "https://demo.bkdh.net/mobile_api"
    
    // 错误枚举
    enum NetworkError: Error {
        case invalidURL
        case requestFailed(String)
        case decodingFailed(Error)
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "无效的URL"
            case .requestFailed(let message):
                return message
            case .decodingFailed(let error):
                return "数据解析失败: \(error.localizedDescription)"
            }
        }
    }
    
    // POST请求
    func post<T: Codable>(
        endpoint: String,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil
    ) async throws -> T {
        let url = "\(baseURL)/\(endpoint)?spa_load=1&client=BTBK"
        print("发起POST请求: \(url)")
        print("参数: \(parameters ?? [:])")
        
        let request = AF.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            request
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        print("请求成功，响应数据大小: \(data.count) 字节")
                        
                        do {
                            let decoder = JSONDecoder()
                            let decodedResponse = try decoder.decode(T.self, from: data)
                            continuation.resume(returning: decodedResponse)
                        } catch {
                            print("解码失败: \(error)")
                            // 尝试解析错误响应
                            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                print("服务器返回错误: \(errorResponse.message)")
                                continuation.resume(throwing: NetworkError.requestFailed(errorResponse.message))
                            } else {
                                continuation.resume(throwing: NetworkError.decodingFailed(error))
                            }
                        }
                    case .failure(let error):
                        print("请求失败: \(error.localizedDescription)")
                        if let data = response.data,
                           let errorString = String(data: data, encoding: .utf8) {
                            print("错误响应数据: \(errorString)")
                        }
                        continuation.resume(throwing: NetworkError.requestFailed(error.localizedDescription))
                    }
                }
        }
    }
    
    // GET请求
    func get<T: Codable>(
        endpoint: String,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil
    ) async throws -> T {
        let url = "\(baseURL)/\(endpoint)?spa_load=1&client=BTBK"
        print("发起GET请求: \(url)")
        print("参数: \(parameters ?? [:])")
        
        let request = AF.request(
            url,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.default,
            headers: headers
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            request
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        print("请求成功，响应数据大小: \(data.count) 字节")
                        
                        do {
                            let decoder = JSONDecoder()
                            let decodedResponse = try decoder.decode(T.self, from: data)
                            continuation.resume(returning: decodedResponse)
                        } catch let decodingError as DecodingError {
                            // 详细打印解码错误
                            print("解码失败: \(decodingError)")
                            
                            switch decodingError {
                            case .typeMismatch(let type, let context):
                                print("类型不匹配: 期望 \(type)，路径: \(context.codingPath.map { $0.stringValue })")
                            case .valueNotFound(let type, let context):
                                print("值未找到: 期望 \(type)，路径: \(context.codingPath.map { $0.stringValue })")
                            case .keyNotFound(let key, let context):
                                print("键未找到: \(key.stringValue)，路径: \(context.codingPath.map { $0.stringValue })")
                            case .dataCorrupted(let context):
                                print("数据损坏: \(context.debugDescription)，路径: \(context.codingPath.map { $0.stringValue })")
                            @unknown default:
                                print("未知解码错误: \(decodingError)")
                            }
                            
                            // 尝试解析错误响应
                            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                print("服务器返回错误: \(errorResponse.message)")
                                continuation.resume(throwing: NetworkError.requestFailed(errorResponse.message))
                            } else {
                                continuation.resume(throwing: NetworkError.decodingFailed(decodingError))
                            }
                        } catch {
                            print("其他解码错误: \(error)")
                            continuation.resume(throwing: NetworkError.decodingFailed(error))
                        }
                    case .failure(let error):
                        print("请求失败: \(error.localizedDescription)")
                        if let data = response.data,
                           let errorString = String(data: data, encoding: .utf8) {
                            print("错误响应数据: \(errorString)")
                        }
                        continuation.resume(throwing: NetworkError.requestFailed(error.localizedDescription))
                    }
                }
        }
    }
}

// 通用错误响应模型
struct ErrorResponse: Codable {
    let code: Int
    let message: String
    let data: [String]?
} 
