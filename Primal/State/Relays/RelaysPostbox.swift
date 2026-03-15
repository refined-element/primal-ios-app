//
//  RelaysPostbox.swift
//  Primal
//
//  Created by Nikola Lukovic on 21.6.23..
//

import Foundation
import Combine
import GenericJSON

final class RelaysPostbox {
    let pool = RelayPool()
    
    static let instance = RelaysPostbox()
    
    func disconnect() {
        loadedRalays = []
        self.pool.disconnect()
    }
    
    var loadedRalays: [String] = []
    
    var cancellables: Set<AnyCancellable> = []
    
    func connect(_ relays: [String]) {
        if NetworkSettings.enhancedPrivacy { return } // Disable connecting to the relays
        
        loadedRalays += relays
        self.pool.connect(relays: relays)
    }
    
    func reconnect() {
        pool.disconnect()
        pool.connect(relays: loadedRalays)
    }
    
    /// The dedicated agent relay pool — connects only to agent_relays.
    let agentPool = RelayPool()

    /// Connect agent relay pool to the agent-specific relays.
    func connectAgentRelays() {
        agentPool.connect(relays: agent_relays)
    }

    /// Subscribe to agent events via REQ on the agent relay pool only.
    func subscribeAgentREQ(subscriptionId: String, filters: [JSON], handler: @escaping (_ event: JSON, _ relay: String) -> Void) {
        // Ensure agent relays are connected
        if agentPool.connections.isEmpty {
            connectAgentRelays()
        }
        agentPool.requestREQ(subscriptionId: subscriptionId, filters: filters, handler: handler)
    }

    /// Close an agent REQ subscription.
    func closeAgentREQ(subscriptionId: String) {
        agentPool.closeREQ(subscriptionId: subscriptionId)
    }

    /// Publish an agent event ONLY to agent-specific relays.
    /// Does NOT broadcast to all user relays.
    func requestAgentEvent(_ ev: NostrObject, successHandler: ((_ result: [JSON]) -> Void)? = nil, errorHandler: (() -> Void)? = nil) {
        // Ensure agent relays are connected
        if agentPool.connections.isEmpty {
            connectAgentRelays()
        }

        var didSucceed: Bool?

        agentPool.request(ev) { result, relay in
            DispatchQueue.main.async {
                if didSucceed != true {
                    didSucceed = true
                    successHandler?(result)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if didSucceed == nil {
                didSucceed = false
                errorHandler?()
            }
        }
    }

    func request(_ ev: NostrObject, errorDelay: Double = 10, successHandler: ((_ result: [JSON]) -> Void)? = nil, errorHandler: (() -> Void)? = nil) {
        var didSucceed: Bool?
        
        func resultHandler(result: [JSON], relay: String) {
            DispatchQueue.main.async {
                if didSucceed != true {
                    didSucceed = true
                    successHandler?(result)
                }                
            }
        }
        
        pool.request(ev, resultHandler)
        
        var relays = IdentityManager.instance.userRelays?.keys as? [String] ?? []
        if relays.isEmpty { relays = bootstrap_relays }
        
        if let jsonEV: JSON = ev.encodeToString()?.decode() {
            SocketRequest(name: "broadcast_events", payload: [
                "events": .array([jsonEV]),
                "relays": .array(relays.map { .string($0) })
            ])
            .publisher()
            .sink { res in
                if res.eventBroadcastSuccessful {
                    resultHandler(result: [], relay: "")
                }
            }
            .store(in: &cancellables)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + errorDelay) {
            if didSucceed == nil {
                didSucceed = false
                errorHandler?()
            }
        }
    }
}
