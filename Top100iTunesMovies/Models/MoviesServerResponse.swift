//
//  MoviesServerResponse.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Foundation


/// Wrapper for server response.
struct MoviesServerResponse: Decodable {
    struct Feed: Decodable {
        let entry: [Movie]?
        
        enum CodingKeys: String, CodingKey {
            case entry
        }
    }
    
    let feed: Feed?
    
    enum CodingKeys: String, CodingKey {
        case feed
    }
}
