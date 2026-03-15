//
//  FeedElementAgentCapabilityCell.swift
//  Primal
//
//  Feed cell that displays an agent capability advertisement (kind 38400).
//

import UIKit

class FeedElementAgentCapabilityCell: FeedElementBaseCell, RegularFeedElementCell {
    static var cellID: String { "FeedElementAgentCapabilityCell" }

    let capabilityView = AgentCapabilityCardView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(capabilityView)
        capabilityView
            .pinToSuperview(edges: .top, padding: 8)
            .pinToSuperview(edges: .bottom, padding: 0)
            .pinToSuperview(edges: .horizontal, padding: 16)

        capabilityView.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func update(_ content: ParsedContent) {
        guard let capability = content.agentCapability else { return }
        capabilityView.configure(capability: capability)
        capabilityView.updateTheme()
    }

    override func updateTheme() {
        super.updateTheme()
        capabilityView.updateTheme()
    }
}

extension FeedElementAgentCapabilityCell: AgentCapabilityCardViewDelegate {
    func agentCapabilityCardViewDidTapRequestService(_ view: AgentCapabilityCardView) {
        delegate?.postCellDidTap(self, .requestAgentService)
    }
}
