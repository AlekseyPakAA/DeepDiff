//
//  UICollectionView+Extensions.swift
//  DeepDiff
//
//  Created by Khoa Pham.
//  Copyright © 2018 Khoa Pham. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit

typealias CollectionView = UICollectionView

#elseif os(macOS)
import Cocoa

typealias CollectionView = NSCollectionView

extension CollectionView {
    func performBatchUpdates(_ updates: (() -> Void)?,
                             completion: ((Bool) -> Void)? = nil) {
        performBatchUpdates(updates, completionHandler: completion)
    }

    func deleteItems(at indexPaths: [IndexPath]) {
        self.deleteItems(at: Set<IndexPath>(indexPaths))
    }

    func insertItems(at indexPaths: [IndexPath]) {
        self.insertItems(at: Set<IndexPath>(indexPaths))
    }

    func reloadItems(at indexPaths: [IndexPath]) {
        self.reloadItems(at: Set<IndexPath>(indexPaths))
    }
}

#endif

public extension CollectionView {

  /// Animate reload in a batch update
  ///
  /// - Parameters:
  ///   - changes: The changes from diff
  ///   - section: The section that all calculated IndexPath belong
  ///   - updateData: Update your data source model
  ///   - completion: Called when operation completes
  func reload<T: DiffAware>(
    changes: [Change<T>],
    section: Int = 0,
    updateData: @escaping () -> Void,
    completion: ((Bool) -> Void)? = nil) {
    
    let changesWithIndexPath = IndexPathConverter().convert(changes: changes, section: section)
    
    performBatchUpdates({
      updateData()
      self.insideUpdate(changesWithIndexPath: changesWithIndexPath)
    }, completion: { finished in
      completion?(finished)
    })

    // reloadRows needs to be called outside the batch
    outsideUpdate(changesWithIndexPath: changesWithIndexPath)
  }
  
  // MARK: - Helper
  
  private func insideUpdate(changesWithIndexPath: ChangeWithIndexPath) {
    changesWithIndexPath.deletes.executeIfPresent {
      deleteItems(at: $0)
    }

    changesWithIndexPath.inserts.executeIfPresent {
      insertItems(at: $0)
    }
    
    changesWithIndexPath.moves.executeIfPresent {
      $0.forEach { move in
        moveItem(at: move.from, to: move.to)
      }
    }
  }

  private func outsideUpdate(changesWithIndexPath: ChangeWithIndexPath) {
    changesWithIndexPath.replaces.executeIfPresent {
      self.reloadItems(at: $0)
    }
  }
}
