//
//  DragController.swift
//  
//
//  Created by Yanik Simpson on 7/19/20.
//

import UIKit

/// Make this property weak to prevent a retain cycle. Don't worry about setting this.
public protocol DragControllerStateManager: class {
    var currentPosition: Int { get set }
}

/// Used to configure the DragView contents. Inherits from UITableViewDataSource & UITableViewDelegate.
public protocol DragControllerDelegate: UITableViewDataSource, UITableViewDelegate {
    var controller: DragControllerStateManager? { get set }
    func scrollViewDidScroll(_ scrollView: UIScrollView)
}

extension DragControllerDelegate {
    public func handleStateChange(scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -(scrollView.frame.height * 0.12) {
            if controller?.currentPosition == 0 { return }
            controller?.currentPosition -= 1
        }
    }
}

/// The possible heights with datasources for the dragView.
public struct DragControllerState {
    var dataSource: DragControllerDelegate?
    let height: CGFloat
    
    public init(dataSource: DragControllerDelegate?, height: CGFloat) {
        self.dataSource = dataSource
        self.height = height
    }
}

public final class DragController: DragControllerStateManager {
    
    // MARK: Properties
    
    private(set) var configuration: [DragControllerState]
    
    var currentState: DragControllerState {
        return configuration[currentPosition]
    }
    public var currentPosition: Int = 0 {
        didSet {
            presentationStateChangeHandler?(currentState, shouldScroll)
        }
    }
    var shouldScroll: Bool {
        return currentPosition == (configuration.count-1)
    }
    
    // MARK: Callbacks
    
    var presentationStateChangeHandler: ((DragControllerState, Bool) -> Void)?
    
    // MARK: Initializer
    
    init(configuration: [DragControllerState]) {
        self.configuration = configuration.sorted(by: { $0.height < $1.height })
        self.configuration.forEach({ $0.dataSource?.controller = self })
    }
    
    // MARK: Methods
    
    func changeState(for currentHeight: CGFloat) {
        var absoluteValueAndConfigIndex = [(offset: Int, element: CGFloat)]()
        
        for config in configuration.enumerated() {
            let diffFromConfig = abs(currentHeight - config.element.height)
            absoluteValueAndConfigIndex.append((config.offset, diffFromConfig))
        }
        
        let sortedResults = absoluteValueAndConfigIndex.sorted(by: { $0.element < $1.element })
        
        currentPosition = sortedResults.first!.offset
    }
}


