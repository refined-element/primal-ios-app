//
//  AgentFeedViewController.swift
//  Primal
//
//  Dedicated feed for browsing agent capabilities, service requests,
//  and active agreements. Accessible from Dev Mode settings.
//

import UIKit
import Combine

final class AgentFeedViewController: NoteViewController {

    private var agentCancellables: Set<AnyCancellable> = []
    private var hasSubscribed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Agent Services"
        navigationItem.leftBarButtonItem = customBackButton

        // Lazy relay connection: only subscribe when the user opens this screen
        if !hasSubscribed {
            ASAManager.instance.subscribeToAgentEvents()
            hasSubscribed = true
        }

        loadAgentPosts()

        // React to live capability/request/agreement changes from the relay
        ASAManager.instance.$discoveredCapabilities
            .combineLatest(
                ASAManager.instance.$pendingRequests,
                ASAManager.instance.$activeAgreements,
                ASAManager.instance.$attestations
            )
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                self?.loadAgentPosts()
            }
            .store(in: &agentCancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        mainTabBarController?.setTabBarHidden(false, animated: animated)
    }

    // MARK: - Data Loading

    private func loadAgentPosts() {
        var agentPosts: [ParsedContent] = []

        // Demo posts when demo mode is on
        if ASAManager.demoModeEnabled {
            agentPosts.append(contentsOf: AgentDemoData.generateDemoPosts())
        }

        // Live discovered capabilities from relays
        let now = Date().timeIntervalSince1970
        for cap in ASAManager.instance.discoveredCapabilities {
            let reputationDisplay = ASAManager.instance.getReputationDisplay(for: cap.pubkey)
            let displaySuffix = reputationDisplay.map { " \($0)" } ?? ""
            let post = PrimalFeedPost(
                id: cap.id, kind: NostrKind.agentCapability.rawValue,
                pubkey: cap.pubkey, created_at: Double(cap.createdAt),
                tags: [], content: cap.content, sig: "",
                likes: 0, mentions: 0, replies: 0, zaps: 0,
                satszapped: 0, score24h: 0, reposts: 0
            )
            let user = ParsedUser(data: PrimalUser(
                id: cap.pubkey, pubkey: cap.pubkey,
                npub: "", name: String(cap.pubkey.prefix(8)),
                about: reputationDisplay ?? "", picture: "",
                nip05: "", banner: "",
                displayName: cap.serviceId + displaySuffix, location: "",
                lud06: "", lud16: "", website: cap.l402Endpoint ?? "",
                tags: [], created_at: now, sig: "", deleted: false
            ))
            let content = ParsedContent(post: post, user: user)
            content.agentCapability = cap
            content.text = cap.content

            // Avoid duplicates with demo data
            if !agentPosts.contains(where: { $0.post.id == cap.id }) {
                agentPosts.append(content)
            }
        }

        // Live service requests
        for req in ASAManager.instance.pendingRequests {
            let post = PrimalFeedPost(
                id: req.id, kind: NostrKind.agentServiceRequest.rawValue,
                pubkey: req.pubkey, created_at: Double(req.createdAt),
                tags: [], content: req.content, sig: "",
                likes: 0, mentions: 0, replies: 0, zaps: 0,
                satszapped: 0, score24h: 0, reposts: 0
            )
            let user = ParsedUser(data: PrimalUser(
                id: req.pubkey, pubkey: req.pubkey,
                npub: "", name: String(req.pubkey.prefix(8)),
                about: "", picture: "",
                nip05: "", banner: "",
                displayName: req.requestId, location: "",
                lud06: "", lud16: "", website: "",
                tags: [], created_at: now, sig: "", deleted: false
            ))
            let content = ParsedContent(post: post, user: user)
            content.agentServiceRequest = req
            content.text = req.content

            if !agentPosts.contains(where: { $0.post.id == req.id }) {
                agentPosts.append(content)
            }
        }

        // Live active agreements
        for asa in ASAManager.instance.activeAgreements {
            let post = PrimalFeedPost(
                id: asa.id, kind: NostrKind.agentServiceAgreement.rawValue,
                pubkey: asa.pubkey, created_at: Double(asa.createdAt),
                tags: [], content: asa.content, sig: "",
                likes: 0, mentions: 0, replies: 0, zaps: 0,
                satszapped: 0, score24h: 0, reposts: 0
            )
            let user = ParsedUser(data: PrimalUser(
                id: asa.pubkey, pubkey: asa.pubkey,
                npub: "", name: String(asa.pubkey.prefix(8)),
                about: "", picture: "",
                nip05: "", banner: "",
                displayName: asa.agreementId, location: "",
                lud06: "", lud16: "", website: "",
                tags: [], created_at: now, sig: "", deleted: false
            ))
            let content = ParsedContent(post: post, user: user)
            content.agentServiceAgreement = asa
            content.text = asa.content

            if !agentPosts.contains(where: { $0.post.id == asa.id }) {
                agentPosts.append(content)
            }
        }

        // Live attestations
        for att in ASAManager.instance.attestations {
            let post = PrimalFeedPost(
                id: att.id, kind: NostrKind.agentAttestation.rawValue,
                pubkey: att.pubkey, created_at: Double(att.createdAt),
                tags: [], content: att.content, sig: "",
                likes: 0, mentions: 0, replies: 0, zaps: 0,
                satszapped: 0, score24h: 0, reposts: 0
            )
            let user = ParsedUser(data: PrimalUser(
                id: att.pubkey, pubkey: att.pubkey,
                npub: "", name: String(att.pubkey.prefix(8)),
                about: "", picture: "",
                nip05: "", banner: "",
                displayName: att.attestationId, location: "",
                lud06: "", lud16: "", website: "",
                tags: [], created_at: now, sig: "", deleted: false
            ))
            let content = ParsedContent(post: post, user: user)
            content.agentAttestation = att
            content.text = att.content

            if !agentPosts.contains(where: { $0.post.id == att.id }) {
                agentPosts.append(content)
            }
        }

        // Sort newest first
        agentPosts.sort { $0.post.created_at > $1.post.created_at }

        posts = agentPosts
    }
}
