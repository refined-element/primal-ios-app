//
//  OnboardingStartViewController.swift
//  Primal
//
//  Created by Pavle D Stevanović on 22.4.23..
//

import UIKit
import SafariServices
import Kingfisher

final class OnboardingMainButton: UIButton {
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.5
        }
    }
    
    init(_ title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        setTitleColor(.white.withAlphaComponent(0.5), for: .highlighted)
        titleLabel?.font = .appFont(withSize: 18, weight: .semibold)
        backgroundColor = .black.withAlphaComponent(0.81)
        layer.cornerRadius = 28
        constrainToSize(height: 56)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class OnboardingStartViewController: OnboardingBaseViewController {
    let termsBothLines = TermsAndConditionsView(whiteOverride: true)

    let signupButton = OnboardingMainButton("Create Account")
    let signinButton = OnboardingMainButton("Sign In")

    /// Placeholder for animation compatibility (replaces old screenshot image)
    let screenshot = UIView()

    private let gradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    @objc func signupPressed() {
        onboardingParent?.pushViewController(OnboardingDisplayNameController(backgroundIndex: backgroundIndex + 1), animated: true)
    }

    @objc func signinPressed() {
        if ICloudKeychainManager.instance.onlineNpubsThatAreNotInUse.isEmpty {
            onboardingParent?.pushViewController(OnboardingSigninController(backgroundIndex: backgroundIndex + 1), animated: true)
        } else {
            onboardingParent?.pushViewController(OnboardingCloudSigninController(backgroundIndex: backgroundIndex + 1), animated: true)
        }
    }
}

private extension OnboardingStartViewController {
    func setup() {
        // Dark gradient background
        gradientLayer.colors = [
            UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0).cgColor,  // #0a0a0f
            UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0).cgColor   // #1a1a2e
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)

        let containerView = UIView()
        view.addSubview(containerView)

        // Wolf icon using SF Symbol
        let wolfConfig = UIImage.SymbolConfiguration(pointSize: 72, weight: .light)
        let wolfImage = UIImage(systemName: "pawprint.fill", withConfiguration: wolfConfig)
        let wolfIcon = UIImageView(image: wolfImage)
        wolfIcon.tintColor = UIColor(red: 0.969, green: 0.576, blue: 0.102, alpha: 1.0) // #f7931a bitcoin orange
        wolfIcon.contentMode = .scaleAspectFit
        wolfIcon.translatesAutoresizingMaskIntoConstraints = false

        // App name
        let titleLabel = UILabel()
        titleLabel.text = "NostrWolfe"
        titleLabel.font = .appFont(withSize: 36, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        // Tagline
        let taglineLabel = UILabel()
        taglineLabel.text = "The Agent Commerce Layer for Nostr"
        taglineLabel.font = .appFont(withSize: 16, weight: .semibold)
        taglineLabel.textColor = UIColor(red: 0.969, green: 0.576, blue: 0.102, alpha: 1.0)
        taglineLabel.textAlignment = .center

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Agents discover, negotiate, and transact\n— all on Nostr, settled with Lightning."
        subtitleLabel.font = .appFont(withSize: 14, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.6)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Branding section (wolf + title + tagline + subtitle)
        let brandingStack = UIStackView(arrangedSubviews: [
            wolfIcon,
            SpacerView(height: 16, priority: .defaultHigh),
            titleLabel,
            SpacerView(height: 8, priority: .defaultHigh),
            taglineLabel,
            SpacerView(height: 12, priority: .defaultHigh),
            subtitleLabel
        ])
        brandingStack.axis = .vertical
        brandingStack.alignment = .center

        // Lightning bolt decorative accent
        let boltConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let boltImage = UIImage(systemName: "bolt.fill", withConfiguration: boltConfig)
        let boltIcon = UIImageView(image: boltImage)
        boltIcon.tintColor = UIColor(red: 0.969, green: 0.576, blue: 0.102, alpha: 0.3)
        boltIcon.contentMode = .scaleAspectFit

        let boltContainer = UIView()
        boltContainer.addSubview(boltIcon)
        boltIcon.centerToSuperview().pinToSuperview(edges: .vertical)

        // Full content stack
        let contentStack = UIStackView(arrangedSubviews: [
            SpacerView(height: 1, priority: .defaultLow),
            brandingStack,
            SpacerView(height: 12, priority: .defaultLow),
            boltContainer,
            SpacerView(height: 12, priority: .defaultLow),
            signinButton,
            SpacerView(height: 10, priority: .defaultHigh),
            signupButton,
            SpacerView(height: 10, priority: .defaultHigh),
            termsBothLines
        ])
        contentStack.axis = .vertical

        containerView.addSubview(contentStack)
        contentStack
            .pinToSuperview(edges: .horizontal, padding: 35)
            .pinToSuperview(edges: .bottom, padding: 12, safeArea: true)
            .pinToSuperview(edges: .top, padding: 0, safeArea: true)

        signupButton.addTarget(self, action: #selector(signupPressed), for: .touchUpInside)
        signinButton.addTarget(self, action: #selector(signinPressed), for: .touchUpInside)

        containerView.constrainToSize(width: 375, height: 800)
        containerView.centerToSuperview(axis: .horizontal)
        let centerYC = containerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        centerYC.priority = .defaultHigh
        centerYC.isActive = true
        containerView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        let scale = UIScreen.main.bounds.width / 375

        containerView.transform = .init(scaleX: scale, y: scale)
    }
}
