//
//  L402Client.swift
//  Primal
//
//  L402 protocol support for accessing paid content via Lightning payments.
//  Implements HTTP 402 Payment Required flow with macaroon + preimage auth.
//

import Foundation
import Combine

/// Errors that can occur during L402 authentication.
enum L402Error: Error {
    case invalidChallenge
    case paymentFailed(String)
    case missingPreimage
    case networkError(Error)
    case invalidResponse
    case walletNotAvailable

    var message: String {
        switch self {
        case .invalidChallenge:
            return "Invalid L402 challenge from server"
        case .paymentFailed(let msg):
            return "Payment failed: \(msg)"
        case .missingPreimage:
            return "Payment succeeded but no preimage was returned"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .walletNotAvailable:
            return "Wallet is not available"
        }
    }
}

/// Parsed L402 challenge from a 402 response's WWW-Authenticate header.
struct L402Challenge {
    let macaroon: String
    let invoice: String

    /// Parse an L402/LSAT challenge from the WWW-Authenticate header.
    /// Format: `L402 macaroon="<macaroon>", invoice="<invoice>"`
    /// or:     `LSAT macaroon="<macaroon>", invoice="<invoice>"`
    static func parse(from header: String) -> L402Challenge? {
        let trimmed = header.trimmingCharacters(in: .whitespaces)

        // Support both L402 and legacy LSAT prefix
        let body: String
        if trimmed.hasPrefix("L402 ") {
            body = String(trimmed.dropFirst(5))
        } else if trimmed.hasPrefix("LSAT ") {
            body = String(trimmed.dropFirst(5))
        } else {
            return nil
        }

        var macaroon: String?
        var invoice: String?

        let parts = body.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for part in parts {
            let keyValue = part.components(separatedBy: "=")
            guard keyValue.count == 2 else { continue }
            let key = keyValue[0].trimmingCharacters(in: .whitespaces).lowercased()
            let value = keyValue[1].trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))

            if key == "macaroon" {
                macaroon = value
            } else if key == "invoice" {
                invoice = value
            }
        }

        guard let mac = macaroon, let inv = invoice, !mac.isEmpty, !inv.isEmpty else {
            return nil
        }

        return L402Challenge(macaroon: mac, invoice: inv)
    }
}

/// Client for accessing L402-protected resources.
/// Automatically handles the 402 → pay → retry flow using Primal's wallet.
final class L402Client {
    static let shared = L402Client()

    private let session = URLSession.shared

    /// Access an L402-protected URL.
    /// 1. Makes initial request
    /// 2. If 402, parses the challenge
    /// 3. Pays the invoice via the wallet
    /// 4. Retries with L402 authorization header
    func access(_ url: URL) async throws -> (Data, HTTPURLResponse) {
        // Step 1: Initial request
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw L402Error.invalidResponse
        }

        // If not 402, return directly
        guard httpResponse.statusCode == 402 else {
            return (data, httpResponse)
        }

        // Step 2: Parse L402 challenge
        guard
            let authHeader = httpResponse.value(forHTTPHeaderField: "WWW-Authenticate"),
            let challenge = L402Challenge.parse(from: authHeader)
        else {
            throw L402Error.invalidChallenge
        }

        // Step 3: Pay the invoice via the wallet
        guard WalletManager.instance.userHasWallet == true else {
            throw L402Error.walletNotAvailable
        }

        let paymentResult: PaymentResult?
        do {
            paymentResult = try await WalletManager.instance.sendLNInvoice(
                challenge.invoice,
                satsOverride: nil,
                messageOverride: nil
            )
        } catch {
            throw L402Error.paymentFailed(error.localizedDescription)
        }

        guard let preimage = paymentResult?.preimage else {
            throw L402Error.missingPreimage
        }

        // Step 4: Retry with L402 auth
        var authedRequest = URLRequest(url: url)
        authedRequest.setValue("L402 \(challenge.macaroon):\(preimage)", forHTTPHeaderField: "Authorization")

        let (authedData, authedResponse) = try await session.data(for: authedRequest)

        guard let authedHTTPResponse = authedResponse as? HTTPURLResponse else {
            throw L402Error.invalidResponse
        }

        return (authedData, authedHTTPResponse)
    }

    /// Access an L402-protected URL and decode the JSON response.
    func accessJSON<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        let (data, _) = try await access(url)
        return try JSONDecoder().decode(type, from: data)
    }
}
