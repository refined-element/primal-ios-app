//
//  FeedElementASAContractCell.swift
//  Primal
//
//  Feed cell that displays an Agent Service Agreement (kind 38402).
//

import UIKit

class FeedElementASAContractCell: FeedElementBaseCell, RegularFeedElementCell {
    static var cellID: String { "FeedElementASAContractCell" }

    let contractView = ASAContractCardView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contractView)
        contractView
            .pinToSuperview(edges: .top, padding: 8)
            .pinToSuperview(edges: .bottom, padding: 0)
            .pinToSuperview(edges: .horizontal, padding: 16)

        contractView.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func update(_ content: ParsedContent) {
        guard let agreement = content.agentServiceAgreement else { return }
        contractView.configure(agreement: agreement)
        contractView.updateTheme()
    }

    override func updateTheme() {
        super.updateTheme()
        contractView.updateTheme()
    }
}

extension FeedElementASAContractCell: ASAContractCardViewDelegate {
    func asaContractCardViewDidTapView(_ view: ASAContractCardView) {
        delegate?.postCellDidTap(self, .viewASA)
    }

    func asaContractCardViewDidTapSettle(_ view: ASAContractCardView) {
        delegate?.postCellDidTap(self, .settleASA)
    }
}
