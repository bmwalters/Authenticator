//
//  ExportDataViewController.swift
//  Authenticator
//
//  Copyright (c) 2020 Authenticator authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

final class ExportDataViewController: UITableViewController {
    private let dispatchAction: (ExportData.Effect) -> Void
    private var viewModel: ExportData.ViewModel

    init(viewModel: ExportData.ViewModel, dispatchAction: @escaping (ExportData.Effect) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .otpBackgroundColor
        view.tintColor = .otpForegroundColor
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0

        // Set up top bar
        title = "Create Backup"

        let action = #selector(rightBarButtonAction)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: action)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO
        dispatchAction(.exportData)
    }

    // MARK: - Target Actions

    @objc
    func rightBarButtonAction() {
        dispatchAction(.done)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        default:
            return UITableViewCell()
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // An apparent rendering error can occur when the table view is scrolled programmatically, causing a cell
        // scrolled off of the screen to appear with a black background when scrolled back onto the screen. Setting the
        // background color of the cell to the table view's background color, instead of to `.clear`, fixes the issue.
        cell.backgroundColor = .otpBackgroundColor
        cell.selectionStyle = .none

        cell.textLabel?.textColor = .otpForegroundColor
    }
}

// MARK: - View Model Helpers

extension ExportDataViewController {
    func update(with viewModel: ExportData.ViewModel) {
        self.viewModel = viewModel
    }
}
