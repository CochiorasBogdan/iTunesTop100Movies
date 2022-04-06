//
//  ImageLoader.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Foundation
import AppKit

/// Handles Image retrievel from server.
struct ImageRequestManager {
    
    /// Server response.
    enum Response {
        case failure(Error?)
        case success(NSImage)
    }
    
    
    /// Create a request for image retrieval.
    /// - Parameters:
    ///   - url: URL for the request execution.
    ///   - completion: response called when request is completed
    /// - Returns: the request data.
    func createGETImageRequest(from url: URL, completion: @escaping (Response) -> Void) -> URLSessionTask {
        return URLSession.shared.dataTask(with: url) { data, response, error in
            guard let httpURLResponse = response as? HTTPURLResponse,
                  // consider 200 as success
                  httpURLResponse.statusCode == 200,
                  let mimeType = response?.mimeType,
                  let data = data,
                  error == nil,
                  // check response data is imiage
                  mimeType.hasPrefix("image"),
                  let image = NSImage(data: data) else {
                      completion(.failure(error))
                      return
                  }
            
            completion(.success(image))
        }
    }
    
    /// Create a request for image retrieval.
    /// - Parameters:
    ///   - url: URL for the request execution.
    ///   - completion: response called when request is completed
    /// - Returns: the request data.
    @discardableResult func performGETImageRequest(from url: URL, completion: @escaping (Response) -> Void) -> URLSessionTask {
        let task = createGETImageRequest(from: url, completion: completion)
        task.resume()
        return task
    }
}
