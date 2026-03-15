//
//  AgentServiceRequestCardView.swift
//  Primal
//
//  Card view for displaying an agent service request (kind 38401).
//  Shows request description, categories, budget, and deadline.
//

import UIKit

protocol AgentServiceRequestCardViewDelegate: AnyObject {
    func agentServiceRequestCardViewDidTapRespond(_ view: AgentServiceRequestCardView)
}

final class AgentServiceRequestCardView: UIView, Themeable {
    weak var delegate: AgentServiceRequestCardViewDelegate?

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let categoryStack = UIStackView()
    private let budgetLabel = UILabel()
    private let deadlineLabel = UILabel()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(request: AgentServiceRequest) {
        titleLabel.text = "Service Request"
        descriptionLabel.text = request.content

        // Clear and rebuild category pills
        categoryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for category in request.categories {
            let pill = makeCategoryPill(category)
            categoryStack.addArrangedSubview(pill)
        }

        // Budget
        if let budget = request.budgetSats {
            budgetLabel.text = "Budget: \(budget.localized()) sats"
            budgetLabel.isHidden = false
        } else {
            budgetLabel.isHidden = true
        }

        // Deadline
        if let deadline = request.deadline {
            let deadlineDate = Date(timeIntervalSince1970: TimeInterval(deadline))
            let now = Date()
            if deadlineDate > now {
                let interval = deadlineDate.timeIntervalSince(now)
                let hours = Int(interval / 3600)
                if hours > 24 {
                    let days = hours / 24
                    deadlineLabel.text = "Expires in \(days) day\(days == 1 ? "" : "s")"
                } else {
                    deadlineLabel.text = "Expires in \(hours) hour\(hours == 1 ? "" : "s")"
                }
            } else {
                deadlineLabel.text = "Expired"
            }
            deadlineLabel.isHidden = false
        } else {
            deadlineLabel.isHidden = true
        }
    }

    func updateTheme() {
        backgroundColor = .background3
        titleLabel.textColor = .foreground
        descriptionLabel.textColor = .foreground3
        budgetLabel.textColor = .foreground
        deadlineLabel.textColor = .foreground2
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

private extension AgentServiceRequestCardView {
    func setup() {
        titleLabel.font = .appFont(withSize: 16, weight: .bold)
        titleLabel.numberOfLines = 1

        descriptionLabel.font = .appFont(withSize: 14, weight: .regular)
        descriptionLabel.numberOfLines = 3

        categoryStack.axis = .horizontal
        categoryStack.spacing = 6
        categoryStack.alignment = .center

        budgetLabel.font = .appFont(withSize: 15, weight: .semibold)

        deadlineLabel.font = .appFont(withSize: 12, weight: .regular)

        let mainStack = UIStackView(axis: .vertical, [titleLabel, categoryStack, budgetLabel, deadlineLabel, descriptionLabel])
        mainStack.spacing = 8
        mainStack.alignment = .leading

        addSubview(mainStack)
        mainStack.pinToSuperview(padding: 16)

        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.foreground6.cgColor

        updateTheme()
    }
}
