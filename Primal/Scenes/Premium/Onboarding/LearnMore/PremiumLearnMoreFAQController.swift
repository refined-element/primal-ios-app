//
//  PremiumLearnMoreFAQController.swift
//  Primal
//
//  Created by Pavle Stevanović on 19.11.24..
//

import UIKit

class PremiumLearnMoreFAQController: UIViewController {
    let data: [(String, String)] = [
        ("What is Agentic Commerce?", "Agentic Commerce enables AI agents to discover each other, negotiate services, and settle payments over the Lightning Network using the Nostr protocol. Lightning Enable provides the infrastructure to make this possible."),
        ("What is the Individual plan?", "The Individual plan ($99/mo) is for solo developers and agent operators. It includes the ability to publish agent capabilities, create L402 challenges, access the agent API, and get a verified Nostr address and custom Lightning address."),
        ("What is the Business plan?", "The Business plan ($299/mo) is for businesses running agent fleets. It includes everything in Individual plus multi-agent fleet management, advanced analytics, priority support, and custom integrations."),
        ("How do I subscribe?", "Visit lightningenable.com to subscribe to a plan. Once subscribed, you will receive an API key that unlocks agent features in the app."),
        ("What are L402 challenges?", "L402 is a protocol that lets agents gate access to services behind Lightning payments. When an agent creates an L402 challenge, other agents must pay a Lightning invoice to access the service. This enables machine-to-machine commerce."),
        ("What are Agent Service Agreements?", "Agent Service Agreements (ASAs) are published on Nostr and describe what services an agent offers, its pricing, and how to interact with it. Other agents discover these agreements to find and use services."),
        ("Can I manage multiple agents?", "Yes, with the Business plan you can manage multiple agents from a single dashboard. Monitor performance, configure capabilities, and coordinate your agent fleet."),
        ("How do I get support?", "Email us at support@lightningenable.com. Business plan users get priority support with faster response times and dedicated assistance."),
        ("Is my payment information associated with my Nostr account?", "No. Your subscription is managed through lightningenable.com. Your payment information is not associated with your Nostr identity."),
        ("What features are coming next?", "We are actively building new agent capabilities including agent-to-agent negotiation, automated service discovery, and advanced L402 payment flows. Follow us on Nostr for updates.")
    ]


    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Agentic Commerce FAQ"
        view.backgroundColor = .background

        let stack = UIStackView(axis: .vertical, [])
        for (question, answer) in data {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 6
            paragraph.alignment = .justified

            let questionLabel = UILabel()
            questionLabel.numberOfLines = 0
            questionLabel.attributedText = .init(string: question, attributes: [
                .font: UIFont.appFont(withSize: 16, weight: .bold),
                .foregroundColor: UIColor.foreground,
                .paragraphStyle: paragraph
            ])
            stack.addArrangedSubview(questionLabel)
            stack.addArrangedSubview(SpacerView(height: 8))

            let descLabel = UILabel()
            descLabel.attributedText = .init(string: answer, attributes: [
                .font: UIFont.appFont(withSize: 16, weight: .regular),
                .foregroundColor: UIColor.foreground3,
                .paragraphStyle: paragraph
            ])
            descLabel.numberOfLines = 0

            stack.addArrangedSubview(descLabel)
            stack.addArrangedSubview(SpacerView(height: 30))
        }

        let support = UIButton(configuration: .accent("Lightning Enable", font: .appFont(withSize: 16, weight: .bold)))
        let supportParent = UIView()
        supportParent.addSubview(support)
        support.pinToSuperview(edges: .vertical, padding: 20).centerToSuperview(axis: .horizontal)

        stack.addArrangedSubview(supportParent)

        let scrollView = UIScrollView()
        scrollView.addSubview(stack)
        stack
            .pinToSuperview(edges: .vertical, padding: 10)
            .pinToSuperview(edges: .horizontal, padding: 20)

        view.addSubview(scrollView)
        scrollView.pinToSuperview()

        stack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40).isActive = true

        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = .init(top: 160, left: 0, bottom: 100, right: 0)

        support.addAction(.init(handler: { [weak self] _ in
            guard let premiumLearn: PremiumLearnMoreController = self?.findParent() else { return }

            premiumLearn.show(PremiumSupportPrimalController(state: WalletManager.instance.premiumState), sender: nil)
        }), for: .touchUpInside)
    }
}
