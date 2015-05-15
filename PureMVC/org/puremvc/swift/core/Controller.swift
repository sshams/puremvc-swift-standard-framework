//
//  Controller.swift
//  PureMVC SWIFT Standard
//
//  Copyright(c) 2015-2025 Saad Shams <saad.shams@puremvc.org>
//  Your reuse is governed by the Creative Commons Attribution 3.0 License
//

import Foundation

/**
A Singleton `IController` implementation.

In PureMVC, the `Controller` class follows the
'Command and Controller' strategy, and assumes these
responsibilities:

* Remembering which `ICommand`s are intended to handle which `INotifications`.
* Registering itself as an `IObserver` with the `View` for each `INotification` that it has an `ICommand` mapping for.
* Creating a new instance of the proper `ICommand` to handle a given `INotification` when notified by the `View`.
* Calling the `ICommand`'s `execute` method, passing in the `INotification`.

Your application must register `ICommands` with the
Controller.

The simplest way is to subclass `Facade`,
and use its `initializeController` method to add your
registrations. 

`@see org.puremvc.swift.core.view.View View`

`@see org.puremvc.swift.patterns.observer.Observer Observer`

`@see org.puremvc.swift.patterns.observer.Notification Notification`

`@see org.puremvc.swift.patterns.command.SimpleCommand SimpleCommand`

`@see org.puremvc.swift.patterns.command.MacroCommand MacroCommand`
*/
public class Controller: IController {
    
    // Local reference to View
    private var _view: IView?
    
    // Mapping of Notification names to references of the closures that instantiates and return `ICommand` instance
    private var commandMap: [String: () -> ICommand]
    
    // Singleton instance
    private static var instance: IController?
    
    /// Message constant
    public static let SINGLETON_MSG = "Controller Singleton already constructed!"
    
    // to ensure operation happens only once
    private static var token: dispatch_once_t = 0
    
    // Concurrent queue for commandMap
    // for speed and convenience of running concurrently while reading, and thread safety of blocking while mutating
    private let commandMapQueue = dispatch_queue_create("org.puremvc.controller.commandMapQueue", DISPATCH_QUEUE_CONCURRENT)
    
    /**
    Constructor.
    
    This `IController` implementation is a Singleton,
    so you should not call the constructor
    directly, but instead call the static Singleton
    Factory method `Controller.getInstance()`
    
    @throws Error if Singleton instance has already been constructed
    */
    public init() {
        assert(Controller.instance == nil, Controller.SINGLETON_MSG)
        commandMap = [:]
        Controller.instance = self
        initializeController()
    }
    
    /**
    Initialize the Singleton `Controller` instance.
    
    Called automatically by the constructor.
    
    Note that if you are using a subclass of `View`
    in your application, you should *also* subclass `Controller`
    and override the `initializeController` method in the
    following way:
    
        // ensure that the Controller is talking to my IView implementation
        public func initializeController() {
            view = MyView.getInstance { MyView() }
        }
    */
    public func initializeController() {
        view = View.getInstance { View() }
    }
    
    /**
    `Controller` Singleton Factory method.
    
    :param: closure reference that returns `IController`
    :returns: the Singleton instance of `Controller`
    */
    public class func getInstance(closure: () -> IController) -> IController {
        dispatch_once(&self.token) {
            self.instance = closure()
        }
        return instance!
    }
    
    /**
    If an `ICommand` has previously been registered
    to handle a the given `INotification`, then it is executed.
    
    :param: note an `INotification`
    */
    public func executeCommand(notification: INotification) {
        dispatch_sync(commandMapQueue) {
            if let closure = self.commandMap[notification.name] {
                var commandInstance = closure()
                commandInstance.execute(notification)
            }
        }
    }
    
    /**
    Register a particular `ICommand` class as the handler
    for a particular `INotification`.
    
    If an `ICommand` has already been registered to
    handle `INotification`s with this name, it is no longer
    used, the new `ICommand` is used instead.
    
    The Observer for the new ICommand is only created if this the
    first time an ICommand has been regisered for this Notification name.
    
    :param: notificationName the name of the `INotification`
    :param: closure reference that instantiates and returns `ICommand`
    */
    public func registerCommand(notificationName: String, closure: () -> ICommand) {
        dispatch_barrier_sync(commandMapQueue) {
            if self.commandMap[notificationName] == nil { //weak reference to Controller (self) to avoid reference cycle with View and Observer
                self.view!.registerObserver(notificationName, observer: Observer(notifyMethod: {[weak self] notification in self!.executeCommand(notification)}, notifyContext: self))
            }
            self.commandMap[notificationName] = closure
        }
    }
    
    /**
    Check if a Command is registered for a given Notification
    
    :param: notificationName
    :returns: whether a Command is currently registered for the given `notificationName`.
    */
    public func hasCommand(notificationName: String) -> Bool {
        var result = false
        dispatch_sync(commandMapQueue) {
            result = self.commandMap[notificationName] != nil
        }
        return result
    }
    
    /**
    Remove a previously registered `ICommand` to `INotification` mapping.
    
    :param: notificationName the name of the `INotification` to remove the `ICommand` mapping for
    */
    public func removeCommand(notificationName: String) {
        if self.hasCommand(notificationName) {
            dispatch_barrier_sync(commandMapQueue) {
                self.view!.removeObserver(notificationName, notifyContext: self)
                self.commandMap[notificationName] = nil
            }
        }
    }
    
    /// Local reference to View
    public var view: IView? {
        get { return _view }
        set { _view = newValue }
    }
}