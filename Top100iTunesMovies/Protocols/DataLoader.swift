//
//  DataLoader.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Foundation
import AppKit


/// Defines methods to be called on loading state change.
protocol Loader: AnyObject {
    func loadingStateChanged(isLoading: Bool) -> Void
}

/// Specifies conformation for data loading.
protocol DataLoader {
    
    var delegate: Loader? { get set }
    /// Flag that defines if data loading is in progress.
    var isLoading: Bool { get }
    
    /// Loads data.
    func loadData(completion: @escaping (ITunesRequestManager.ResponseError?) -> Void) -> Void
}
