//
//  CollectionViewItem.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Cocoa

class CollectionViewItem: NSCollectionViewItem {

    @IBOutlet weak var posterImageView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.isOpaque = false
        view.layer?.backgroundColor = .clear
        posterImageView.wantsLayer = true
        let shadow = NSShadow()
        // change shadow color based on Dark mode or normal
        shadow.shadowColor = NSAppearance.current.name == .aqua ? .black : .highlightColor
        shadow.shadowBlurRadius = 3
        posterImageView.shadow = shadow
    }
    
    static let identifier = "CollectionViewItem"
}
