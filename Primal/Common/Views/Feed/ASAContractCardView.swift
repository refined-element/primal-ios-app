//
//  ASAContractCardView.swift
//  Primal
//
//  Card view for displaying an Agent Service Agreement (kind 38402).
//  Shows provider/requester, status badge, terms, and action buttons.
//

import UIKit

protocol ASAContractCardViewDelegate: AnyObject {
    func asaContractCardViewDidTapView(_ view: ASAContractCardView)
    func asaContractCardViewDidTapSettle(_ view: ASAContractCardView)
}

final class ASAContractCardView: UIView, Themeable {
    weak var delegate: ASAContractCardViewDelegate?

    private let titleLabel = UILabel()
    private let providerLabel = UILabel()
    private let requesterLabel = UILabel()
    private let statusBadge = UILabel()
    private let statusContainer = UIView()
    private let termsStack = UIStackView()
    let viewButton = UIButton(configuration: .viewDetailsButton()).constrainToSize(height: 36)
    let settleButton = UIButton(configuration: .settleL402Button()).constrainToSize(height: 36)

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(agreement: AgentServiceAgreement) {
        titleLabel.text = "Service Agreement"

        // Provider / requester
        if let provider = agreement.providerPubkey {
            providerLabel.text = "Provider: \(String(provider.prefix(8)))..."
            providerLabel.isHidden = false
        } else {
            providerLabel.isHidden = true
        }

        if let requester = agreement.requesterPubkey {
            requesterLabel.text = "Requester: \(String(requester.prefix(8)))..."
            requesterLabel.isHidden = false
        } else {
            requesterLabel.isHidden = true
        }

        // Status badge
        statusBadge.text = agreement.status.rawValue.capitalized
        let statusColor: UIColor = {
            switch agreement.status {
            case .active:       return .systemGreen
            case .completed:    return .systemBlue
            case .disputed:     return .systemRed
            case .expired:      return .systemGray
            case .proposed:     return .systemYellow
            }
        }()
        statusContainer.backgroundColor = statusColor.withAlphaComponent(0.15)
        statusBadge.textColor = statusColor

        // Terms
        termsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for term in agreement.terms {
            let row = makeTermRow(term)
            termsStack.addArrangedSubview(row)
        }
        termsStack.isHidden = agreement.terms.isEmpty

        // Buttons
        settleButton.isHidden = agreement.status != .active
    }

    func updateTheme() {
        backgroundColor = .background3
        titleLabel.textColor = .foreground
        providerLabel.textColor = .foreground2
        requesterLabel.textColor = .foreground2
        viewButton.configuration = .viewDetailsButton()
        settleButton.configuration = .settleL402Button()
    }

    private func makeTermRow(_ term: ASATerm) -> UIView {
        let label = UILabel()
        label.text = "\(term.type): \(term.value) \(term.unit)"
        label.font = .appFont(withSize: 13, weight: .regular)
        label.textColor = .foreground3
        return label
    }
}

private extension ASAContractCardView {
    func setup() {
        titleLabel.font = .appFont(withSize: 16, weight: .bold)
        titleLabel.numberOfLines = 1

        providerLabel.font = .appFont(withSize: 13, weight: .regular)
        requesterLabel.font = .appFont(withSize: 13, weight: .regular)

        statusBadge.font = .appFont(withSize: 11, weight: .semibold)
        statusContainer.layer.cornerRadius = 10
        statusContainer.addSubview(statusBadge)
        statusBadge
            .pinToSuperview(edges: .vertical, padding: 4)
            .pinToSuperview(edges: .horizontal, padding: 8)

        termsStack.axis = .vertical
        termsStack.spacing = 4

        viewButton.addAction(.init(handler: { [weak self] _ in
            guard let self else { return }
            self.delegate?.asaContractCardViewDidTapView(self)
        }), for: .touchUpInside)

        settleButton.addAction(.init(handler: { [weak self] _ in
            guard let self else { return }
            self.delegate?.asaContractCardViewDidTapSettle(self)
        }), for: .touchUpInside)

        let buttonRow = UIStackView([viewButton, settleButton])
        buttonRow.spacing = 8
        buttonRow.alignment = .center

        let mainStack = UIStackView(axis: .vertical, [titleLabel, statusContainer, providerLabel, requesterLabel, termsStack, buttonRow])
        mainStack.spacing = 8
        mainStack.alignment = .leading
        mainStack.setCustomSpacing(12, after: termsStack)

        addSubview(mainStack)
        mainStack.pinToSuperview(padding: 16)

        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.foreground6.cgColor

        updateTheme()
    }
}

extension UIButton.Configuration {
    static func viewDetailsButton() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.borderless()
        var container = AttributeContainer()
        container.font = UIFont.appFont(withSize: 14, weight: .semibold)
        configuration.attributedTitle = AttributedString("View Details", attributes: container)
        configuration.baseForegroundColor = .accent
        configuration.cornerStyle = .capsule
        configuration.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        configuration.background.strokeColor = .accent
        configuration.background.strokeWidth = 1
        return configuration
    }

    static func settleL402Button() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.borderless()
        var container = AttributeContainer()
        container.font = UIFont.appFont(withSize: 14, weight: .semibold)
        configuration.attributedTitle = AttributedString("Settle via L402", attributes: container)
        configuration.image = UIImage(systemName: "bolt.fill")
        configuration.imagePadding = 4
        configuration.baseForegroundColor = .white
        configuration.background.backgroundColor = .accent
        configuration.cornerStyle = .capsule
        configuration.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        return configuration
    }
}
