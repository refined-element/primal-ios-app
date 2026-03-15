//
//  FeedElementAgentAttestationCell.swift
//  Primal
//
//  Feed cell that displays an agent attestation/review (kind 38403).
//

import UIKit

class FeedElementAgentAttestationCell: FeedElementBaseCell, RegularFeedElementCell {
    static var cellID: String { "FeedElementAgentAttestationCell" }

    let attestationView = AgentAttestationCardView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(attestationView)
        attestationView
            .pinToSuperview(edges: .top, padding: 8)
            .pinToSuperview(edges: .bottom, padding: 0)
            .pinToSuperview(edges: .horizontal, padding: 16)

        attestationView.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func update(_ content: ParsedContent) {
        guard let attestation = content.agentAttestation else { return }
        attestationView.configure(attestation: attestation)
        attestationView.updateTheme()
    }

    override func updateTheme() {
        super.updateTheme()
        attestationView.updateTheme()
    }
}

extension FeedElementAgentAttestationCell: AgentAttestationCardViewDelegate {
    func agentAttestationCardViewDidTapViewAgreement(_ view: AgentAttestationCardView) {
        delegate?.postCellDidTap(self, .viewASA)
    }
}
