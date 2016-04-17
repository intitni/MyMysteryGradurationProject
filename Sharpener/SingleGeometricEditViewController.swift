//
//  SingleGeometricEditViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 2/21/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

import UIKit

class SingleGeometricEditViewController: UIViewController {

    @IBOutlet weak var navigationBar: ProcessingNavigationBar! {
        didSet {
            navigationBar.buttonDelegate = self
        }
    }
    @IBOutlet weak var displayView: SPDisplayView! {
        didSet {
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(SingleGeometricEditViewController.swipeOnDisplayView(_:)))
            swipeRight.direction = UISwipeGestureRecognizerDirection.Right
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(SingleGeometricEditViewController.swipeOnDisplayView(_:)))
            swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
            displayView.addGestureRecognizer(swipeRight)
            displayView.addGestureRecognizer(swipeLeft)
        }
    }
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var smoothnessControl: SPSmoothControl! {
        didSet {
            smoothnessControl.smoothDelegate = self
        }
    }
    
    /// The geometric that should be editted, passed on segue.
    var geometric: SPGeometrics? {
        didSet {
            editingCurve = geometric?.lines.first
        }
    }
    /// The curve editting.
    var editingCurve: SPCurve? {
        didSet {
            if guessesTableViewController != nil {
                guessesTableViewController.editingCurve = editingCurve
            }
            drawDispalyView()
        }
    }
    /// Showing guesses for a SPCurve, set in embedded segue.
    var guessesTableViewController: GuessesTableViewController! {
        didSet {
            guessesTableViewController.containerViewController = self
        }
    }
    var guessesTableView: UITableView { return guessesTableViewController.tableView }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        drawDispalyView()
    }

    func drawDispalyView() {
        guard editingCurve != nil && geometric != nil && displayView != nil else { return }
        displayView.showGeometric(geometric!, andHighlightCurve: editingCurve!)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let identifier = segue.identifier
        switch identifier {
        case .Some("EditEmbbedGuesses"):
            if let toVC = segue.destinationViewController as? GuessesTableViewController {
                guessesTableViewController = toVC
                toVC.containerViewController = self
                toVC.editingCurve = editingCurve
            }
        default: break
        }
    }

}

extension SingleGeometricEditViewController: ProcessingNavigationBarDelegate {
    func didTapOnNavigationBarButton(index: Int) {
        switch index {
        case 0:
            performSegueWithIdentifier("UnwindEditToVectorize", sender: self)
        case 1:
            performSegueWithIdentifier("UnwindEditToVectorize", sender: self)
        default: break
        }
    }
    
    var processingNavigationBarRightButtonText: String { return "" }
}

extension SingleGeometricEditViewController: SPSmoothControlDelegate {
    func smoothnessChangedTo(smoothness: CGFloat) {
        guard editingCurve != nil && editingCurve?.smoothness != smoothness else { return }
        let approx = SPBezierPathApproximator(smoothness: smoothness)
        approx.approximate(editingCurve!)
        drawDispalyView()
    }
}

extension SingleGeometricEditViewController: GuessesTableViewControllerDelegate {
    func didRevokeGuess() {
        editingCurve?.applied = nil
        guessesTableViewController.reloadData()
        drawDispalyView()
    }
    
    func didApplyGuess(guess: SPGuess) {
        editingCurve?.applied = guess
        guessesTableViewController.reloadData()
        drawDispalyView()
    }
    
    func shouldShowPreviewForGuess() {
        
    }
}

// MARK: - Gesture Handling

extension SingleGeometricEditViewController {
    func swipeOnDisplayView(recognizer: UISwipeGestureRecognizer) {
        if case .Ended = recognizer.state {
            let direction = recognizer.direction
            guard let currentIndex = geometric?.lines.indexOf({ $0 === editingCurve! }) as Int? else {
                return
            }
            var newIndex = currentIndex
            
            if direction == UISwipeGestureRecognizerDirection.Right {
                newIndex -= 1
                if newIndex < 0 { newIndex = geometric!.lines.endIndex - 1 }
            }
            if direction == UISwipeGestureRecognizerDirection.Left {
                newIndex += 1
                if newIndex >= geometric?.lines.endIndex { newIndex = 0 }
            }
            
            if newIndex != currentIndex {
                editingCurve = geometric?.lines[newIndex]
                guessesTableViewController.reloadData()
                smoothnessControl.smoothness = editingCurve?.smoothness ?? 0
            }
        }
    }
}