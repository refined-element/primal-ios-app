//
//  FeedElementAgentServiceRequestCell.swift
//  Primal
//
//  Feed cell that displays an agent service request (kind 38401).
//

import UIKit

class FeedElementAgentServiceRequestCell: FeedElementBaseCell, RegularFeedElementCell {
    static var cellID: String { "FeedElementAgentServiceRequestCell" }

    let requestView = AgentServiceRequestCardView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(requestView)
        requestView
            .pinToSuperview(edges: .top, padding: 8)
            .pinToSuperview(edges: .bottom, padding: 0)
            .pinToSuperview(edges: .horizontal, padding: 16)

        requestView.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func update(_ content: ParsedContent) {
        guard let request = content.agentServiceRequest else { return }
        requestView.configure(request: request)
        requestView.updateTheme()
    }

    override func updateTheme() {
        super.updateTheme()
        requestView.updateTheme()
    }
}

extension FeedElementAgentServiceRequestCell: AgentServiceRequestCardViewDelegate {
    func agentServiceRequestCardViewDidTapRespond(_ view: AgentServiceRequestCardView) {
        delegate?.postCellDidTap(self, .requestAgentService)
    }
}
