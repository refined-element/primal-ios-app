//
//  ASAManager.swift
//  Primal
//
//  Manages Agent Service Agreements: discovery of agent capabilities,
//  publishing requests and agreements, negotiation via encrypted DMs,
//  and settlement via L402.
//

import Foundation
import Combine
import GenericJSON

extension String {
    static let agentDemoModeKey = "agentDemoModeKey"
}

final class ASAManager {
    static let instance = ASAManager()

    private var cancellables: Set<AnyCancellable> = []
    private let agentSubscriptionId = "agent-asa-sub"

    private init() {
        // Relay subscription is now lazy — call subscribeToAgentEvents()
        // explicitly when the user opens the Agent feed.
    }

    /// Demo mode: when enabled, demo agent posts are injected into feeds.
    static var demoModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: .agentDemoModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: .agentDemoModeKey) }
    }

    /// Get demo posts for injection into feeds.
    static func demoPosts() -> [ParsedContent] {
        guard demoModeEnabled else { return [] }
        return AgentDemoData.generateDemoPosts()
    }

    // MARK: - Published State

    @Published var discoveredCapabilities: [AgentCapability] = []
    @Published var activeAgreements: [AgentServiceAgreement] = []
    @Published var pendingRequests: [AgentServiceRequest] = []
    @Published var attestations: [AgentAttestation] = []

    // MARK: - Discovery

    /// Query relays for agent capabilities matching the given categories/hashtags.
    /// Sends a REQ directly to agent relays (not the Primal cache server).
    func queryCapabilities(categories: [String]? = nil, hashtags: [String]? = nil, limit: Int = 20) {
        // Build the Nostr filter for agent event kinds
        var filterJSON: [String: JSON] = [
            "kinds": .array([
                .number(Double(NostrKind.agentCapability.rawValue)),
                .number(Double(NostrKind.agentServiceRequest.rawValue)),
                .number(Double(NostrKind.agentServiceAgreement.rawValue)),
                .number(Double(NostrKind.agentAttestation.rawValue))
            ]),
            "limit": .number(Double(limit))
        ]

        if let categories = categories, !categories.isEmpty {
            filterJSON["#s"] = .array(categories.map { .string($0) })
        }
        if let hashtags = hashtags, !hashtags.isEmpty {
            filterJSON["#t"] = .array(hashtags.map { .string($0) })
        }

        let subscriptionId = "agent-query-\(Int(Date().timeIntervalSince1970))"
        let filter: JSON = .object(filterJSON)

        RelaysPostbox.instance.subscribeAgentREQ(subscriptionId: subscriptionId, filters: [filter]) { [weak self] eventJSON, relay in
            guard let dict = eventJSON.objectValue else { return }
            let event = NostrObject.fromJSONDict(dict)
            self?.processEvent(event)
        }
    }

    /// Subscribe to agent event kinds from the relay pool.
    /// Opens a persistent REQ subscription on agent relays to receive
    /// incoming events in real-time.
    func subscribeToAgentEvents() {
        // Build a persistent subscription filter for all agent event kinds
        let filter: JSON = .object([
            "kinds": .array([
                .number(Double(NostrKind.agentCapability.rawValue)),
                .number(Double(NostrKind.agentServiceRequest.rawValue)),
                .number(Double(NostrKind.agentServiceAgreement.rawValue)),
                .number(Double(NostrKind.agentAttestation.rawValue))
            ]),
            "limit": .number(50)
        ])

        RelaysPostbox.instance.subscribeAgentREQ(subscriptionId: agentSubscriptionId, filters: [filter]) { [weak self] eventJSON, relay in
            guard let dict = eventJSON.objectValue else { return }
            let event = NostrObject.fromJSONDict(dict)
            self?.processEvent(event)
        }
    }

    /// Process a raw Nostr event (called when events arrive from relays).
    func processEvent(_ event: NostrObject) {
        switch event.kind {
        case NostrKind.agentCapability.rawValue:
            if let capability = AgentCapability.parse(from: event.tags, content: event.content, id: event.id, pubkey: event.pubkey, createdAt: event.created_at) {
                // Replace existing capability from same pubkey+serviceId, or append
                if let index = discoveredCapabilities.firstIndex(where: { $0.pubkey == capability.pubkey && $0.serviceId == capability.serviceId }) {
                    discoveredCapabilities[index] = capability
                } else {
                    discoveredCapabilities.append(capability)
                }
            }
        case NostrKind.agentServiceRequest.rawValue:
            if let request = AgentServiceRequest.parse(from: event.tags, content: event.content, id: event.id, pubkey: event.pubkey, createdAt: event.created_at) {
                if let index = pendingRequests.firstIndex(where: { $0.id == request.id }) {
                    pendingRequests[index] = request
                } else {
                    pendingRequests.append(request)
                }
            }
        case NostrKind.agentServiceAgreement.rawValue:
            if let agreement = AgentServiceAgreement.parse(from: event.tags, content: event.content, id: event.id, pubkey: event.pubkey, createdAt: event.created_at) {
                if let index = activeAgreements.firstIndex(where: { $0.agreementId == agreement.agreementId }) {
                    activeAgreements[index] = agreement
                } else {
                    activeAgreements.append(agreement)
                }
            }
        case NostrKind.agentAttestation.rawValue:
            if let attestation = AgentAttestation.parse(from: event.tags, content: event.content, id: event.id, pubkey: event.pubkey, createdAt: event.created_at) {
                if let index = attestations.firstIndex(where: { $0.attestationId == attestation.attestationId && $0.pubkey == attestation.pubkey }) {
                    attestations[index] = attestation
                } else {
                    attestations.append(attestation)
                }
            }
        default:
            break
        }
    }

    // MARK: - Reputation

    /// Compute average reputation score for an agent from attestations.
    func getReputationScore(for pubkey: String) -> Double? {
        let relevant = attestations.filter { $0.subjectPubkey == pubkey && $0.rating >= 1 && $0.rating <= 5 }
        guard !relevant.isEmpty else { return nil }
        let total = relevant.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(relevant.count)
    }

    /// Returns a formatted reputation display string, e.g. "★ 4.8 (12 reviews)".
    /// Returns nil if no attestations exist for the given pubkey.
    func getReputationDisplay(for pubkey: String) -> String? {
        let relevant = attestations.filter { $0.subjectPubkey == pubkey && $0.rating >= 1 && $0.rating <= 5 }
        guard !relevant.isEmpty else { return nil }
        let total = relevant.reduce(0) { $0 + $1.rating }
        let average = Double(total) / Double(relevant.count)
        let count = relevant.count
        let noun = count == 1 ? "review" : "reviews"
        return String(format: "\u{2605} %.1f (%d %@)", average, count, noun)
    }

    // MARK: - Publishing

    /// Publish an agent capability advertisement.
    func publishCapability(
        serviceId: String,
        categories: [String],
        content: String,
        pricing: [AgentPricing],
        l402Endpoint: String? = nil,
        apiEndpoint: String? = nil,
        apiMethod: String? = nil,
        schemaURL: String? = nil,
        capacity: String? = nil,
        uptime: Double? = nil,
        hashtags: [String] = []
    ) -> NostrObject? {
        let event = NostrObject.agentCapability(
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
            hashtags: hashtags
        )
        if let event = event {
            RelaysPostbox.instance.requestAgentEvent(event, successHandler: { _ in
                print("[ASAManager] Published event kind \(event.kind) to relays")
            }, errorHandler: {
                print("[ASAManager] Failed to publish event kind \(event.kind)")
            })
        }
        return event
    }

    /// Publish a service request.
    func publishServiceRequest(
        requestId: String,
        categories: [String],
        content: String,
        budgetSats: Int? = nil,
        deadline: Int64? = nil,
        hashtags: [String] = []
    ) -> NostrObject? {
        let event = NostrObject.agentServiceRequest(
            requestId: requestId,
            categories: categories,
            content: content,
            budgetSats: budgetSats,
            deadline: deadline,
            hashtags: hashtags
        )
        if let event = event {
            RelaysPostbox.instance.requestAgentEvent(event, successHandler: { _ in
                print("[ASAManager] Published event kind \(event.kind) to relays")
            }, errorHandler: {
                print("[ASAManager] Failed to publish event kind \(event.kind)")
            })
        }
        return event
    }

    /// Publish a service agreement.
    func publishAgreement(
        agreementId: String,
        providerPubkey: String,
        requesterPubkey: String,
        capabilityEventId: String? = nil,
        l402Endpoint: String? = nil,
        terms: [ASATerm],
        status: ASAStatus = .proposed,
        expiry: Int64? = nil,
        content: String
    ) -> NostrObject? {
        let event = NostrObject.agentServiceAgreement(
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
        if let event = event {
            RelaysPostbox.instance.requestAgentEvent(event, successHandler: { _ in
                print("[ASAManager] Published event kind \(event.kind) to relays")
            }, errorHandler: {
                print("[ASAManager] Failed to publish event kind \(event.kind)")
            })
        }
        return event
    }

    /// Publish an attestation/review for an agent.
    func publishAttestation(
        subjectPubkey: String,
        agreementId: String,
        rating: Int,
        content: String,
        proof: String? = nil
    ) -> NostrObject? {
        let attestationId = "att-\(agreementId.prefix(16))-\(Int(Date().timeIntervalSince1970))"

        let event = NostrObject.agentAttestation(
            attestationId: attestationId,
            subjectPubkey: subjectPubkey,
            agreementId: agreementId,
            rating: rating,
            content: content,
            proof: proof
        )
        if let event = event {
            RelaysPostbox.instance.requestAgentEvent(event, successHandler: { _ in
                print("[ASAManager] Published attestation kind \(event.kind) to relays")
            }, errorHandler: {
                print("[ASAManager] Failed to publish attestation kind \(event.kind)")
            })
        }
        return event
    }

    /// Update an agreement's status by publishing a new replaceable event.
    func updateAgreementStatus(agreementId: String, newStatus: ASAStatus) {
        guard let existing = activeAgreements.first(where: { $0.agreementId == agreementId }) else { return }

        _ = publishAgreement(
            agreementId: existing.agreementId,
            providerPubkey: existing.providerPubkey ?? "",
            requesterPubkey: existing.requesterPubkey ?? "",
            capabilityEventId: existing.capabilityEventId,
            l402Endpoint: existing.l402Endpoint,
            terms: existing.terms,
            status: newStatus,
            expiry: existing.expiry,
            content: existing.content
        )
    }

    // MARK: - Negotiation

    /// Send a negotiation message to another agent via encrypted DM.
    func sendNegotiationMessage(_ message: ASANegotiationMessage, to pubkey: String) -> NostrObject? {
        guard let data = try? JSONEncoder().encode(message),
              let jsonString = String(data: data, encoding: .utf8) else { return nil }

        let event = NostrObject.message(jsonString, recipientPubkey: pubkey)
        if let event = event {
            RelaysPostbox.instance.requestAgentEvent(event, successHandler: { _ in
                print("[ASAManager] Published negotiation DM to \(pubkey.prefix(16))...")
            }, errorHandler: {
                print("[ASAManager] Failed to publish negotiation DM to \(pubkey.prefix(16))...")
            })
        }
        return event
    }

    /// Parse a negotiation message from a DM's decrypted content.
    func parseNegotiationMessage(from content: String) -> ASANegotiationMessage? {
        guard let data = content.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ASANegotiationMessage.self, from: data)
    }

    // MARK: - Settlement

    /// Execute a service via L402, delegating to L402Client for the payment flow.
    func executeService(agreement: AgentServiceAgreement) async throws -> (Data, HTTPURLResponse) {
        guard let endpoint = agreement.l402Endpoint,
              let url = URL(string: endpoint) else {
            throw L402Error.invalidResponse
        }

        let result = try await L402Client.shared.access(url)

        // Update agreement status on completion
        await MainActor.run {
            updateAgreementStatus(agreementId: agreement.agreementId, newStatus: .completed)
        }

        return result
    }
}
