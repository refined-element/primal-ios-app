//
//  AgentCapabilityCardView.swift
//  Primal
//
//  Card view for displaying an agent's capability advertisement (kind 38400).
//  Shows service name, categories, pricing, uptime, and a request button.
//

import UIKit

protocol AgentCapabilityCardViewDelegate: AnyObject {
    func agentCapabilityCardViewDidTapRequestService(_ view: AgentCapabilityCardView)
}

final class AgentCapabilityCardView: UIView, Themeable {
    weak var delegate: AgentCapabilityCardViewDelegate?

    private let serviceNameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let categoryStack = UIStackView()
    private let priceLabel = UILabel()
    private let uptimeIndicator = UIView()
    private let uptimeLabel = UILabel()
    let requestButton = UIButton(configuration: .requestServiceButton()).constrainToSize(height: 44)

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(capability: AgentCapability) {
        serviceNameLabel.text = capability.serviceId
        descriptionLabel.text = capability.content

        // Clear and rebuild category pills
        categoryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for category in capability.categories {
            let pill = makeCategoryPill(category)
            categoryStack.addArrangedSubview(pill)
        }

        // Price display - show first pricing tier
        if let firstPrice = capability.pricing.first {
            priceLabel.text = "\(firstPrice.amount) \(firstPrice.unit)/\(firstPrice.model)"
        } else {
            priceLabel.text = "Price: Contact"
        }

        // Uptime
        if let uptime = capability.uptime {
            uptimeLabel.text = String(format: "%.1f%% uptime", uptime * 100)
            uptimeIndicator.backgroundColor = uptime > 0.99 ? .systemGreen : uptime > 0.95 ? .systemYellow : .systemRed
            uptimeLabel.isHidden = false
            uptimeIndicator.isHidden = false
        } else {
            uptimeLabel.isHidden = true
            uptimeIndicator.isHidden = true
        }
    }

    func updateTheme() {
        backgroundColor = .background3
        serviceNameLabel.textColor = .foreground
        descriptionLabel.textColor = .foreground3
        priceLabel.textColor = .foreground
        uptimeLabel.textColor = .foreground2
        requestButton.configuration = .requestServiceButton()
    }

    private func makeCategoryPill(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .appFont(withSize: 11, weight: .semibold)
        label.textColor = .accent

        let container = UIView()
        container.backgroundColor = .accent.withAlphaComponent(0.15)
        container.layer.cornerRadius = 10

        container.addSubview(label)
        label
            .pinToSuperview(edges: .vertical, padding: 4)
            .pinToSuperview(edges: .horizontal, padding: 8)

        return container
    }
}

private extension AgentCapabilityCardView {
    func setup() {
        serviceNameLabel.font = .appFont(withSize: 16, weight: .bold)
        serviceNameLabel.numberOfLines = 1

        descriptionLabel.font = .appFont(withSize: 14, weight: .regular)
        descriptionLabel.numberOfLines = 3

        priceLabel.font = .appFont(withSize: 15, weight: .semibold)

        categoryStack.axis = .horizontal
        categoryStack.spacing = 6
        categoryStack.alignment = .center

        uptimeIndicator.constrainToSize(width: 8, height: 8)
        uptimeIndicator.layer.cornerRadius = 4

        uptimeLabel.font = .appFont(withSize: 12, weight: .regular)

        let uptimeRow = UIStackView([uptimeIndicator, uptimeLabel])
        uptimeRow.spacing = 6
        uptimeRow.alignment = .center

        requestButton.addAction(.init(handler: { [weak self] _ in
            guard let self else { return }
            self.delegate?.agentCapabilityCardViewDidTapRequestService(self)
        }), for: .touchUpInside)

        let buttonRow = UIStackView([requestButton])
        buttonRow.alignment = .center

        let mainStack = UIStackView(axis: .vertical, [serviceNameLabel, categoryStack, priceLabel, uptimeRow, descriptionLabel, buttonRow])
        mainStack.spacing = 8
        mainStack.alignment = .leading
        mainStack.setCustomSpacing(12, after: descriptionLabel)

        addSubview(mainStack)
        mainStack.pinToSuperview(padding: 16)

        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.foreground6.cgColor

        updateTheme()
    }
}

extension UIButton.Configuration {
    static func requestServiceButton() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.borderless()
        var container = AttributeContainer()
        container.font = UIFont.appFont(withSize: 16, weight: .semibold)
        configuration.attributedTitle = AttributedString("Request Service", attributes: container)
        configuration.image = UIImage(systemName: "paperplane.fill")
        configuration.imagePadding = 6
        configuration.baseForegroundColor = .white
        configuration.background.backgroundColor = .accent
        configuration.cornerStyle = .capsule
        configuration.contentInsets = .init(top: 10, leading: 20, bottom: 10, trailing: 20)
        return configuration
    }
}
