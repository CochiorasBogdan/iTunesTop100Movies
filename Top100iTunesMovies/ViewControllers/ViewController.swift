//
//  ViewController.swift
//  Top100iTunesMovies
//
//  Created by Cochioras Bogdan Ionut on 4/4/22.
//

import Cocoa

final class ViewController: NSViewController, Loader {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var spinnerView: NSProgressIndicator!
    
    private lazy var viewModel: ViewModel = {
        let temp = ViewModel()
        temp.delegate = self
        return temp
    }()
    
    // indexes of dragged items
    private var draggingIndexPaths: Set<IndexPath> = []
    // drgged item
    private var draggingItem: NSCollectionViewItem?
    
    private func configureCollection() {
        collectionView.backgroundColors = [.clear]
        // register views
        let nib = NSNib(nibNamed: HeaderView.identifier, bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: .init(rawValue: HeaderView.identifier))
        
        // setup collection layout
        collectionView.collectionViewLayout = NSCollectionViewCompositionalLayout { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
            // size of collection item
            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(150),
                                                  heightDimension: .absolute(150))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize,
                                                         subitem: item,
                                                         count: 1)
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            // header size
            let supplementarySize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                           heightDimension: .absolute(44))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: supplementarySize,
                                                                     elementKind: HeaderView.identifier,
                                                                     alignment: .topLeading)
            section.boundarySupplementaryItems = [header]
            return section
        }
        
        // register for drag and drop
        collectionView.registerForDraggedTypes(
            NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        collectionView.registerForDraggedTypes([
            .string
        ])
        collectionView.setDraggingSourceOperationMask(.move, forLocal: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollection()
        
        // load data
        viewModel.loadData { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.collectionView.reloadData()
                if let error = error {
                    let alert: NSAlert = {
                        let temp = NSAlert()
                        temp.messageText = error.message
                        temp.alertStyle = .critical
                        temp.addButton(withTitle: "OK")
                        return temp
                    }()
                    alert.runModal()
                }
            }
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // MARK: - Loader methods
    
    func loadingStateChanged(isLoading: Bool) {
        // update spinner
        if isLoading {
            spinnerView.startAnimation(nil)
        } else {
            spinnerView.stopAnimation(nil)
        }
    }
}

/// Configure dat source.
extension ViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection(section)
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        
        guard let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: HeaderView.identifier), for: indexPath) as? HeaderView else {
            return NSView()
        }
        // configure header title
        headerView.titleLabel.stringValue = viewModel.headerTitle(for: indexPath) ?? ""
        return headerView
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        // create collection item
        return collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: CollectionViewItem.identifier), for: indexPath)
    }
}

/// Configure delegate.
extension ViewController: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        
        guard let item = item as? CollectionViewItem else {
            return
        }
        // configure item title
        item.titleLabel.stringValue = viewModel.titleForItem(at: indexPath) ?? ""
        
        // set item image
        viewModel.imageForItem(at: indexPath) { [weak item] image in
            DispatchQueue.main.async { [weak item] in
                item?.posterImageView.image = image
            }
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
        draggingIndexPaths = indexPaths
        
        if let indexPath = draggingIndexPaths.first,
           let item = collectionView.item(at: indexPath) {
            // preserve dragged item
            draggingItem = item
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
        // reset dragging tracking
        draggingIndexPaths = []
        draggingItem = nil
    }
    
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        guard let movie = viewModel.movieAt(indexPath: indexPath) else {
            return nil
        }
        // preserve dragging item id
        let pb = NSPasteboardItem()
        pb.setString(movie.id.attributes.id, forType: .string)
        return pb
    }
    
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, index: Int, dropOperation: NSCollectionView.DropOperation) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        let proposedDropIndexPath = proposedDropIndexPath.pointee
        
        if let draggingItem = draggingItem,
           let currentIndexPath = collectionView.indexPath(for: draggingItem),
           currentIndexPath != proposedDropIndexPath as IndexPath {
            
            //             create gap for item insertion, caused bugs so commented method
            //            collectionView.animator().moveItem(at: currentIndexPath,
            //                                               to: proposedDropIndexPath as IndexPath)
        }
        return .move
    }
    
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        if let fromIndexPath = draggingIndexPaths.first {
            guard let movie = viewModel.movieAt(indexPath: fromIndexPath) else {
                assertionFailure("Should find movie")
                return false
            }
            // try to move item
            guard viewModel.move(movie: movie, from: fromIndexPath, to: indexPath) else {
                return false
            }
            // refresh after move
            collectionView.reloadData()
        }
        return true
    }
}
