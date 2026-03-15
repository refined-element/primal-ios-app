//
//  AgentAttestationCardView.swift
//  Primal
//
//  Card view for displaying an agent attestation/review (kind 38403).
//  Shows reviewer identity, rating, review text, agreement link, and proof indicator.
//

import UIKit

protocol AgentAttestationCardViewDelegate: AnyObject {
    func agentAttestationCardViewDidTapViewAgreement(_ view: AgentAttestationCardView)
}

final class AgentAttestationCardView: UIView, Themeable {
    weak var delegate: AgentAttestationCardViewDelegate?

    private let headerLabel = UILabel()
    private let ratingStack = UIStackView()
    private let reviewLabel = UILabel()
    private let agreementLabel = UILabel()
    private let proofIndicator = UIView()
    private let proofLabel = UILabel()
    let viewAgreementButton = UIButton(configuration: .viewAgreementButton()).constrainToSize(height: 36)

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(attestation: AgentAttestation) {
        headerLabel.text = "Review by \(String(attestation.pubkey.prefix(12)))..."

        // Build star rating
        ratingStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for i in 1...5 {
            let starImage = i <= attestation.rating ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            let starView = UIImageView(image: starImage)
            starView.tintColor = .accent
            starView.constrainToSize(width: 18, height: 18)
            ratingStack.addArrangedSubview(starView)
        }

        let ratingLabel = UILabel()
        ratingLabel.text = "\(attestation.rating)/5"
        ratingLabel.font = .appFont(withSize: 14, weight: .semibold)
        ratingLabel.textColor = .foreground2
        ratingStack.addArrangedSubview(ratingLabel)

        reviewLabel.text = attestation.content
        reviewLabel.isHidden = attestation.content.isEmpty

        if !attestation.agreementId.isEmpty {
            agreementLabel.text = "Agreement: \(String(attestation.agreementId.prefix(16)))..."
            agreementLabel.isHidden = false
            viewAgreementButton.isHidden = false
        } else {
            agreementLabel.isHidden = true
            viewAgreementButton.isHidden = true
        }

        // Proof indicator
        if let _ = attestation.proof {
            proofIndicator.backgroundColor = .systemGreen
            proofLabel.text = "Payment verified"
            proofIndicator.isHidden = false
            proofLabel.isHidden = false
        } else {
            proofIndicator.isHidden = true
            proofLabel.isHidden = true
        }
    }

    func updateTheme() {
        backgroundColor = .background3
        headerLabel.textColor = .foreground
        reviewLabel.textColor = .foreground3
        agreementLabel.textColor = .foreground2
        proofLabel.textColor = .foreground2
        viewAgreementButton.configuration = .viewAgreementButton()
    }
}

private extension AgentAttestationCardView {
    func setup() {
        headerLabel.font = .appFont(withSize: 14, weight: .bold)
        headerLabel.numberOfLines = 1

        ratingStack.axis = .horizontal
        ratingStack.spacing = 4
        ratingStack.alignment = .center

        reviewLabel.font = .appFont(withSize: 14, weight: .regular)
        reviewLabel.numberOfLines = 4

        agreementLabel.font = .appFont(withSize: 12, weight: .regular)
        agreementLabel.numberOfLines = 1

        proofIndicator.constrainToSize(width: 8, height: 8)
        proofIndicator.layer.cornerRadius = 4

        proofLabel.font = .appFont(withSize: 12, weight: .regular)

        let proofRow = UIStackView([proofIndicator, proofLabel])
        proofRow.spacing = 6
        proofRow.alignment = .center

        viewAgreementButton.addAction(.init(handler: { [weak self] _ in
            guard let self else { return }
            self.delegate?.agentAttestationCardViewDidTapViewAgreement(self)
        }), for: .touchUpInside)

        let buttonRow = UIStackView([viewAgreementButton])
        buttonRow.alignment = .center

        let mainStack = UIStackView(axis: .vertical, [headerLabel, ratingStack, reviewLabel, agreementLabel, proofRow, buttonRow])
        mainStack.spacing = 8
        mainStack.alignment = .leading
        mainStack.setCustomSpacing(12, after: proofRow)

        addSubview(mainStack)
        mainStack.pinToSuperview(padding: 16)

        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.foreground6.cgColor

        updateTheme()
    }
}

extension UIButton.Configuration {
    static func viewAgreementButton() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.borderless()
        var container = AttributeContainer()
        container.font = UIFont.appFont(withSize: 14, weight: .semibold)
        configuration.attributedTitle = AttributedString("View Agreement", attributes: container)
        configuration.image = UIImage(systemName: "doc.text")
        configuration.imagePadding = 6
        configuration.baseForegroundColor = .accent
        configuration.background.backgroundColor = .accent.withAlphaComponent(0.1)
        configuration.cornerStyle = .capsule
        configuration.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        return configuration
    }
}
