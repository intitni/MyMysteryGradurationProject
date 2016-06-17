//
//  GuessesTableViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 2/21/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

protocol GuessesTableViewControllerDelegate: class {
    func didApplyGuess(guess: SPGuess)
    func didRevokeGuess()
    func shouldShowPreviewForGuess()
}

class GuessesTableViewController: UITableViewController {
    
    weak var containerViewController: GuessesTableViewControllerDelegate?
    var editingCurve: SPCurve?
    var guesses: [SPGuess]? { return editingCurve?.guesses }
    var appliedGuess: SPGuess? { return editingCurve?.applied }


    override func viewDidLoad() {
        super.viewDidLoad()
        prepareTableView()
        self.clearsSelectionOnViewWillAppear = true
    }
    
    private func prepareTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.backgroundColor = UIColor.spGrayishWhiteColor()
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return editingCurve?.guesses.count ?? 0
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("GuessCell", forIndexPath: indexPath) as! GuessTableViewCell
        guard let gs = guesses else { return cell }
        
        let currentGuess = gs[indexPath.row]
        cell.guess = currentGuess
        cell.applied = currentGuess === appliedGuess ? true : false
        cell.delegate = self

        return cell
    }

    func reloadData() {
        let range = NSMakeRange(0, self.tableView.numberOfSections)
        let sections = NSIndexSet(indexesInRange: range)
        self.tableView.reloadSections(sections, withRowAnimation: .Automatic)
    }

}

extension GuessesTableViewController: GuessTableViewCellDelegate {
    func shouldPerformActionForCell(cell: GuessTableViewCell, revoke: Bool) {
        if revoke { containerViewController?.didRevokeGuess() }
        else { containerViewController?.didApplyGuess(cell.guess!) }
    }
    
    func shouldShowPreviewForCurrentCurveWithGuess(guess: SPGuess) {
        
    }
    
    func shouldStopShowingPreviewForCurrentCurve() {
        
    }
}
