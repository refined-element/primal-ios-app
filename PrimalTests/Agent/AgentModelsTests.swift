//
//  AgentModelsTests.swift
//  PrimalTests
//
//  Created by NostrWolfe on 14.3.26..
//

import XCTest
@testable import Primal

// MARK: - AgentPricing Tests

final class AgentPricingTests: XCTestCase {

    func testParse_validTag() {
        let tag = ["price", "50", "sats", "per-request"]
        let pricing = AgentPricing.parse(from: tag)
        XCTAssertNotNil(pricing)
        XCTAssertEqual(pricing?.amount, 50)
        XCTAssertEqual(pricing?.unit, "sats")
        XCTAssertEqual(pricing?.model, "per-request")
    }

    func testParse_largeAmount() {
        let tag = ["price", "1000000", "msats", "per-minute"]
        let pricing = AgentPricing.parse(from: tag)
        XCTAssertNotNil(pricing)
        XCTAssertEqual(pricing?.amount, 1_000_000)
        XCTAssertEqual(pricing?.unit, "msats")
        XCTAssertEqual(pricing?.model, "per-minute")
    }

    func testParse_zeroAmount() {
        let tag = ["price", "0", "sats", "free"]
        let pricing = AgentPricing.parse(from: tag)
        XCTAssertNotNil(pricing)
        XCTAssertEqual(pricing?.amount, 0)
    }

    func testParse_missingAmount() {
        let tag = ["price"]
        XCTAssertNil(AgentPricing.parse(from: tag))
    }

    func testParse_nonIntegerAmount() {
        let tag = ["price", "abc", "sats", "per-request"]
        XCTAssertNil(AgentPricing.parse(from: tag))
    }

    func testParse_floatAmount() {
        let tag = ["price", "3.14", "sats", "per-request"]
        XCTAssertNil(AgentPricing.parse(from: tag))
    }

    func testParse_wrongTagName() {
        let tag = ["cost", "50", "sats", "per-request"]
        XCTAssertNil(AgentPricing.parse(from: tag))
    }

    func testParse_tooFewElements() {
        let tag = ["price", "50", "sats"]
        XCTAssertNil(AgentPricing.parse(from: tag))
    }

    func testParse_emptyTag() {
        let tag: [String] = []
        XCTAssertNil(AgentPricing.parse(from: tag))
    }

    func testParse_extraElementsIgnored() {
        let tag = ["price", "50", "sats", "per-request", "extra", "data"]
        let pricing = AgentPricing.parse(from: tag)
        XCTAssertNotNil(pricing)
        XCTAssertEqual(pricing?.amount, 50)
    }
}

// MARK: - AgentCapability Tests

final class AgentCapabilityTests: XCTestCase {

    private let testId = "event-id-abc123"
    private let testPubkey = "pubkey-abc123def456"
    private let testCreatedAt: Int64 = 1_710_000_000

    func testParse_fullEvent() {
        let tags: [[String]] = [
            ["d", "translate-service"],
            ["s", "translation"],
            ["s", "ai"],
            ["price", "50", "sats", "per-request"],
            ["price", "100", "sats", "per-minute"],
            ["l402", "https://agent.example.com/l402/translate"],
            ["endpoint", "https://api.example.com/translate", "POST"],
            ["schema", "https://schema.example.com/translate.json"],
            ["capacity", "1000", "requests/hour"],
            ["uptime", "0.998"],
            ["t", "ai"],
            ["t", "nlp"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "Translation agent", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)

        XCTAssertNotNil(cap)
        XCTAssertEqual(cap?.id, testId)
        XCTAssertEqual(cap?.pubkey, testPubkey)
        XCTAssertEqual(cap?.createdAt, testCreatedAt)
        XCTAssertEqual(cap?.serviceId, "translate-service")
        XCTAssertEqual(cap?.categories, ["translation", "ai"])
        XCTAssertEqual(cap?.content, "Translation agent")
        XCTAssertEqual(cap?.pricing.count, 2)
        XCTAssertEqual(cap?.pricing[0].amount, 50)
        XCTAssertEqual(cap?.pricing[1].amount, 100)
        XCTAssertEqual(cap?.l402Endpoint, "https://agent.example.com/l402/translate")
        XCTAssertEqual(cap?.apiEndpoint, "https://api.example.com/translate")
        XCTAssertEqual(cap?.apiMethod, "POST")
        XCTAssertEqual(cap?.schemaURL, "https://schema.example.com/translate.json")
        XCTAssertEqual(cap?.capacity, "1000 requests/hour")
        XCTAssertEqual(cap?.uptime, 0.998, accuracy: 0.0001)
        XCTAssertEqual(cap?.hashtags, ["ai", "nlp"])
    }

    func testParse_minimalEvent() {
        let tags: [[String]] = [
            ["d", "minimal-service"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)

        XCTAssertNotNil(cap)
        XCTAssertEqual(cap?.serviceId, "minimal-service")
        XCTAssertTrue(cap?.categories.isEmpty ?? false)
        XCTAssertTrue(cap?.pricing.isEmpty ?? false)
        XCTAssertNil(cap?.l402Endpoint)
        XCTAssertNil(cap?.apiEndpoint)
        XCTAssertNil(cap?.apiMethod)
        XCTAssertNil(cap?.schemaURL)
        XCTAssertNil(cap?.capacity)
        XCTAssertNil(cap?.uptime)
        XCTAssertTrue(cap?.hashtags.isEmpty ?? false)
    }

    func testParse_missingServiceId_returnsNil() {
        let tags: [[String]] = [
            ["s", "translation"],
            ["price", "50", "sats", "per-request"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "No d tag", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(cap)
    }

    func testParse_multipleCategories() {
        let tags: [[String]] = [
            ["d", "multi-cat"],
            ["s", "translation"],
            ["s", "summarization"],
            ["s", "generation"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(cap?.categories, ["translation", "summarization", "generation"])
    }

    func testParse_multiplePricingTiers() {
        let tags: [[String]] = [
            ["d", "tiered"],
            ["price", "10", "sats", "per-request"],
            ["price", "500", "sats", "per-hour"],
            ["price", "5000", "sats", "per-day"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(cap?.pricing.count, 3)
        XCTAssertEqual(cap?.pricing[0].amount, 10)
        XCTAssertEqual(cap?.pricing[1].amount, 500)
        XCTAssertEqual(cap?.pricing[2].amount, 5000)
    }

    func testParse_invalidPricingTagsFiltered() {
        let tags: [[String]] = [
            ["d", "mixed-pricing"],
            ["price", "50", "sats", "per-request"],
            ["price", "invalid"],
            ["price", "100", "sats", "per-minute"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(cap?.pricing.count, 2)
    }

    func testParse_uptimeParsingValid() {
        let tags: [[String]] = [
            ["d", "uptime-test"],
            ["uptime", "0.998"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(cap?.uptime, 0.998, accuracy: 0.0001)
    }

    func testParse_uptimeParsingInvalid() {
        let tags: [[String]] = [
            ["d", "uptime-bad"],
            ["uptime", "not-a-number"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(cap?.uptime)
    }

    func testParse_uptimeParsingMissing() {
        let tags: [[String]] = [
            ["d", "no-uptime"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(cap?.uptime)
    }

    func testParse_capacityCombinesTagElements() {
        let tags: [[String]] = [
            ["d", "capacity-test"],
            ["capacity", "1000", "requests/hour"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(cap?.capacity, "1000 requests/hour")
    }

    func testParse_capacitySingleValue() {
        let tags: [[String]] = [
            ["d", "capacity-single"],
            ["capacity", "unlimited"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(cap?.capacity, "unlimited")
    }

    func testParse_capacityEmptyTag() {
        let tags: [[String]] = [
            ["d", "capacity-empty"],
            ["capacity"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(cap?.capacity)
    }

    func testParse_endpointTagWithMethod() {
        let tags: [[String]] = [
            ["d", "endpoint-test"],
            ["endpoint", "https://api.example.com/v1/run", "POST"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(cap?.apiEndpoint, "https://api.example.com/v1/run")
        XCTAssertEqual(cap?.apiMethod, "POST")
    }

    func testParse_endpointTagWithoutMethod() {
        let tags: [[String]] = [
            ["d", "endpoint-no-method"],
            ["endpoint", "https://api.example.com/v1/run"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(cap?.apiEndpoint, "https://api.example.com/v1/run")
        XCTAssertNil(cap?.apiMethod)
    }

    func testParse_extraTagsIgnored() {
        let tags: [[String]] = [
            ["d", "extra-tags"],
            ["unknown", "should-be-ignored"],
            ["foo", "bar", "baz"],
        ]

        let cap = AgentCapability.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNotNil(cap)
        XCTAssertEqual(cap?.serviceId, "extra-tags")
    }
}

// MARK: - AgentServiceRequest Tests

final class AgentServiceRequestTests: XCTestCase {

    private let testId = "req-event-id-xyz"
    private let testPubkey = "requester-pubkey-789"
    private let testCreatedAt: Int64 = 1_710_100_000

    func testParse_fullEvent() {
        let tags: [[String]] = [
            ["d", "request-001"],
            ["s", "translation"],
            ["s", "summarization"],
            ["budget", "5000"],
            ["deadline", "1710200000"],
            ["t", "urgent"],
            ["t", "ai"],
        ]

        let req = AgentServiceRequest.parse(from: tags, content: "Translate this document", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)

        XCTAssertNotNil(req)
        XCTAssertEqual(req?.id, testId)
        XCTAssertEqual(req?.pubkey, testPubkey)
        XCTAssertEqual(req?.createdAt, testCreatedAt)
        XCTAssertEqual(req?.requestId, "request-001")
        XCTAssertEqual(req?.categories, ["translation", "summarization"])
        XCTAssertEqual(req?.content, "Translate this document")
        XCTAssertEqual(req?.budgetSats, 5000)
        XCTAssertEqual(req?.deadline, 1_710_200_000)
        XCTAssertEqual(req?.hashtags, ["urgent", "ai"])
    }

    func testParse_minimalEvent() {
        let tags: [[String]] = [
            ["d", "minimal-req"],
        ]

        let req = AgentServiceRequest.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)

        XCTAssertNotNil(req)
        XCTAssertEqual(req?.requestId, "minimal-req")
        XCTAssertNil(req?.budgetSats)
        XCTAssertNil(req?.deadline)
        XCTAssertTrue(req?.categories.isEmpty ?? false)
        XCTAssertTrue(req?.hashtags.isEmpty ?? false)
    }

    func testParse_missingRequestId_returnsNil() {
        let tags: [[String]] = [
            ["s", "translation"],
            ["budget", "5000"],
        ]

        XCTAssertNil(AgentServiceRequest.parse(from: tags, content: "No d tag", id: testId, pubkey: testPubkey, createdAt: testCreatedAt))
    }

    func testParse_budgetParsing_validInteger() {
        let tags: [[String]] = [
            ["d", "budget-test"],
            ["budget", "10000"],
        ]

        let req = AgentServiceRequest.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(req?.budgetSats, 10_000)
    }

    func testParse_budgetParsing_invalidInteger() {
        let tags: [[String]] = [
            ["d", "budget-bad"],
            ["budget", "not-a-number"],
        ]

        let req = AgentServiceRequest.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(req?.budgetSats)
    }

    func testParse_budgetParsing_zeroBudget() {
        let tags: [[String]] = [
            ["d", "budget-zero"],
            ["budget", "0"],
        ]

        let req = AgentServiceRequest.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(req?.budgetSats, 0)
    }

    func testParse_deadlineParsing_valid() {
        let tags: [[String]] = [
            ["d", "deadline-test"],
            ["deadline", "1710200000"],
        ]

        let req = AgentServiceRequest.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(req?.deadline, 1_710_200_000)
    }

    func testParse_deadlineParsing_invalid() {
        let tags: [[String]] = [
            ["d", "deadline-bad"],
            ["deadline", "tomorrow"],
        ]

        let req = AgentServiceRequest.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(req?.deadline)
    }
}

// MARK: - ASATerm Tests

final class ASATermTests: XCTestCase {

    func testParse_validTerm() {
        let tag = ["terms", "per-request", "50", "sats"]
        let term = ASATerm.parse(from: tag)

        XCTAssertNotNil(term)
        XCTAssertEqual(term?.type, "per-request")
        XCTAssertEqual(term?.value, "50")
        XCTAssertEqual(term?.unit, "sats")
    }

    func testParse_wrongTagName() {
        let tag = ["pricing", "per-request", "50", "sats"]
        XCTAssertNil(ASATerm.parse(from: tag))
    }

    func testParse_tooFewElements() {
        let tag = ["terms", "per-request", "50"]
        XCTAssertNil(ASATerm.parse(from: tag))
    }

    func testParse_emptyTag() {
        let tag: [String] = []
        XCTAssertNil(ASATerm.parse(from: tag))
    }

    func testParse_singleElement() {
        let tag = ["terms"]
        XCTAssertNil(ASATerm.parse(from: tag))
    }

    func testParse_extraElementsIgnored() {
        let tag = ["terms", "per-minute", "100", "sats", "extra1", "extra2"]
        let term = ASATerm.parse(from: tag)
        XCTAssertNotNil(term)
        XCTAssertEqual(term?.type, "per-minute")
        XCTAssertEqual(term?.value, "100")
        XCTAssertEqual(term?.unit, "sats")
    }
}

// MARK: - ASAStatus Tests

final class ASAStatusTests: XCTestCase {

    func testAllRawValues() {
        XCTAssertEqual(ASAStatus(rawValue: "proposed"), .proposed)
        XCTAssertEqual(ASAStatus(rawValue: "active"), .active)
        XCTAssertEqual(ASAStatus(rawValue: "completed"), .completed)
        XCTAssertEqual(ASAStatus(rawValue: "disputed"), .disputed)
        XCTAssertEqual(ASAStatus(rawValue: "expired"), .expired)
    }

    func testInvalidRawValue() {
        XCTAssertNil(ASAStatus(rawValue: "unknown"))
        XCTAssertNil(ASAStatus(rawValue: ""))
        XCTAssertNil(ASAStatus(rawValue: "Active")) // case-sensitive
    }
}

// MARK: - AgentServiceAgreement Tests

final class AgentServiceAgreementTests: XCTestCase {

    private let testId = "asa-event-id-456"
    private let testPubkey = "asa-creator-pubkey"
    private let testCreatedAt: Int64 = 1_710_300_000

    func testParse_fullEvent() {
        let tags: [[String]] = [
            ["d", "agreement-001"],
            ["status", "active"],
            ["p", "provider-pubkey-abc", "", "provider"],
            ["p", "requester-pubkey-xyz", "", "requester"],
            ["e", "cap-event-id-123", "", "capability"],
            ["l402", "https://agent.example.com/l402/service"],
            ["terms", "per-request", "50", "sats"],
            ["terms", "per-hour", "500", "sats"],
            ["expiry", "1711000000"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "Service agreement", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)

        XCTAssertNotNil(asa)
        XCTAssertEqual(asa?.id, testId)
        XCTAssertEqual(asa?.pubkey, testPubkey)
        XCTAssertEqual(asa?.createdAt, testCreatedAt)
        XCTAssertEqual(asa?.agreementId, "agreement-001")
        XCTAssertEqual(asa?.status, .active)
        XCTAssertEqual(asa?.providerPubkey, "provider-pubkey-abc")
        XCTAssertEqual(asa?.requesterPubkey, "requester-pubkey-xyz")
        XCTAssertEqual(asa?.capabilityEventId, "cap-event-id-123")
        XCTAssertEqual(asa?.l402Endpoint, "https://agent.example.com/l402/service")
        XCTAssertEqual(asa?.terms.count, 2)
        XCTAssertEqual(asa?.terms[0].type, "per-request")
        XCTAssertEqual(asa?.terms[1].type, "per-hour")
        XCTAssertEqual(asa?.expiry, 1_711_000_000)
        XCTAssertEqual(asa?.content, "Service agreement")
    }

    func testParse_missingAgreementId_returnsNil() {
        let tags: [[String]] = [
            ["status", "active"],
        ]
        XCTAssertNil(AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt))
    }

    func testParse_missingStatus_returnsNil() {
        let tags: [[String]] = [
            ["d", "agreement-no-status"],
        ]
        XCTAssertNil(AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt))
    }

    func testParse_invalidStatus_returnsNil() {
        let tags: [[String]] = [
            ["d", "agreement-bad-status"],
            ["status", "invalid-status-value"],
        ]
        XCTAssertNil(AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt))
    }

    func testParse_providerRequesterPubkeys() {
        let tags: [[String]] = [
            ["d", "pubkey-test"],
            ["status", "proposed"],
            ["p", "provider-pk", "", "provider"],
            ["p", "requester-pk", "", "requester"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(asa?.providerPubkey, "provider-pk")
        XCTAssertEqual(asa?.requesterPubkey, "requester-pk")
    }

    func testParse_providerRequesterPubkeys_missingRole() {
        // p-tags without role markers at index 3
        let tags: [[String]] = [
            ["d", "no-role-test"],
            ["status", "active"],
            ["p", "some-pubkey"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNotNil(asa)
        XCTAssertNil(asa?.providerPubkey)
        XCTAssertNil(asa?.requesterPubkey)
    }

    func testParse_capabilityEventId() {
        let tags: [[String]] = [
            ["d", "cap-ref-test"],
            ["status", "active"],
            ["e", "cap-id-abc", "", "capability"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(asa?.capabilityEventId, "cap-id-abc")
    }

    func testParse_capabilityEventId_noCapabilityMarker() {
        let tags: [[String]] = [
            ["d", "cap-no-marker"],
            ["status", "active"],
            ["e", "some-event-id", "", "reply"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(asa?.capabilityEventId)
    }

    func testParse_multipleTerms() {
        let tags: [[String]] = [
            ["d", "multi-terms"],
            ["status", "proposed"],
            ["terms", "per-request", "50", "sats"],
            ["terms", "per-hour", "500", "sats"],
            ["terms", "per-day", "5000", "sats"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(asa?.terms.count, 3)
        XCTAssertEqual(asa?.terms[0].value, "50")
        XCTAssertEqual(asa?.terms[1].value, "500")
        XCTAssertEqual(asa?.terms[2].value, "5000")
    }

    func testParse_invalidTermsFiltered() {
        let tags: [[String]] = [
            ["d", "bad-terms"],
            ["status", "active"],
            ["terms", "per-request", "50", "sats"],
            ["terms", "incomplete"],
            ["terms", "per-hour", "100", "sats"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(asa?.terms.count, 2)
    }

    func testParse_allStatusValues() {
        let statuses: [ASAStatus] = [.proposed, .active, .completed, .disputed, .expired]

        for status in statuses {
            let tags: [[String]] = [
                ["d", "status-\(status.rawValue)"],
                ["status", status.rawValue],
            ]

            let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
            XCTAssertNotNil(asa, "Should parse agreement with status \(status.rawValue)")
            XCTAssertEqual(asa?.status, status)
        }
    }

    func testParse_expiryParsing_valid() {
        let tags: [[String]] = [
            ["d", "expiry-valid"],
            ["status", "active"],
            ["expiry", "1711000000"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertEqual(asa?.expiry, 1_711_000_000)
    }

    func testParse_expiryParsing_invalid() {
        let tags: [[String]] = [
            ["d", "expiry-bad"],
            ["status", "active"],
            ["expiry", "not-a-timestamp"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(asa?.expiry)
    }

    func testParse_expiryParsing_missing() {
        let tags: [[String]] = [
            ["d", "no-expiry"],
            ["status", "active"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(asa?.expiry)
    }

    func testParse_noL402Endpoint() {
        let tags: [[String]] = [
            ["d", "no-l402"],
            ["status", "proposed"],
        ]

        let asa = AgentServiceAgreement.parse(from: tags, content: "", id: testId, pubkey: testPubkey, createdAt: testCreatedAt)
        XCTAssertNil(asa?.l402Endpoint)
    }
}

// MARK: - ASANegotiationMessage Tests

final class ASANegotiationMessageTests: XCTestCase {

    func testEncodeDecode_serviceRequest() {
        let msg = ASANegotiationMessage(
            type: "service-request",
            capability: "cap-event-id",
            params: ["language": "en", "format": "markdown"],
            budget: 5000,
            deadline: 1_710_200_000,
            price: nil,
            priceModel: nil,
            l402URL: nil,
            estimatedTime: nil,
            terms: nil,
            offerEvent: nil,
            asa: nil,
            result: nil,
            requestsMade: nil,
            totalPaid: nil,
            reason: nil
        )

        let data = try! JSONEncoder().encode(msg)
        let decoded = try! JSONDecoder().decode(ASANegotiationMessage.self, from: data)

        XCTAssertEqual(decoded.type, "service-request")
        XCTAssertEqual(decoded.capability, "cap-event-id")
        XCTAssertEqual(decoded.params?["language"], "en")
        XCTAssertEqual(decoded.params?["format"], "markdown")
        XCTAssertEqual(decoded.budget, 5000)
        XCTAssertEqual(decoded.deadline, 1_710_200_000)
    }

    func testEncodeDecode_serviceOffer() {
        let msg = ASANegotiationMessage(
            type: "service-offer",
            capability: "cap-id",
            params: nil,
            budget: nil,
            deadline: nil,
            price: 50,
            priceModel: "per-request",
            l402URL: "https://agent.example.com/l402",
            estimatedTime: 120,
            terms: ["payment": "upfront", "refund": "on-failure"],
            offerEvent: "offer-event-id",
            asa: nil,
            result: nil,
            requestsMade: nil,
            totalPaid: nil,
            reason: nil
        )

        let data = try! JSONEncoder().encode(msg)
        let decoded = try! JSONDecoder().decode(ASANegotiationMessage.self, from: data)

        XCTAssertEqual(decoded.type, "service-offer")
        XCTAssertEqual(decoded.price, 50)
        XCTAssertEqual(decoded.priceModel, "per-request")
        XCTAssertEqual(decoded.l402URL, "https://agent.example.com/l402")
        XCTAssertEqual(decoded.estimatedTime, 120)
        XCTAssertEqual(decoded.terms?["payment"], "upfront")
        XCTAssertEqual(decoded.offerEvent, "offer-event-id")
    }

    func testEncodeDecode_accept() {
        let msg = ASANegotiationMessage(
            type: "accept",
            capability: nil,
            params: nil,
            budget: nil,
            deadline: nil,
            price: nil,
            priceModel: nil,
            l402URL: nil,
            estimatedTime: nil,
            terms: nil,
            offerEvent: "offer-event-to-accept",
            asa: "asa-event-id",
            result: nil,
            requestsMade: nil,
            totalPaid: nil,
            reason: nil
        )

        let data = try! JSONEncoder().encode(msg)
        let decoded = try! JSONDecoder().decode(ASANegotiationMessage.self, from: data)

        XCTAssertEqual(decoded.type, "accept")
        XCTAssertEqual(decoded.offerEvent, "offer-event-to-accept")
        XCTAssertEqual(decoded.asa, "asa-event-id")
    }

    func testEncodeDecode_complete() {
        let msg = ASANegotiationMessage(
            type: "complete",
            capability: nil,
            params: nil,
            budget: nil,
            deadline: nil,
            price: nil,
            priceModel: nil,
            l402URL: nil,
            estimatedTime: nil,
            terms: nil,
            offerEvent: nil,
            asa: "asa-completed",
            result: "Translation completed successfully.",
            requestsMade: 3,
            totalPaid: 150,
            reason: nil
        )

        let data = try! JSONEncoder().encode(msg)
        let decoded = try! JSONDecoder().decode(ASANegotiationMessage.self, from: data)

        XCTAssertEqual(decoded.type, "complete")
        XCTAssertEqual(decoded.asa, "asa-completed")
        XCTAssertEqual(decoded.result, "Translation completed successfully.")
        XCTAssertEqual(decoded.requestsMade, 3)
        XCTAssertEqual(decoded.totalPaid, 150)
    }

    func testEncodeDecode_dispute() {
        let msg = ASANegotiationMessage(
            type: "dispute",
            capability: nil,
            params: nil,
            budget: nil,
            deadline: nil,
            price: nil,
            priceModel: nil,
            l402URL: nil,
            estimatedTime: nil,
            terms: nil,
            offerEvent: nil,
            asa: "asa-disputed",
            result: nil,
            requestsMade: nil,
            totalPaid: nil,
            reason: "Service quality below agreed standards"
        )

        let data = try! JSONEncoder().encode(msg)
        let decoded = try! JSONDecoder().decode(ASANegotiationMessage.self, from: data)

        XCTAssertEqual(decoded.type, "dispute")
        XCTAssertEqual(decoded.asa, "asa-disputed")
        XCTAssertEqual(decoded.reason, "Service quality below agreed standards")
    }

    func testDecode_missingOptionalFields() {
        let json = """
        {"type": "service-request"}
        """
        let data = json.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(ASANegotiationMessage.self, from: data)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.type, "service-request")
        XCTAssertNil(decoded?.capability)
        XCTAssertNil(decoded?.params)
        XCTAssertNil(decoded?.budget)
        XCTAssertNil(decoded?.deadline)
        XCTAssertNil(decoded?.price)
        XCTAssertNil(decoded?.priceModel)
        XCTAssertNil(decoded?.l402URL)
        XCTAssertNil(decoded?.estimatedTime)
        XCTAssertNil(decoded?.terms)
        XCTAssertNil(decoded?.offerEvent)
        XCTAssertNil(decoded?.asa)
        XCTAssertNil(decoded?.result)
        XCTAssertNil(decoded?.requestsMade)
        XCTAssertNil(decoded?.totalPaid)
        XCTAssertNil(decoded?.reason)
    }

    func testDecode_invalidJSON() {
        let json = "not valid json at all"
        let data = json.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(ASANegotiationMessage.self, from: data)
        XCTAssertNil(decoded)
    }

    func testDecode_emptyObject() {
        // "type" is required for Codable struct, so empty object should fail
        let json = "{}"
        let data = json.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(ASANegotiationMessage.self, from: data)
        // type is non-optional String, so decoding {} should fail
        XCTAssertNil(decoded)
    }
}
