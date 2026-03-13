//
//  L402PaywallView.swift
//  Primal
//
//  Paywall overlay shown on L402 gated posts. Displays price, description,
//  and unlock button. Shows loading state during payment.
//

import UIKit

protocol L402PaywallViewDelegate: AnyObject {
    func l402PaywallViewDidTapUnlock(_ view: L402PaywallView)
}

final class L402PaywallView: UIView, Themeable {
    weak var delegate: L402PaywallViewDelegate?

    let unlockButton = UIButton(configuration: .unlockButton()).constrainToSize(height: 44)

    private let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let unlockedIcon = UIImageView(image: UIImage(systemName: "lock.open.fill"))
    private let unlockedLabel = UILabel()

    private lazy var lockedStack: UIStackView = {
        let priceRow = UIStackView([lockIcon, priceLabel])
        priceRow.spacing = 6
        priceRow.alignment = .center

        let buttonRow = UIStackView([unlockButton])
        buttonRow.alignment = .center

        let stack = UIStackView(axis: .vertical, [titleLabel, priceRow, descriptionLabel, buttonRow])
        stack.spacing = 8
        stack.alignment = .center
        stack.setCustomSpacing(12, after: descriptionLabel)
        return stack
    }()

    private lazy var loadingStack: UIStackView = {
        let label = UILabel()
        label.text = "Paying invoice..."
        label.font = .appFont(withSize: 14, weight: .regular)
        label.textColor = .foreground3

        let stack = UIStackView([spinner, label])
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private lazy var unlockedStack: UIStackView = {
        let stack = UIStackView([unlockedIcon, unlockedLabel])
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(gate: L402Gate, isUnlocking: Bool, isUnlocked: Bool) {
        if isUnlocked {
            lockedStack.isHidden = true
            loadingStack.isHidden = true
            unlockedStack.isHidden = false
            spinner.stopAnimating()
            return
        }

        if isUnlocking {
            lockedStack.isHidden = true
            loadingStack.isHidden = false
            unlockedStack.isHidden = true
            spinner.startAnimating()
            return
        }

        lockedStack.isHidden = false
        loadingStack.isHidden = true
        unlockedStack.isHidden = true
        spinner.stopAnimating()

        priceLabel.text = "\(gate.priceSats.localized()) sats"
        if let desc = gate.description, !desc.isEmpty {
            descriptionLabel.text = desc
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }
    }

    func updateTheme() {
        backgroundColor = .background3
        titleLabel.textColor = .foreground
        priceLabel.textColor = .foreground
        descriptionLabel.textColor = .foreground3
        lockIcon.tintColor = .accent
        unlockedIcon.tintColor = .accent
        unlockedLabel.textColor = .foreground
        unlockButton.configuration = .unlockButton()
    }
}

private extension L402PaywallView {
    func setup() {
        titleLabel.text = "Premium Content"
        titleLabel.font = .appFont(withSize: 15, weight: .bold)

        priceLabel.font = .appFont(withSize: 20, weight: .semibold)

        descriptionLabel.font = .appFont(withSize: 14, weight: .regular)
        descriptionLabel.numberOfLines = 2

        lockIcon.constrainToSize(width: 18, height: 18)
        lockIcon.contentMode = .scaleAspectFit

        unlockedIcon.constrainToSize(width: 18, height: 18)
        unlockedIcon.contentMode = .scaleAspectFit
        unlockedLabel.text = "Content Unlocked"
        unlockedLabel.font = .appFont(withSize: 15, weight: .semibold)

        unlockButton.addAction(.init(handler: { [weak self] _ in
            guard let self else { return }
            self.delegate?.l402PaywallViewDidTapUnlock(self)
        }), for: .touchUpInside)

        let mainStack = UIStackView(axis: .vertical, [lockedStack, loadingStack, unlockedStack])
        mainStack.spacing = 0
        mainStack.alignment = .center

        addSubview(mainStack)
        mainStack.pinToSuperview(padding: 16)

        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.foreground6.cgColor

        updateTheme()
    }
}

extension UIButton.Configuration {
    static func unlockButton() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.borderless()
        var container = AttributeContainer()
        container.font = UIFont.appFont(withSize: 16, weight: .semibold)
        configuration.attributedTitle = AttributedString("Unlock with Lightning", attributes: container)
        configuration.image = UIImage(systemName: "bolt.fill")
        configuration.imagePadding = 6
        configuration.baseForegroundColor = .white
        configuration.background.backgroundColor = .accent
        configuration.cornerStyle = .capsule
        configuration.contentInsets = .init(top: 10, leading: 20, bottom: 10, trailing: 20)
        return configuration
    }
}
