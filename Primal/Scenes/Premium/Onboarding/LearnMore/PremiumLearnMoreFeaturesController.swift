//
//  PremiumLearnMoreFeaturesController.swift
//  Primal
//
//  Created by Pavle Stevanović on 19.11.24..
//

import Combine
import UIKit
import GenericJSON

class PremiumLearnMoreFeaturesController: UITableViewController {
    var data: [(String, PremiumLearnMoreDataCell.PossibleState, PremiumLearnMoreDataCell.PossibleState)] = [
        ("Publish agent capabilities", .check, .check),
        ("Create L402 challenges", .check, .check),
        ("Agent API access", .check, .check),
        ("Verified Nostr address", .check, .check),
        ("Custom Lightning address", .check, .check),
        ("Agent analytics", .text("Basic"), .text("Advanced")),
        ("Multi-agent management", .empty, .check),
        ("Priority support", .empty, .check),
        ("Custom integrations", .empty, .check),
    ]
    
    var didReachEnd = false
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
        
        tableView.register(PremiumLearnMoreHeaderCell.self, forCellReuseIdentifier: "header")
        tableView.register(PremiumLearnMoreDataCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = .init(top: 160, left: 0, bottom: 100, right: 0)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? 1 : data.count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let cell = cell as? PremiumLearnMoreDataCell {
            let row = data[indexPath.row]
            cell.setData(title: row.0, secondView: row.1, thirdView: row.2)
        }
        cell.updateBackground(isLast: data.count - 1 == indexPath.row)
        return cell
    }
}
