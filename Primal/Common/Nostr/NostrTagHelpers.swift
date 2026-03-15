//
//  NostrTagHelpers.swift
//  Primal
//
//  Created by NostrWolfe on 14.3.26..
//

import Foundation

extension Array where Element == [String] {
    func firstTag(_ name: String) -> [String]? {
        first(where: { $0.first == name })
    }

    func allTags(_ name: String) -> [[String]] {
        filter { $0.first == name }
    }

    func tagValue(_ name: String) -> String? {
        firstTag(name)?[safe: 1]
    }

    func tagValues(_ name: String) -> [String] {
        allTags(name).compactMap { $0[safe: 1] }
    }
}
