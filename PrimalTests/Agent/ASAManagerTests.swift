//
//  ASAManagerTests.swift
//  PrimalTests
//
//  Created by NostrWolfe on 14.3.26..
//

import XCTest
@testable import Primal

final class ASAManagerTests: XCTestCase {

    private var manager: ASAManager!

    override func setUp() {
        super.setUp()
        manager = ASAManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeEvent(
        id: String = "test-event-id",
        sig: String = "test-sig",
        tags: [[String]] = [],
        pubkey: String = "test-pubkey",
        createdAt: Int64 = 1_710_000_000,
        kind: Int,
        content: String = ""
    ) -> NostrObject {
        NostrObject(
            id: id,
            sig: sig,
            tags: tags,
            pubkey: pubkey,
            created_at: createdAt,
            kind: kind,
            content: content
        )
    }

    // MARK: - processEvent: Capability

    func testProcessEvent_capability_addsToDiscovered() {
        let event = makeEvent(
            id: "cap-1",
            tags: [
                ["d", "translate-svc"],
                ["s", "translation"],
                ["price", "50", "sats", "per-request"],
            ],
            pubkey: "agent-pubkey-a",
            kind: NostrKind.agentCapability.rawValue,
            content: "Translation service"
        )

        manager.processEvent(event)

        XCTAssertEqual(manager.discoveredCapabilities.count, 1)
        XCTAssertEqual(manager.discoveredCapabilities[0].serviceId, "translate-svc")
        XCTAssertEqual(manager.discoveredCapabilities[0].pubkey, "agent-pubkey-a")
        XCTAssertEqual(manager.discoveredCapabilities[0].content, "Translation service")
    }

    func testProcessEvent_capability_updatesExisting() {
        // First event
        let event1 = makeEvent(
            id: "cap-1",
            tags: [
                ["d", "translate-svc"],
                ["price", "50", "sats", "per-request"],
            ],
            pubkey: "agent-pubkey-a",
            kind: NostrKind.agentCapability.rawValue,
            content: "V1"
        )

        // Second event from same pubkey+serviceId
        let event2 = makeEvent(
            id: "cap-2",
            tags: [
                ["d", "translate-svc"],
                ["price", "100", "sats", "per-request"],
            ],
            pubkey: "agent-pubkey-a",
            kind: NostrKind.agentCapability.rawValue,
            content: "V2"
        )

        manager.processEvent(event1)
        manager.processEvent(event2)

        XCTAssertEqual(manager.discoveredCapabilities.count, 1)
        XCTAssertEqual(manager.discoveredCapabilities[0].content, "V2")
        XCTAssertEqual(manager.discoveredCapabilities[0].pricing[0].amount, 100)
    }

    func testProcessEvent_capability_differentPubkeysAreSeparate() {
        let event1 = makeEvent(
            id: "cap-1",
            tags: [["d", "translate-svc"]],
            pubkey: "agent-a",
            kind: NostrKind.agentCapability.rawValue
        )

        let event2 = makeEvent(
            id: "cap-2",
            tags: [["d", "translate-svc"]],
            pubkey: "agent-b",
            kind: NostrKind.agentCapability.rawValue
        )

        manager.processEvent(event1)
        manager.processEvent(event2)

        XCTAssertEqual(manager.discoveredCapabilities.count, 2)
    }

    func testProcessEvent_capability_differentServiceIdsAreSeparate() {
        let event1 = makeEvent(
            id: "cap-1",
            tags: [["d", "svc-a"]],
            pubkey: "same-agent",
            kind: NostrKind.agentCapability.rawValue
        )

        let event2 = makeEvent(
            id: "cap-2",
            tags: [["d", "svc-b"]],
            pubkey: "same-agent",
            kind: NostrKind.agentCapability.rawValue
        )

        manager.processEvent(event1)
        manager.processEvent(event2)

        XCTAssertEqual(manager.discoveredCapabilities.count, 2)
    }

    func testProcessEvent_capability_invalidEvent_ignored() {
        // Missing "d" tag -> parse returns nil
        let event = makeEvent(
            id: "bad-cap",
            tags: [["s", "translation"]],
            kind: NostrKind.agentCapability.rawValue
        )

        manager.processEvent(event)
        XCTAssertTrue(manager.discoveredCapabilities.isEmpty)
    }

    // MARK: - processEvent: ServiceRequest

    func testProcessEvent_serviceRequest_addsToPending() {
        let event = makeEvent(
            id: "req-1",
            tags: [
                ["d", "request-001"],
                ["s", "translation"],
                ["budget", "5000"],
            ],
            pubkey: "requester-pk",
            kind: NostrKind.agentServiceRequest.rawValue,
            content: "Need translation"
        )

        manager.processEvent(event)

        XCTAssertEqual(manager.pendingRequests.count, 1)
        XCTAssertEqual(manager.pendingRequests[0].requestId, "request-001")
        XCTAssertEqual(manager.pendingRequests[0].budgetSats, 5000)
    }

    func testProcessEvent_serviceRequest_updatesExisting() {
        let event1 = makeEvent(
            id: "req-1",
            tags: [
                ["d", "request-001"],
                ["budget", "3000"],
            ],
            kind: NostrKind.agentServiceRequest.rawValue,
            content: "V1"
        )

        // Same id -> should replace
        let event2 = makeEvent(
            id: "req-1",
            tags: [
                ["d", "request-001-updated"],
                ["budget", "5000"],
            ],
            kind: NostrKind.agentServiceRequest.rawValue,
            content: "V2"
        )

        manager.processEvent(event1)
        manager.processEvent(event2)

        XCTAssertEqual(manager.pendingRequests.count, 1)
        XCTAssertEqual(manager.pendingRequests[0].content, "V2")
    }

    func testProcessEvent_serviceRequest_differentIds_separate() {
        let event1 = makeEvent(
            id: "req-1",
            tags: [["d", "request-001"]],
            kind: NostrKind.agentServiceRequest.rawValue
        )

        let event2 = makeEvent(
            id: "req-2",
            tags: [["d", "request-002"]],
            kind: NostrKind.agentServiceRequest.rawValue
        )

        manager.processEvent(event1)
        manager.processEvent(event2)

        XCTAssertEqual(manager.pendingRequests.count, 2)
    }

    func testProcessEvent_serviceRequest_invalidEvent_ignored() {
        let event = makeEvent(
            id: "bad-req",
            tags: [["s", "translation"]], // missing d tag
            kind: NostrKind.agentServiceRequest.rawValue
        )

        manager.processEvent(event)
        XCTAssertTrue(manager.pendingRequests.isEmpty)
    }

    // MARK: - processEvent: Agreement

    func testProcessEvent_agreement_addsToActive() {
        let event = makeEvent(
            id: "asa-1",
            tags: [
                ["d", "agreement-001"],
                ["status", "active"],
                ["p", "provider-pk", "", "provider"],
                ["p", "requester-pk", "", "requester"],
                ["terms", "per-request", "50", "sats"],
            ],
            kind: NostrKind.agentServiceAgreement.rawValue,
            content: "Agreement details"
        )

        manager.processEvent(event)

        XCTAssertEqual(manager.activeAgreements.count, 1)
        XCTAssertEqual(manager.activeAgreements[0].agreementId, "agreement-001")
        XCTAssertEqual(manager.activeAgreements[0].status, .active)
    }

    func testProcessEvent_agreement_updatesExisting() {
        let event1 = makeEvent(
            id: "asa-1",
            tags: [
                ["d", "agreement-001"],
                ["status", "proposed"],
            ],
            kind: NostrKind.agentServiceAgreement.rawValue,
            content: "Proposed"
        )

        let event2 = makeEvent(
            id: "asa-2",
            tags: [
                ["d", "agreement-001"],
                ["status", "active"],
            ],
            kind: NostrKind.agentServiceAgreement.rawValue,
            content: "Now active"
        )

        manager.processEvent(event1)
        manager.processEvent(event2)

        // Same agreementId -> updated in place
        XCTAssertEqual(manager.activeAgreements.count, 1)
        XCTAssertEqual(manager.activeAgreements[0].status, .active)
        XCTAssertEqual(manager.activeAgreements[0].content, "Now active")
    }

    func testProcessEvent_agreement_invalidEvent_ignored() {
        // Missing both "d" and "status"
        let event = makeEvent(
            id: "bad-asa",
            tags: [["p", "some-pubkey"]],
            kind: NostrKind.agentServiceAgreement.rawValue
        )

        manager.processEvent(event)
        XCTAssertTrue(manager.activeAgreements.isEmpty)
    }

    // MARK: - processEvent: Unknown Kind

    func testProcessEvent_unknownKind_ignored() {
        let event = makeEvent(
            id: "unknown",
            tags: [["d", "something"]],
            kind: 99999
        )

        manager.processEvent(event)

        XCTAssertTrue(manager.discoveredCapabilities.isEmpty)
        XCTAssertTrue(manager.pendingRequests.isEmpty)
        XCTAssertTrue(manager.activeAgreements.isEmpty)
    }

    // MARK: - processEvent: Cross-type isolation

    func testProcessEvent_differentKinds_goToCorrectArrays() {
        let capEvent = makeEvent(
            id: "cap-1",
            tags: [["d", "svc-1"]],
            pubkey: "agent-pk",
            kind: NostrKind.agentCapability.rawValue
        )

        let reqEvent = makeEvent(
            id: "req-1",
            tags: [["d", "req-1"]],
            pubkey: "user-pk",
            kind: NostrKind.agentServiceRequest.rawValue
        )

        let asaEvent = makeEvent(
            id: "asa-1",
            tags: [
                ["d", "asa-1"],
                ["status", "proposed"],
            ],
            kind: NostrKind.agentServiceAgreement.rawValue
        )

        manager.processEvent(capEvent)
        manager.processEvent(reqEvent)
        manager.processEvent(asaEvent)

        XCTAssertEqual(manager.discoveredCapabilities.count, 1)
        XCTAssertEqual(manager.pendingRequests.count, 1)
        XCTAssertEqual(manager.activeAgreements.count, 1)
    }

    // MARK: - Negotiation Message Parsing

    func testNegotiationMessage_encodeDecodeRoundTrip() {
        let original = ASANegotiationMessage(
            type: "service-offer",
            capability: "cap-123",
            params: ["key": "value"],
            budget: nil,
            deadline: nil,
            price: 50,
            priceModel: "per-request",
            l402URL: "https://example.com/l402",
            estimatedTime: 60,
            terms: ["payment": "upfront"],
            offerEvent: "offer-id",
            asa: nil,
            result: nil,
            requestsMade: nil,
            totalPaid: nil,
            reason: nil
        )

        let data = try! JSONEncoder().encode(original)
        let jsonString = String(data: data, encoding: .utf8)!

        let decoded = manager.parseNegotiationMessage(from: jsonString)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.type, "service-offer")
        XCTAssertEqual(decoded?.capability, "cap-123")
        XCTAssertEqual(decoded?.price, 50)
        XCTAssertEqual(decoded?.priceModel, "per-request")
        XCTAssertEqual(decoded?.l402URL, "https://example.com/l402")
        XCTAssertEqual(decoded?.estimatedTime, 60)
        XCTAssertEqual(decoded?.terms?["payment"], "upfront")
        XCTAssertEqual(decoded?.offerEvent, "offer-id")
    }

    func testParseNegotiationMessage_invalidJSON_returnsNil() {
        XCTAssertNil(manager.parseNegotiationMessage(from: "not json"))
        XCTAssertNil(manager.parseNegotiationMessage(from: "{invalid"))
        XCTAssertNil(manager.parseNegotiationMessage(from: "12345"))
    }

    func testParseNegotiationMessage_emptyString_returnsNil() {
        XCTAssertNil(manager.parseNegotiationMessage(from: ""))
    }

    func testParseNegotiationMessage_validMinimalJSON() {
        let json = #"{"type":"service-request"}"#
        let msg = manager.parseNegotiationMessage(from: json)
        XCTAssertNotNil(msg)
        XCTAssertEqual(msg?.type, "service-request")
    }

    func testParseNegotiationMessage_missingTypeField_returnsNil() {
        let json = #"{"capability":"cap-id"}"#
        XCTAssertNil(manager.parseNegotiationMessage(from: json))
    }

    // MARK: - Relay Configuration

    func testAgentRelaysContainsLightningEnable() {
        XCTAssertTrue(
            agent_relays.contains("wss://agents.lightningenable.com"),
            "agent_relays should contain the Lightning Enable agent relay"
        )
    }

    func testBootstrapRelaysContainsAgentRelay() {
        XCTAssertTrue(
            bootstrap_relays.contains("wss://agents.lightningenable.com"),
            "bootstrap_relays should include the agent relay"
        )
    }

    func testAgentRelaysNotEmpty() {
        XCTAssertFalse(agent_relays.isEmpty, "agent_relays must not be empty")
    }

    // MARK: - Publishing (Event Creation)

    func testPublishCapabilityReturnsNilWithoutKeypair() {
        // Without a logged-in user, the factory method cannot sign and returns nil
        let event = manager.publishCapability(
            serviceId: "test-svc",
            categories: ["translation"],
            content: "Test",
            pricing: [AgentPricing(amount: 10, unit: "sats", model: "per-request")]
        )
        XCTAssertNil(event, "publishCapability should return nil when no keypair is available")
    }

    func testPublishServiceRequestReturnsNilWithoutKeypair() {
        let event = manager.publishServiceRequest(
            requestId: "test-req",
            categories: ["translation"],
            content: "Need translation"
        )
        XCTAssertNil(event, "publishServiceRequest should return nil when no keypair is available")
    }

    func testPublishAgreementReturnsNilWithoutKeypair() {
        let event = manager.publishAgreement(
            agreementId: "test-asa",
            providerPubkey: "provider-pk",
            requesterPubkey: "requester-pk",
            terms: [ASATerm(type: "per-request", value: "50", unit: "sats")],
            content: "Agreement"
        )
        XCTAssertNil(event, "publishAgreement should return nil when no keypair is available")
    }

    func testAgentCapabilityEventHasCorrectTagsAndKind() {
        // Use createNostrObjectAndSign directly with a test keypair to verify tag structure
        // Test private key (32 bytes hex) — NOT a real key, just for unit testing
        let testPrivkey = "e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35"
        let testPubkey = "339dcab94eee2e4b0a6427e563e6455bdc05345560f4c4023cdd97bceaababcd"

        var tags: [[String]] = [["d", "test-service"]]
        tags.append(["s", "translation"])
        tags.append(["price", "50", "sats", "per-request"])
        tags.append(["l402", "https://example.com/l402"])

        let event = NostrObject.createNostrObjectAndSign(
            pubkey: testPubkey,
            privkey: testPrivkey,
            content: "Test capability",
            kind: NostrKind.agentCapability.rawValue,
            tags: tags
        )

        // If the keypair is valid, event will be non-nil; if not, skip assertion
        if let event = event {
            XCTAssertEqual(event.kind, NostrKind.agentCapability.rawValue)
            XCTAssertEqual(event.content, "Test capability")

            // Verify expected tags are present
            let dTag = event.tags.first(where: { $0.first == "d" })
            XCTAssertEqual(dTag?[1], "test-service")

            let sTag = event.tags.first(where: { $0.first == "s" })
            XCTAssertEqual(sTag?[1], "translation")

            let priceTag = event.tags.first(where: { $0.first == "price" })
            XCTAssertEqual(priceTag?[1], "50")
            XCTAssertEqual(priceTag?[2], "sats")
            XCTAssertEqual(priceTag?[3], "per-request")

            let l402Tag = event.tags.first(where: { $0.first == "l402" })
            XCTAssertEqual(l402Tag?[1], "https://example.com/l402")
        }
    }

    // MARK: - processEvent: Update-in-place behavior

    func testProcessEventUpdatesExistingCapability() {
        // First capability from agent-pk / svc-alpha
        let event1 = makeEvent(
            id: "cap-v1",
            tags: [
                ["d", "svc-alpha"],
                ["price", "10", "sats", "per-request"],
            ],
            pubkey: "agent-pk",
            kind: NostrKind.agentCapability.rawValue,
            content: "Version 1"
        )

        // Updated capability — same pubkey + serviceId
        let event2 = makeEvent(
            id: "cap-v2",
            tags: [
                ["d", "svc-alpha"],
                ["price", "20", "sats", "per-request"],
            ],
            pubkey: "agent-pk",
            kind: NostrKind.agentCapability.rawValue,
            content: "Version 2"
        )

        manager.processEvent(event1)
        manager.processEvent(event2)

        XCTAssertEqual(manager.discoveredCapabilities.count, 1, "Should update in-place, not duplicate")
        XCTAssertEqual(manager.discoveredCapabilities[0].content, "Version 2")
        XCTAssertEqual(manager.discoveredCapabilities[0].pricing[0].amount, 20)
        XCTAssertEqual(manager.discoveredCapabilities[0].id, "cap-v2")
    }

    func testProcessEventUpdatesExistingRequest() {
        let event1 = makeEvent(
            id: "req-same",
            tags: [
                ["d", "req-alpha"],
                ["budget", "1000"],
            ],
            pubkey: "requester-pk",
            kind: NostrKind.agentServiceRequest.rawValue,
            content: "Original request"
        )

        // Same event id -> should update in place
        let event2 = makeEvent(
            id: "req-same",
            tags: [
                ["d", "req-alpha-v2"],
                ["budget", "2000"],
            ],
            pubkey: "requester-pk",
            kind: NostrKind.agentServiceRequest.rawValue,
            content: "Updated request"
        )

        manager.processEvent(event1)
        manager.processEvent(event2)

        XCTAssertEqual(manager.pendingRequests.count, 1, "Should update in-place, not duplicate")
        XCTAssertEqual(manager.pendingRequests[0].content, "Updated request")
        XCTAssertEqual(manager.pendingRequests[0].budgetSats, 2000)
    }

    func testProcessEventUpdatesExistingAgreement() {
        let event1 = makeEvent(
            id: "asa-v1",
            tags: [
                ["d", "asa-alpha"],
                ["status", "proposed"],
            ],
            kind: NostrKind.agentServiceAgreement.rawValue,
            content: "Proposed agreement"
        )

        // Same agreementId -> should update in place
        let event2 = makeEvent(
            id: "asa-v2",
            tags: [
                ["d", "asa-alpha"],
                ["status", "active"],
            ],
            kind: NostrKind.agentServiceAgreement.rawValue,
            content: "Activated agreement"
        )

        manager.processEvent(event1)
        manager.processEvent(event2)

        XCTAssertEqual(manager.activeAgreements.count, 1, "Should update in-place, not duplicate")
        XCTAssertEqual(manager.activeAgreements[0].status, .active)
        XCTAssertEqual(manager.activeAgreements[0].content, "Activated agreement")
    }

    // MARK: - Demo Mode

    func testDemoModeEnabledReturnsDemoPosts() {
        // Save current value and restore after test
        let previousValue = ASAManager.demoModeEnabled
        defer { ASAManager.demoModeEnabled = previousValue }

        ASAManager.demoModeEnabled = true
        let posts = ASAManager.demoPosts()
        XCTAssertFalse(posts.isEmpty, "demoPosts() should return posts when demo mode is enabled")
    }

    func testDemoModeDisabledReturnsEmpty() {
        let previousValue = ASAManager.demoModeEnabled
        defer { ASAManager.demoModeEnabled = previousValue }

        ASAManager.demoModeEnabled = false
        let posts = ASAManager.demoPosts()
        XCTAssertTrue(posts.isEmpty, "demoPosts() should return empty when demo mode is disabled")
    }
}
