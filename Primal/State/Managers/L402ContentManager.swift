//
//  L402ContentManager.swift
//  Primal
//
//  Manages L402 gated premium content: tracks unlocked posts, handles payment flow,
//  and caches authorization tokens for re-access.
//

import Foundation
import Combine
import UIKit

struct L402Gate: Hashable {
    let url: String
    let priceSats: Int
    let description: String?
}

struct L402Authorization {
    let macaroon: String
    let preimage: String
    let unlockedAt: Date
}

final class L402ContentManager {
    static let instance = L402ContentManager()

    /// Map of post ID -> authorization for unlocked content
    private var authorizations: [String: L402Authorization] = [:]

    /// Posts currently being unlocked (payment in flight)
    private var unlockingPosts: Set<String> = []

    /// Publisher for unlock state changes
    let unlockStateChanged = PassthroughSubject<String, Never>()

    func isUnlocked(_ postId: String) -> Bool {
        authorizations[postId] != nil
    }

    func isUnlocking(_ postId: String) -> Bool {
        unlockingPosts.contains(postId)
    }

    func authorization(for postId: String) -> L402Authorization? {
        authorizations[postId]
    }

    /// Parse L402 gate info from a post's tags.
    /// Tag format: ["l402", "<url>", "<price_sats>", "<optional_description>"]
    static func parseGate(from tags: [[String]]) -> L402Gate? {
        guard let tag = tags.first(where: { $0.first == "l402" }),
              tag.count >= 3,
              let priceSats = Int(tag[2])
        else { return nil }

        return L402Gate(
            url: tag[1],
            priceSats: priceSats,
            description: tag[safe: 3]
        )
    }

    /// Unlock L402 gated content for a post.
    /// Fetches the L402 URL, pays the invoice, retries with auth, and caches the result.
    func unlock(post: ParsedContent, gate: L402Gate, completion: @escaping (Result<Data, Error>) -> Void) {
        let postId = post.post.id

        guard !unlockingPosts.contains(postId) else { return }
        unlockingPosts.insert(postId)
        unlockStateChanged.send(postId)

        Task {
            do {
                guard let url = URL(string: gate.url) else {
                    throw L402Error.invalidResponse
                }

                let (data, response) = try await L402Client.shared.access(url)

                // Extract the authorization from the request header we used
                // The L402Client already handled payment internally
                // We store a synthetic authorization for cache tracking
                await MainActor.run {
                    self.authorizations[postId] = L402Authorization(
                        macaroon: "cached",
                        preimage: "cached",
                        unlockedAt: Date()
                    )
                    self.unlockingPosts.remove(postId)
                    self.unlockStateChanged.send(postId)
                    completion(.success(data))
                }
            } catch {
                await MainActor.run {
                    self.unlockingPosts.remove(postId)
                    self.unlockStateChanged.send(postId)
                    completion(.failure(error))
                }
            }
        }
    }
}
