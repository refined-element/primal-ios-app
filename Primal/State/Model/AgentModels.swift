//
//  AgentModels.swift
//  Primal
//
//  Created by NostrWolfe on 14.3.26..
//

import Foundation

// MARK: - AgentPricing

struct AgentPricing {
    let amount: Int
    let unit: String
    let model: String

    /// Parse from a tag with format: ["price", "50", "sats", "per-request"]
    static func parse(from tag: [String]) -> AgentPricing? {
        guard
            tag.first == "price",
            let amountStr = tag[safe: 1],
            let amount = Int(amountStr),
            let unit = tag[safe: 2],
            let model = tag[safe: 3]
        else { return nil }

        return AgentPricing(amount: amount, unit: unit, model: model)
    }
}

// MARK: - AgentCapability

struct AgentCapability {
    let id: String
    let pubkey: String
    let createdAt: Int64
    let serviceId: String
    let categories: [String]
    let content: String
    let pricing: [AgentPricing]
    let l402Endpoint: String?
    let apiEndpoint: String?
    let apiMethod: String?
    let schemaURL: String?
    let capacity: String?
    let uptime: Double?
    let hashtags: [String]
    let negotiable: Bool
    let minPriceSats: Int?

    static func parse(from tags: [[String]], content: String, id: String, pubkey: String, createdAt: Int64) -> AgentCapability? {
        guard let serviceId = tags.tagValue("d") else { return nil }

        let categories = tags.tagValues("s")
        let pricing = tags.allTags("price").compactMap { AgentPricing.parse(from: $0) }
        let l402Endpoint = tags.tagValue("l402")

        let endpointTag = tags.firstTag("endpoint")
        let apiEndpoint = endpointTag?[safe: 1]
        let apiMethod = endpointTag?[safe: 2]

        let schemaURL = tags.tagValue("schema")

        let capacityTag = tags.firstTag("capacity")
        let capacity: String? = {
            guard let capacityTag = capacityTag, capacityTag.count > 1 else { return nil }
            return capacityTag.dropFirst().joined(separator: " ")
        }()

        let uptime: Double? = {
            guard let uptimeStr = tags.tagValue("uptime") else { return nil }
            return Double(uptimeStr)
        }()

        let hashtags = tags.tagValues("t")

        let negotiableTag = tags.firstTag("negotiable")
        let negotiable: Bool
        let minPriceSats: Int?
        if let negValue = negotiableTag?[safe: 1] {
            if negValue == "false" {
                negotiable = false
                minPriceSats = nil
            } else if negValue == "floor", let floorStr = negotiableTag?[safe: 2], let floor = Int(floorStr) {
                negotiable = true
                minPriceSats = floor
            } else {
                negotiable = true
                minPriceSats = nil
            }
        } else {
            negotiable = true
            minPriceSats = nil
        }

        return AgentCapability(
            id: id,
            pubkey: pubkey,
            createdAt: createdAt,
            serviceId: serviceId,
            categories: categories,
            content: content,
            pricing: pricing,
            l402Endpoint: l402Endpoint,
            apiEndpoint: apiEndpoint,
            apiMethod: apiMethod,
            schemaURL: schemaURL,
            capacity: capacity,
            uptime: uptime,
            hashtags: hashtags,
            negotiable: negotiable,
            minPriceSats: minPriceSats
        )
    }
}

// MARK: - AgentServiceRequest

struct AgentServiceRequest {
    let id: String
    let pubkey: String
    let createdAt: Int64
    let requestId: String
    let categories: [String]
    let content: String
    let budgetSats: Int?
    let deadline: Int64?
    let hashtags: [String]

    static func parse(from tags: [[String]], content: String, id: String, pubkey: String, createdAt: Int64) -> AgentServiceRequest? {
        guard let requestId = tags.tagValue("d") else { return nil }

        let categories = tags.tagValues("s")

        let budgetSats: Int? = {
            guard let budgetStr = tags.tagValue("budget") else { return nil }
            return Int(budgetStr)
        }()

        let deadline: Int64? = {
            guard let deadlineStr = tags.tagValue("deadline") else { return nil }
            return Int64(deadlineStr)
        }()

        let hashtags = tags.tagValues("t")

        return AgentServiceRequest(
            id: id,
            pubkey: pubkey,
            createdAt: createdAt,
            requestId: requestId,
            categories: categories,
            content: content,
            budgetSats: budgetSats,
            deadline: deadline,
            hashtags: hashtags
        )
    }
}

// MARK: - ASAStatus

enum ASAStatus: String {
    case proposed, active, completed, disputed, expired
}

// MARK: - ASATerm

struct ASATerm {
    let type: String
    let value: String
    let unit: String

    /// Parse from a tag with format: ["terms", "per-request", "50", "sats"]
    static func parse(from tag: [String]) -> ASATerm? {
        guard
            tag.first == "terms",
            let type = tag[safe: 1],
            let value = tag[safe: 2],
            let unit = tag[safe: 3]
        else { return nil }

        return ASATerm(type: type, value: value, unit: unit)
    }
}

// MARK: - AgentServiceAgreement

struct AgentServiceAgreement {
    let id: String
    let pubkey: String
    let createdAt: Int64
    let agreementId: String
    let providerPubkey: String?
    let requesterPubkey: String?
    let capabilityEventId: String?
    let l402Endpoint: String?
    let terms: [ASATerm]
    let status: ASAStatus
    let expiry: Int64?
    let content: String

    static func parse(from tags: [[String]], content: String, id: String, pubkey: String, createdAt: Int64) -> AgentServiceAgreement? {
        guard let agreementId = tags.tagValue("d") else { return nil }

        guard
            let statusStr = tags.tagValue("status"),
            let status = ASAStatus(rawValue: statusStr)
        else { return nil }

        let pTags = tags.allTags("p")
        let providerPubkey = pTags.first(where: { $0[safe: 3] == "provider" })?[safe: 1]
        let requesterPubkey = pTags.first(where: { $0[safe: 3] == "requester" })?[safe: 1]

        let eTags = tags.allTags("e")
        let capabilityEventId = eTags.first(where: { $0[safe: 3] == "capability" })?[safe: 1]

        let l402Endpoint = tags.tagValue("l402")
        let terms = tags.allTags("terms").compactMap { ASATerm.parse(from: $0) }

        let expiry: Int64? = {
            guard let expiryStr = tags.tagValue("expiry") else { return nil }
            return Int64(expiryStr)
        }()

        return AgentServiceAgreement(
            id: id,
            pubkey: pubkey,
            createdAt: createdAt,
            agreementId: agreementId,
            providerPubkey: providerPubkey,
            requesterPubkey: requesterPubkey,
            capabilityEventId: capabilityEventId,
            l402Endpoint: l402Endpoint,
            terms: terms,
            status: status,
            expiry: expiry,
            content: content
        )
    }
}

// MARK: - AgentAttestation

struct AgentAttestation {
    let id: String
    let pubkey: String
    let createdAt: Int64
    let attestationId: String
    let subjectPubkey: String
    let agreementId: String
    let rating: Int
    let content: String
    let proof: String?

    static func parse(from tags: [[String]], content: String, id: String, pubkey: String, createdAt: Int64) -> AgentAttestation? {
        guard let attestationId = tags.tagValue("d") else { return nil }

        let pTags = tags.allTags("p")
        let subjectPubkey = pTags.first(where: { $0[safe: 3] == "subject" })?[safe: 1]
            ?? pTags.first?[safe: 1]

        let eTags = tags.allTags("e")
        let agreementId = eTags.first(where: { $0[safe: 3] == "agreement" })?[safe: 1]
            ?? eTags.first?[safe: 1]

        let rating: Int = {
            guard let ratingStr = tags.tagValue("rating") else { return 0 }
            return Int(ratingStr) ?? 0
        }()

        let proof = tags.tagValue("proof")

        guard let subjectPubkey = subjectPubkey else { return nil }

        return AgentAttestation(
            id: id,
            pubkey: pubkey,
            createdAt: createdAt,
            attestationId: attestationId,
            subjectPubkey: subjectPubkey,
            agreementId: agreementId ?? "",
            rating: rating,
            content: content,
            proof: proof
        )
    }
}

// MARK: - ASANegotiationMessage

struct ASANegotiationMessage: Codable {
    let type: String
    let capability: String?
    let params: [String: String]?
    let budget: Int?
    let deadline: Int64?
    let price: Int?
    let priceModel: String?
    let l402URL: String?
    let estimatedTime: Int?
    let terms: [String: String]?
    let offerEvent: String?
    let asa: String?
    let result: String?
    let requestsMade: Int?
    let totalPaid: Int?
    let reason: String?
}
