import UIKit

public protocol DragViewDelegate: class {
    func dragViewDidScroll(_ dragView: DragView)
    func dragViewDidBeginScrolling(_ dragView: DragView)
}

public class DragView: UIView {
    
    // MARK: Properties
    
    private(set) var controller: DragController!
    
    weak var delegate: (DragViewDelegate & UITableViewDelegate)?
    
    // MARK: View
    
    let dragIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 6).isActive = true
        view.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return view
    }()
    
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.dataSource = controller.currentState.dataSource
        view.delegate = controller.currentState.dataSource
        view.isScrollEnabled = false
        return view
    }()
    
    // MARK: Gestures
    
    private lazy var defaultPanGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleDefaultPan))
        return gesture
    }()
    
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupView()
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: controller.configuration.first!.height).isActive = true
        observePresentationStateChanges()
    }
    
    private func observePresentationStateChanges() {
        controller.presentationStateChangeHandler = { [unowned self] newState, shouldScroll in
            self.defaultPanGesture.cancel()
            
            self.tableView.isScrollEnabled = shouldScroll
            self.tableView.dataSource = newState.dataSource
            self.tableView.alpha = 0
            
            UIView.animate(withDuration: 0.35) {
                self.tableView.reloadData()
                self.tableView.alpha = 1
            }
            
            let heightForState: CGFloat = newState.height
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: .curveLinear, animations: {
                self.constraints.first { $0.firstAnchor == self.heightAnchor }?.isActive = false
                self.heightAnchor.constraint(equalToConstant: heightForState).isActive = true
            })
        }
    }
    
    // MARK: View Setup
    
    func setupView() {
        layer.cornerRadius = 16
        backgroundColor = .white
        
        addGestureRecognizer(defaultPanGesture)
        
        addSubview(dragIndicator)
        dragIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        dragIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor).isActive = true
    }
    
    // MARK: Methods
    
    private var startPosition = CGPoint()
    private var currentPosition = CGPoint()
    
    @objc private func handleDefaultPan(gesture: UIPanGestureRecognizer) {
        guard gesture.translation(in: self).y != 0 else { return }
        
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

extension UIPanGestureRecognizer {
    func cancel() {
        isEnabled = false
        isEnabled = true
    }
}
