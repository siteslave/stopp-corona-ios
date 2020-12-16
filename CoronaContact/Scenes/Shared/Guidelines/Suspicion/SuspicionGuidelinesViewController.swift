//
//  SuspicionGuidelinesViewController.swift
//  CoronaContact
//

import Reusable
import UIKit

final class SuspicionGuidelinesViewController: UIViewController, StoryboardBased, ViewModelBased, FlashableScrollIndicators {
    var viewModel: SuspicionGuidelinesViewModel?

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var instructionsView: InstructionsView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        flashScrollIndicators()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            viewModel?.viewClosed()
        }
    }

    private func setupUI() {
        title = "suspicion_guidelines_title".localized

        instructionsView.instructions = [
            .init(index: 1, text: "suspicion_guidelines_precaution_first".localized),
            .init(index: 2, text: "suspicion_guidelines_precaution_second".localized),
            .init(index: 3, text: "suspicion_guidelines_precaution_third".localized),
            .init(index: 4, text: "suspicion_guidelines_precaution_fourth".localized),
            .init(index: 5, text: "suspicion_guidelines_precaution_fifth".localized),
            .init(index: 6, text: "suspicion_guidelines_precaution_sixth".localized),
        ]
    }

    @IBAction func buttonTapped(_ sender: Any) {
        viewModel?.buttonTapped()
    }
}
