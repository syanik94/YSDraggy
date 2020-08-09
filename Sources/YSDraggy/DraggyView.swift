import UIKit

public protocol DragViewDelegate: class {
    func dragViewDidScroll(_ dragView: DragView)
    func dragViewDidBeginScrolling(_ dragView: DragView)
}

public class DragView: UIView {
    
    // MARK: Properties
    
    private(set) var controller: DragController!
    
    weak var delegate: (DragViewDelegate & UITableViewDelegate)?
    
    public var currentStateIndex: Int {
        return controller.currentPosition
    }
    
    public var tableViewStyle = UITableView.Style.plain
    public var tableViewPadding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    // MARK: View
    
    public lazy var tableView: UITableView = makeTableView()
    public lazy var dragIndicator: UIView = makeDragIndicator()
    
    // MARK: Gestures
    
    private lazy var panGesture: UIPanGestureRecognizer = makePanGesture()
    
    // MARK: Initializer
    
    public init(configuration: [DragControllerState]) {
        controller = DragController(configuration: configuration)
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: controller.configuration.first!.height).isActive = true
        observePresentationStateChanges()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        roundTopCorners(radius: 16)
        setupView()
    }
    
    // MARK: - Observe Changes
    
    private func observePresentationStateChanges() {
        controller.presentationStateChangeHandler = { [unowned self] newState, shouldScroll in
            self.panGesture.cancel()
            
            self.tableView.dataSource = newState.dataSource
            self.tableView.delegate = newState.dataSource

            
            let heightForState: CGFloat = newState.height
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                self.constraints.first { $0.firstAnchor == self.heightAnchor }?.isActive = false
                self.heightAnchor.constraint(equalToConstant: heightForState).isActive = true
            })
        }
    }
    
    // MARK: View Setup
    
    func setupView() {
        addGestureRecognizer(panGesture)
        
        addSubview(dragIndicator)
        dragIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        dragIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: tableViewPadding.bottom).isActive = true
        tableView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: tableViewPadding.left).isActive = true
        tableView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: tableViewPadding.right).isActive = true
        tableView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: tableViewPadding.top).isActive = true
    }
    
    fileprivate func makeDragIndicator() -> UIView {
        let view = UIView()
        view.layer.cornerRadius = 3
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 6).isActive = true
        view.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return view
    }
    
    fileprivate func makeTableView() -> UITableView {
        let view = UITableView(frame: .zero, style: tableViewStyle)
        view.dataSource = controller.currentState.dataSource
        view.delegate = controller.currentState.dataSource
        view.isScrollEnabled = false
        view.bounces = false
        return view
    }
    
    fileprivate func makePanGesture() -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleDefaultPan))
        gesture.maximumNumberOfTouches = 1
        gesture.minimumNumberOfTouches = 1
        return gesture
    }
    
    // MARK: Methods
    
    private var startPosition = CGPoint()
    private var currentPosition = CGPoint()
    
    @objc private func handleDefaultPan(gesture: UIPanGestureRecognizer) {
        guard gesture.translation(in: self).y != 0 else { return }
        
        gesture.require(toFail: tableView.panGestureRecognizer)
        
        let swipeVelocity = -gesture.velocity(in: self).y
                
        if gesture.state == .began {
            if ((controller.currentPosition == controller.configuration.count-1) && swipeVelocity > 0) { return }
            startPosition = gesture.location(in: self)
        }
        
        if gesture.state == .began || gesture.state == .changed {
            if ((controller.currentPosition == controller.configuration.count-1) && swipeVelocity > 0) { return }
            currentPosition = gesture.location(in: self)
            
            if frame.height == controller.configuration.first!.height && swipeVelocity < 0 {
                return
            }
            
            if frame.height == controller.configuration.last!.height && swipeVelocity > 0 {
                return
            }
            
            let difference = startPosition.y - currentPosition.y
            handleDragHeightUpdate(newHeight: frame.height + difference)
        }
        
        if gesture.state == .ended {
            if ((controller.shouldScroll) && swipeVelocity > 0) { return }
            controller.changeState(for: bounds.height)
        }
    }
    
    private func handleDragHeightUpdate(newHeight: CGFloat) {
        self.constraints.first { $0.firstAnchor == self.heightAnchor }?.isActive = false
        UIView.animate(withDuration: 0) {
            self.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
        }
    }
}

extension DragView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension UIPanGestureRecognizer {
    func cancel() {
        isEnabled = false
        isEnabled = true
    }
}
