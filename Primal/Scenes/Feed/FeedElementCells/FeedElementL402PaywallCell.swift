//
//  FeedElementL402PaywallCell.swift
//  Primal
//
//  Feed cell that displays an L402 paywall for gated premium content.
//

import UIKit

class FeedElementL402PaywallCell: FeedElementBaseCell, RegularFeedElementCell {
    static var cellID: String { "FeedElementL402PaywallCell" }

    let paywallView = L402PaywallView()
    private var currentPostId: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(paywallView)
        paywallView
            .pinToSuperview(edges: .top, padding: 8)
            .pinToSuperview(edges: .bottom, padding: 0)
            .pinToSuperview(edges: .horizontal, padding: 16)

        paywallView.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func update(_ content: ParsedContent) {
        currentPostId = content.post.id
        guard let gate = content.l402Gate else { return }

        let isUnlocking = L402ContentManager.instance.isUnlocking(content.post.id)
        let isUnlocked = L402ContentManager.instance.isUnlocked(content.post.id)
        paywallView.configure(gate: gate, isUnlocking: isUnlocking, isUnlocked: isUnlocked)
        paywallView.updateTheme()
    }

    override func updateTheme() {
        super.updateTheme()
        paywallView.updateTheme()
    }
}

extension FeedElementL402PaywallCell: L402PaywallViewDelegate {
    func l402PaywallViewDidTapUnlock(_ view: L402PaywallView) {
        delegate?.postCellDidTap(self, .unlockL402)
    }
}
