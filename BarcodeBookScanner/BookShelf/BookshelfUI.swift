
//
//  DropDownInBookShelf.swift
//
//
//  Created by CarlJohan on 09/07/2017.
//
//

import Foundation
import UIKit
import AZDropdownMenu
import CoreData

extension BookShelfCV {
    
    
    override func viewDidLayoutSubviews() {
        
        let textViewContentSize = emptyBookshelfTextView.sizeThatFits(emptyBookshelfTextView.bounds.size)
        
        NSLayoutConstraint(item: emptyBookshelfTextView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: emptyBookshelfTextView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.8, constant: 0).isActive = true
        NSLayoutConstraint(item: emptyBookshelfTextView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: textViewContentSize.width).isActive = true
        NSLayoutConstraint(item: emptyBookshelfTextView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: textViewContentSize.height).isActive = true
        
        NSLayoutConstraint(item: emptyBookshelfScannerImage, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: emptyBookshelfScannerImage, attribute: .top, relatedBy: .equal, toItem: emptyBookshelfTextView, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
    }
    
    
    func showDropdown() {
        dropDownView?.showMenuFromRect(CGRect(x: 0, y: 70, width: 0, height: 0))
        if self.dropDownView!.isDescendant(of: collectionView) { self.dropDownView?.hideMenu() }
    }
    
    
    
    func setupEmptyBookshelfUIView() {
        
        // Setup of the emptyBookshelfTextView
        emptyBookshelfTextView.isUserInteractionEnabled = false
        emptyBookshelfTextView.font = UIFont(name: "IowanOldStyle-Roman", size: 21)
        emptyBookshelfTextView.text = "Your bookshelf is empty! \nScan some books!"
        emptyBookshelfTextView.textAlignment = .center
        emptyBookshelfTextView.translatesAutoresizingMaskIntoConstraints = false
        emptyBookshelfTextView.alpha = 0
        
        emptyBookshelfScannerImage.alpha = 0
        emptyBookshelfScannerImage.translatesAutoresizingMaskIntoConstraints = false
        emptyBookshelfScannerImage.image = UIImage(named: "MediumScannerIcon")!
        
        collectionView.addSubview(emptyBookshelfTextView)
        collectionView.addSubview(emptyBookshelfScannerImage)
        
    }
    
    func removeBookFromBookshelf() {
        
        
    }
    
    func setupNavBarItem() {
        
        // Setup of the navigation bar
        let screenSize: CGRect = UIScreen.main.bounds
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 64))
        
        
        let sortButton = UIBarButtonItem(image: UIImage(named: "FilterIcon"), style: .plain, target: self, action: #selector(showDropdown))
        
        navItem.rightBarButtonItem = sortButton
        navItem.leftBarButtonItem = editButtonItem
        
        
        navBar.setItems([navItem], animated: false)
        view.addSubview(navBar)
    }
    
    func setupDropDownView() {
    
        // Setup of the DropDownView
        dropDownView = AZDropdownMenu(titles: titles)
        dropDownView!.itemAlignment = .right
        dropDownView!.cellTapHandler = { [weak self] (indexPath: IndexPath) -> Void in
            
            self?.booksInCV.removeAll()
            
            if indexPath[1] < (self?.titles.count)! - 1 {
                self?.loadBookshelf(bookshelfID: (self?.bookshelfs[indexPath[1]].id)!)
                self?.navItem.title = self?.titles[indexPath[1]]
                
            } else if indexPath[1] == (self?.titles.count)! - 1 {
                self?.coreDataArray()
                self?.navItem.title = self?.titles[indexPath[1]]
            }
        }

    
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        switch editing {
        case true : break
        case false:
            
            let bookshelfID = titles.index(of: navItem.title!)
            
            let index = bookshelfs.index(where: { (bookshelf) -> Bool in
                bookshelf.title == navItem.title
            })
            print("Clicked index:", index!)
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems
            
//            if bookshelfID! < self.titles.count - 1 {
            if index! < self.bookshelfs.count {
                
                // We reverse it to make sure the deleted item's indexPath is less than the previous item
                for indexPath in selectedIndexPaths!.reversed() {
                    let book = collectionView.cellForItem(at: indexPath) as! BookCell
                    let bookID = book.associatedConvenienceBook?.bookID
                    
                    collectionView.performBatchUpdates({
                        self.collectionView.deleteItems(at: [indexPath])
                        self.booksInCV.remove(at: indexPath[1])
                    })
                    
                    GoogleBooksClient.sharedInstance.postToBookshelf(BookshelfID: bookshelfID!, bookID: bookID!, add: false)
                    
                }
            } else if index == self.titles.count {
                
                for indexPath in selectedIndexPaths!.reversed() {
                    
                    self.collectionView.performBatchUpdates({
                        self.collectionView.deleteItems(at: [indexPath])
                        self.appDelegate.stack.context.delete(self.downloadedBookInCV[indexPath[1]])
                    }) { (true) in
                        do { try self.appDelegate.stack.saveContext()
                        } catch { print("Failed to save: \(error)") }
                    }
                }
            }            
        }
    }
    
    
    func coreDataArray() {
        
        for fetchedObject in downloadedBookInCV {
            var convenienceBook = ConvenienceBook()
            
            convenienceBook.title = fetchedObject.bookTitle!
            convenienceBook.smallestThumbnail = UIImage(data: fetchedObject.bookCoverAsData! as Data)
            convenienceBook.largestThumbnail = UIImage(data: fetchedObject.bookCoverAsData! as Data)
            convenienceBook.isbn13 = String(fetchedObject.isbn13)
            convenienceBook.isThumbnailAvailable = true
            
            booksInCV.append(convenienceBook)
        }
        collectionView.reloadData()
        
    }
    
}
