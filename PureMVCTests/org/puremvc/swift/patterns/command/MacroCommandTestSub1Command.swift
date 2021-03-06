//
//  MacroCommandTestSub1Command.swift
//  PureMVC SWIFT Standard
//
//  Copyright(c) 2015-2025 Saad Shams <saad.shams@puremvc.org>
//  Your reuse is governed by the Creative Commons Attribution 3.0 License
//

import PureMVC

public class MacroCommandTestSub1Command: SimpleCommand {
    
    /**
    Fabricate a result by multiplying the input by 2
    
    - parameter event: the `IEvent` carrying the `MacroCommandTestVO`
    */
    public override func execute(notification: INotification) {
        let vo = notification.body as! MacroCommandTestVO

        // Fabricate a result
        vo.result1 = 2 * vo.input
    }
    
}
