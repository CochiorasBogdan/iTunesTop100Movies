//
//  ImageDownloadManager.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Foundation
import AppKit

/// Handles image download for the application.
struct ImageDownloadManager {
    
    let manager = ImageRequestManager()
    
    /// Image cache.
    private static let cache = NSCache<NSString, NSImage>()
    
    /// Stores requests.
    private let operationQueue: OperationQueue = {
        let temp = OperationQueue()
        temp.maxConcurrentOperationCount = 4
        temp.qualityOfService = .utility
        return temp
    }()
    
    static let shared = ImageDownloadManager()
    private init() {}
    
    
    /// Retrieves already cached image from cache.
    /// - Parameter key: cached image key.
    /// - Returns: the cached image if it exists.
    static func cachedImage(forKey key: String) -> NSImage? {
        return Self.cache.object(forKey: key as NSString)
    }
    
    
    /// Retrieves an image for the specified URL, either from cache or from server.
    /// - Parameters:
    ///   - url: URL of the image to be retrieved.
    ///   - completion: response which contains the image.
    func downloadImage(for url: URL, completion: @escaping (ImageRequestManager.Response) -> Void) {
        let imageKey = url.absoluteString
        // retrieve from cache if it exists
        if let image = Self.cache.object(forKey: imageKey as NSString) {
            completion(.success(image))
            return
        } else if let operation = operationQueue.operations.first(where: {$0.name == imageKey}) {
            // increase existing image operation priority
            operation.queuePriority = .high
            self.operationQueue.operations.forEach({
                if $0 != operation {
                    $0.queuePriority = .normal
                }
            })
            // preserve any previous completion
            let previousCompletionBlock = operation.completionBlock
            operation.completionBlock = {
                // also call current completion after original operation finishes and image is cached
                if let image = Self.cache.object(forKey: imageKey as NSString) {
                    completion(.success(image))
                } else {
                    completion(.failure(nil))
                }
                previousCompletionBlock?()
            }
            
        } else {
            // create an operation for image fetching
            let operation = BlockOperation()
            operation.name = imageKey
            operation.queuePriority = .high
            operation.addExecutionBlock {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                // reduce other queue items priorities to do a LIFO style downloading
                self.operationQueue.operations.forEach({$0.queuePriority = .normal})
                self.manager.performGETImageRequest(from: url, completion: { response in
                    switch response {
                    case .failure(_):
                        break
                    case .success(let image):
                        // cache image
                        Self.cache.setObject(image, forKey: imageKey as NSString)
                    }
                    completion(response)
                    dispatchGroup.leave()
                })
                dispatchGroup.wait()
            }
            operation.start()
        }
    }
}
