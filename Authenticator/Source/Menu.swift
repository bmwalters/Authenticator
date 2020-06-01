//
//  Menu.swift
//  Authenticator
//
//  Copyright (c) 2018 Authenticator authors
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

import Foundation

struct Menu: Component {
    private let infoList: InfoList
    private var child: Child

    private enum Child {
        case none
        case info(Info)
        case displayOptions(DisplayOptions)
        case exportData(ExportData)

        func viewModel(digitGroupSize: Int) -> Menu.ViewModel.Child {
            switch self {
            case .none:
                return .none
            case .info(let info):
                return .info(info.viewModel)
            case .displayOptions(let displayOptions):
                return .displayOptions(displayOptions.viewModel(digitGroupSize: digitGroupSize))
            case .exportData(let exportData):
                return .exportData(exportData.viewModel())
            }
        }
    }

    init() {
        infoList = InfoList()
        child = .none
    }

    init(info: Info) {
        infoList = InfoList()
        child = .info(info)
    }

    // MARK: View

    func viewModel(digitGroupSize: Int) -> ViewModel {
        return ViewModel(infoList: infoList.viewModel, child: child.viewModel(digitGroupSize: digitGroupSize))
    }

    struct ViewModel {
        let infoList: InfoList.ViewModel
        let child: Child

        enum Child {
            case none
            case info(Info.ViewModel)
            case displayOptions(DisplayOptions.ViewModel)
            case exportData(ExportData.ViewModel)
        }
    }

    // MARK: Update

    enum Action {
        case dismissInfo
        case dismissDisplayOptions
        case dismissExportData

        case infoListEffect(InfoList.Effect)
        case infoEffect(Info.Effect)
        case displayOptionsEffect(DisplayOptions.Effect)
        case exportDataEffect(ExportData.Effect)
    }

    enum Effect {
        case dismissMenu
        case showErrorMessage(String)
        case showSuccessMessage(String)
        case openURL(URL)
        case setDigitGroupSize(Int)
        case exportData
    }

    mutating func update(with action: Action) throws -> Effect? {
        switch action {
        case .dismissInfo:
            try dismissInfo()
            return nil

        case .dismissDisplayOptions:
            try dismissDisplayOptions()
            return nil

        case .dismissExportData:
            try dismissExportData()
            return nil

        case .infoListEffect(let effect):
            return try handleInfoListEffect(effect)

        case .infoEffect(let effect):
            return handleInfoEffect(effect)

        case .displayOptionsEffect(let effect):
            return handleDisplayOptionsEffect(effect)

        case .exportDataEffect(let effect):
            return handleExportDataEffect(effect)
        }
    }

    private mutating func handleInfoListEffect(_ effect: InfoList.Effect) throws -> Effect? {
        switch effect {
        case .showDisplayOptions:
            try showDisplayOptions()
            return nil

        case .showBackupInfo:
            try showExportData()
            return nil

        case .showLicenseInfo:
            let licenseInfo: Info
            do {
                licenseInfo = try Info.licenseInfo()
            } catch {
                return .showErrorMessage("Failed to load acknowledgements.")
            }
            try showInfo(licenseInfo)
            return nil

        case .done:
            return .dismissMenu
        }
    }

    private mutating func handleInfoEffect(_ effect: Info.Effect) -> Effect? {
        switch effect {
        case .done:
            return .dismissMenu
        case let .openURL(url):
            return .openURL(url)
        }
    }

    private mutating func handleDisplayOptionsEffect(_ effect: DisplayOptions.Effect) -> Effect? {
        switch effect {
        case .done:
            return .dismissMenu
        case let .setDigitGroupSize(digitGroupSize):
            return .setDigitGroupSize(digitGroupSize)
        }
    }

    private mutating func handleExportDataEffect(_ effect: ExportData.Effect) -> Effect? {
        switch effect {
        case .done:
            return .dismissMenu
        case .exportData:
            return .exportData
        }
    }

    // MARK: -

    private enum Error: Swift.Error {
        case badChildState
    }

    private mutating func showInfo(_ info: Info) throws {
        guard case .none = child else {
            throw Error.badChildState
        }
        child = .info(info)
    }

    private mutating func dismissInfo() throws {
        guard case .info = child else {
            throw Error.badChildState
        }
        child = .none
    }

    private mutating func showDisplayOptions() throws {
        guard case .none = child else {
            throw Error.badChildState
        }
        child = .displayOptions(DisplayOptions())
    }

    private mutating func dismissDisplayOptions() throws {
        guard case .displayOptions = child else {
            throw Error.badChildState
        }
        child = .none
    }

    private mutating func showExportData() throws {
        guard case .none = child else {
            throw Error.badChildState
        }
        child = .exportData(ExportData())
    }

    private mutating func dismissExportData() throws {
        guard case .exportData = child else {
            throw Error.badChildState
        }
        child = .none
    }
}
