//
//  Tree.swift
//  App
//
//  Created by Hadi Sharghi on 11/18/19.
//

import Foundation

public class TreeNode<T> {
    public var value: T
    
    public weak var parent: TreeNode?
    public var children = [TreeNode<T>]()
    
    public init(value: T) {
        self.value = value
    }
    
    public func addChild(_ node: TreeNode<T>) {
        children.append(node)
        node.parent = self
    }
    
    var leaves: [TreeNode<T>] {
        var leaves = [TreeNode<T>]()
        if self.children.isEmpty {
            leaves.append(self)
        } else {
            for child in self.children {
                leaves += child.leaves
            }
        }
        
        return leaves
    }
}


extension TreeNode: CustomStringConvertible {
    public var description: String {
        var s = "\(value)"
        if !children.isEmpty {
            s += " {" + children.map { $0.description }.joined(separator: ", ") + "}"
        }
        return s
    }
}

extension TreeNode where T: Equatable {
    public func search(_ value: T) -> TreeNode? {
        if value == self.value {
            return self
        }
        for child in children {
            if let found = child.search(value) {
                return found
            }
        }
        return nil
    }
}

extension TreeNode: Equatable where T: Equatable {
    public static func == (lhs: TreeNode<T>, rhs: TreeNode<T>) -> Bool {
        lhs.value == rhs.value
    }
}
