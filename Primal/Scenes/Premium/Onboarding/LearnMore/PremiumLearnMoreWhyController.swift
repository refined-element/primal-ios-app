//
//  PremiumLearnMoreWhyController.swift
//  Primal
//
//  Created by Pavle Stevanović on 7.11.24..
//

import UIKit

class PremiumLearnMoreWhyController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Individual Plan"
        view.backgroundColor = .background

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 6
        paragraph.alignment = .justified

        let descLabel = UILabel()
        descLabel.attributedText = .init(string: """
        The Individual plan is for solo developers and agent operators. For $99/mo, you get everything you need to publish agent capabilities, create L402 challenges, and access the full agent API on Nostr.

        Lightning Enable powers agentic commerce over Nostr, letting your agents settle payments via Lightning and discover each other through Agent Service Agreements.

        Subscribe at lightningenable.com to get started.
        """, attributes: [
            .font: UIFont.appFont(withSize: 16, weight: .regular),
            .foregroundColor: UIColor.foreground3,
            .paragraphStyle: paragraph
        ])
        descLabel.numberOfLines = 0
        
        let stack = UIStackView(axis: .vertical, [
            descLabel,
        ])
        stack.spacing = 10
        view.addSubview(stack)
        stack
            .pinToSuperview(edges: .top, padding: 70, safeArea: true)
            .pinToSuperview(edges: .horizontal, padding: 20)
        
        navigationItem.leftBarButtonItem = customBackButton
    }
}

class PremiumLearnMoreProController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Business Plan"
        view.backgroundColor = .background

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 6
        paragraph.alignment = .justified

        let descLabel = UILabel()
        descLabel.attributedText = .init(string: """
        The Business plan is for teams running agent fleets. For $299/mo, you get everything in Individual plus multi-agent management, analytics, and priority support:
        """, attributes: [
            .font: UIFont.appFont(withSize: 16, weight: .regular),
            .foregroundColor: UIColor.foreground3,
            .paragraphStyle: paragraph
        ])
        descLabel.numberOfLines = 0
        
        let firstDescLabel = UILabel()
        firstDescLabel.attributedText = .init(string: """
        Manage multiple agents from a single dashboard. Monitor performance, configure capabilities, and coordinate your fleet. Available at:
        """, attributes: [
            .font: UIFont.appFont(withSize: 15, weight: .regular),
            .foregroundColor: UIColor.foreground3,
            .paragraphStyle: paragraph
        ])
        firstDescLabel.numberOfLines = 0
        let studioButton = UIButton(configuration: .coloredButton("lightningenable.com", color: .pro), primaryAction: .init(handler: { _ in
            guard let url = URL(string: "https://lightningenable.com") else { return }
            UIApplication.shared.open(url)
        }))
        let firstVStack = UIStackView(axis: .vertical, [
            UILabel("Fleet Management", color: .foreground, font: .appFont(withSize: 16, weight: .semibold)),
            firstDescLabel,
            studioButton
        ])
        firstVStack.alignment = .leading
        
        studioButton.transform = .init(translationX: -12, y: 0)
        
        let firstStack = UIStackView([UIImageView(image: .primalGoldLogo), firstVStack])
        
        let secondDescLabel = UILabel()
        secondDescLabel.attributedText = .init(string: """
        Dedicated support channel with faster response times, custom integration assistance, and early access to new features.
        """, attributes: [
            .font: UIFont.appFont(withSize: 15, weight: .regular),
            .foregroundColor: UIColor.foreground3,
            .paragraphStyle: paragraph
        ])
        secondDescLabel.numberOfLines = 0
        let secondVStack = UIStackView(axis: .vertical, [
            UILabel("Priority Support", color: .foreground, font: .appFont(withSize: 16, weight: .semibold)),
            secondDescLabel,
        ])
        
        let secondStack = UIStackView([UIImageView(image: .legendPreston), secondVStack])
        [firstStack, secondStack].forEach {
            $0.alignment = .top
            $0.spacing = 18
            $0.isLayoutMarginsRelativeArrangement = true
            $0.insetsLayoutMarginsFromSafeArea = false
            $0.layoutMargins = .init(top: 14, left: 14, bottom: 14, right: 14)
        }
        [firstVStack, secondVStack].forEach { $0.spacing = 4 }
        
        let stack = UIStackView(axis: .vertical, [
            descLabel,
            firstStack,
            secondStack
        ])
        stack.spacing = 10
        view.addSubview(stack)
        stack
            .pinToSuperview(edges: .top, padding: 70, safeArea: true)
            .pinToSuperview(edges: .horizontal, padding: 20)
        
        navigationItem.leftBarButtonItem = customBackButton
    }
}
