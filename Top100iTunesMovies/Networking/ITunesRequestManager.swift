//
//  ITunesRequestManager.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Foundation

import Alamofire

/// Handles iTunes Movies requests.
final class ITunesRequestManager {
    
    // preserve request session
    static var manager: Alamofire.Session?
    
    
    /// Server error definitions.
    enum ResponseError: Error {
        case noResponseData
        case serverError(Error?)
        case decodingError(Error)
        
        
        /// User interface message to be shown.
        var message: String {
            switch self {
            case .noResponseData:
                return "No data received from server"
            case .serverError(let error):
                return error?.localizedDescription ?? "Unknown error received from server"
            case .decodingError(let error):
                return error.localizedDescription
            }
        }
    }
    
    
    /// Possible countries for movie retrieval.
    enum Country: String {
        case UnitedStated = "us"
    }
    
    
    /// Requested server response type.
    enum ResponseFormat: String {
        case JSON = "json"
    }
    
    
    /// Request paths.
    enum RequestType {
        // top movies to be retrieved, specify a limit
        case topMovies(limit: Int)
        
        var rawValue: String {
            switch self {
            case .topMovies(let limit):
                return "topmovies/limit=\(limit)"
            }
        }
    }
    
    
    /// Creates the base API URL.
    /// - Parameter country: country for which to retrieve the movies
    /// - Returns: the API base URL without endpoint paths.
    static func baseURL(country: Country) -> URL {
        return URL(string: "https://itunes.apple.com/\(country.rawValue)/rss")!
    }
    
    
    /// Create full formed request URL.
    /// - Parameters:
    ///   - requestType: Request to be done.
    ///   - country: Country for which to retrieve data.
    ///   - responseFormat: type of server data response.
    /// - Returns: complete URL to be used for requests.
    func requestURLFor(type requestType: RequestType, country: Country, responseFormat: ResponseFormat) -> URL {
        switch requestType {
        case .topMovies:
            return Self.baseURL(country: country)
                .appendingPathComponent(requestType.rawValue)
                .appendingPathComponent(responseFormat.rawValue)
        }
    }
    
    
    /// Retrieve movies from iTunes API.
    /// - Parameters:
    ///   - limit: maximum number of movies.
    ///   - responseFormat: response data type.
    ///   - country: country from which to retrieve movies
    ///   - completion: contains response data.
    /// - Returns: top movies from API.
    func getTopMovies(limit: Int,
                      responseFormat: ResponseFormat = .JSON,
                      country: Country = .UnitedStated,
                      completion: @escaping (TypedRequestResponse<MoviesServerResponse?, ResponseError?>) -> Void) -> Void {
        
        let url = requestURLFor(type: .topMovies(limit: limit),
                                country: country,
                                responseFormat: responseFormat)
        
        let configuration = URLSessionConfiguration.default
        configuration.headers = HTTPHeaders.default
        configuration.requestCachePolicy = .reloadIgnoringCacheData
        
        let manager = Alamofire.Session(configuration: configuration)
        Self.manager = manager
        let request = manager.request(url,
                                      method: .get,
                                      encoding: JSONEncoding.default)
        
        // Allow empty responses for all methods since server doesn't respect standards
        request
            .validate()
            .responseData() { afResponse in
                switch afResponse.result {
                case .failure(let afError):
                    completion(.failure(.serverError(afError.underlyingError)))
                case .success(let data):
                    // don't treat empty responses as failures
                    guard !data.isEmpty else {
                        completion(.failure(.noResponseData))
                        return
                    }
                    do {
                        let decoded = try JSONDecoder().decode(MoviesServerResponse.self,
                                                               from: data)
                        completion(.success(decoded))
                    } catch {
                        // catch decoding errors
                        completion(.failure(.decodingError(error)))
                    }
                }
            }
        
        // server started sending inconsistent data so I switched to Alamofire
//        return ServerRequestManager.performGETRequest(url: url) { response in
//            switch response {
//            case .failure(let error):
//                completion(.failure(.serverError(error)))
//            case .success(let data):
//                guard let data = data else {
//                    // don't treat empty responses as failures
//                    completion(.failure(.noResponseData))
//                    return
//                }
////                do {
//                    let decoded = try JSONDecoder().decode(MoviesServerResponse.self,
//                                                            from: data)
//                    completion(.success(decoded))
////                } catch {
////                    // catch decoding errors
////                    completion(.failure(.decodingError(error)))
////                }
//            }
//        }
    }
}
