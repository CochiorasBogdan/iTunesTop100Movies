//
//  RequestManager.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Foundation

/// Wrapper for the server response data types on success and failure.
enum TypedRequestResponse<SuccessResponse, FailureResponse> {
    case failure(FailureResponse)
    case success(SuccessResponse)
}

/// Handles the creation of server requests.
struct ServerRequestManager {

    private init() {}
    
    // Data response from server.
    enum Response {
        case failure(Error?)
        case success(Data?)
    }
    
    
    /// Create a GET request.
    /// - Parameters:
    ///   - url: URL for the request execution.
    ///   - completion: response called when request is completed
    /// - Returns: the request data.
    static func createGETRequest(url: URL, completion: @escaping (Response) -> Void) -> URLSessionTask {
        return URLSession.shared.dataTask(with: url) { data, response, error in
            guard let httpURLResponse = response as? HTTPURLResponse,
                  // consider only 200 response as success
                  httpURLResponse.statusCode == 200 else {
                      completion(.failure(nil))
                      return
                  }
            /// Request failed.
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(data))
            }
        }
    }
    
    
    /// Create and execute a GET request.
    /// - Parameters:
    ///   - url: URL for the request execution.
    ///   - completion: response called when request is completed
    /// - Returns: the request data.
    static func performGETRequest(url: URL, completion: @escaping (Response) -> Void) -> URLSessionTask {
        let task = createGETRequest(url: url, completion: completion)
        // start the request
        task.resume()
        return task
    }
}
