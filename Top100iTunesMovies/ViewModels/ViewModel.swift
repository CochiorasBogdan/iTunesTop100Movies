//
//  ViewModel.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Foundation
import AppKit

/// Handles interaction with `ViewController`.
final class ViewModel: DataLoader {
    
    // Item sections
    enum Section: Int, CaseIterable {
        // top movies
        case top = 0
        // favorite movies
        case favorites = 1
    }
    
    // loading updater
    weak var delegate: Loader?
    
    // flag for data loading
    private(set) var isLoading = false
    
    // top movies
    private(set) var movies = [Movie]()
    // favorite movies
    private(set) var favorites = [Movie]()
    
    
    /// Loads data from server
    /// - Parameter completion: called when data finishes loading
    func loadData(completion: @escaping (ITunesRequestManager.ResponseError?) -> Void) {
        guard !isLoading else {
            // no callback intended
            return
        }
        isLoading = true
        // fetch movies
        ITunesRequestManager().getTopMovies(limit: 100) { [weak self] response in
            guard let self = self else {
                return
            }
            var error: ITunesRequestManager.ResponseError?
            switch response {
            case .failure(let serverError):
                error = serverError
            case .success(let response):
                self.movies = response?.feed?.entry ?? []
            }
            self.isLoading = false
            self.delegate?.loadingStateChanged(isLoading: self.isLoading)
            completion(error)
        }
    }
    
    func numberOfSections() -> Int {
        // one section per case
        return Section.allCases.count
    }
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            assertionFailure("Not handled")
            return 0
        }
        // leave at least one item to allow dragging between sections otherwise itwon't work
        switch section {
        case .top: return max(movies.count, 1)
        case .favorites: return max(favorites.count, 1)
        }
    }
    
    func movies(for section: Section) -> [Movie] {
        switch section {
        case .top: return movies
        case .favorites: return favorites
        }
    }
    
    func titleForItem(at indexPath: IndexPath) -> String? {
        guard let movie = movieAt(indexPath: indexPath) else {
            return nil
        }
        // use movie name for title
        return movie.name?.label
    }
    
    func imageForItem(at indexPath: IndexPath, completion: @escaping (NSImage?) -> Void) {
        // don't load images for fake items
        guard let movie = movieAt(indexPath: indexPath) else {
            completion(nil)
            return
        }
        // load image if URL exists
        if let url = movie.image?.last?.label {
            ImageDownloadManager.shared.downloadImage(for: url) { response in
                switch response {
                case .failure(_):
                    completion(nil)
                case .success(let image):
                    completion(image)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    func headerTitle(for indexPath: IndexPath) -> String? {
        guard let section = Section(rawValue: indexPath.section) else {
            assertionFailure("Not handled")
            return nil
        }
        switch section {
        case .top: return "Top movies"
        case .favorites: return "Favorite movies (Drag movies here)"
        }
    }
    
    func movieAt(indexPath: IndexPath) -> Movie? {
        guard let section = Section(rawValue: indexPath.section) else {
            assertionFailure("Not handled")
            return nil
        }
        // load movies for specified section
        let movies = movies(for: section)
        guard !movies.isEmpty else {
            return nil
        }
        return movies[indexPath.item]
    }
    
    func move(movie: Movie, from: IndexPath, to: IndexPath) -> Bool {
        // check movie exists before moving
        guard let fromSection = Section(rawValue: from.section),
              let toSection = Section(rawValue: to.section),
              movies(for: fromSection).contains(movie) else {
                  return false
              }
            
        // remove movie from initial section
        switch fromSection {
        case .top:
            movies.remove(at: from.item)
        case .favorites:
            favorites.remove(at: from.item)
        }
        
        // move movie to new section
        switch toSection {
        case .top:
            // add as last element if index is bigger than item count
            let newIndex = to.item > movies.count ? movies.count : to.item
            movies.insert(movie, at: newIndex)
        case .favorites:
            // add as last element if index is bigger than item count
            let newIndex = to.item > favorites.count ? favorites.count : to.item
            favorites.insert(movie, at: newIndex)
        }
        return true
    }
}
