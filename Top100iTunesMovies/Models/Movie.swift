//
//  Movie.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Foundation


/// Movies received from server.
struct Movie: Decodable {
    
    struct Name: Decodable {
        let label: String?
        
        enum CodingKeys: String, CodingKey {
            case label
        }
    }
    
    struct Image: Decodable {
        
        struct Attributes: Decodable {
            let height: String?
            
            enum CodingKeys: String, CodingKey {
                case height
            }
        }
        let label: URL?
        let attributes: Attributes?
        
        enum CodingKeys: String, CodingKey {
            case label
            case attributes
        }
    }
    
    struct Summary: Decodable {
        let label: String?
        
        enum CodingKeys: String, CodingKey {
            case label
        }
    }
    
    struct ID: Decodable {
        struct Attributes: Decodable {
            let id: String
            
            enum CodingKeys: String, CodingKey {
                case id = "im:id"
            }
        }
        
        let attributes: Attributes
        
        enum CodingKeys: String, CodingKey {
            case attributes
        }
    }
    
    let id: ID
    let name: Name?
    let image: [Image]?
    let summary: Summary?
    
    enum CodingKeys: String, CodingKey {
        case name = "im:name"
        case image = "im:image"
        case summary
        case id
    }
}

extension Movie: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.attributes.id)
    }
}

extension Movie: Equatable {
    static func ==(lhs: Movie, rhs: Movie) -> Bool {
        return lhs.id.attributes.id == rhs.id.attributes.id
    }
}
