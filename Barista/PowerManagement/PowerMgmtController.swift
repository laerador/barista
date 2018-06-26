//
//  PowerMgmtController.swift
//  Barista
//
//  Created by Franz Greiling on 24.06.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

class PowerMgmtController: NSObject {
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if UserDefaults.standard.shouldActivateOnLaunch {
            self.preventSleep()
        }
        
        self.preventDisplaySleep = UserDefaults.standard.preventDisplaySleep
        UserDefaults.standard.bind(
            NSBindingName(rawValue: UserDefaults.Keys.preventDisplaySleep),
            to: self,
            withKeyPath: #keyPath(preventDisplaySleep),
            options: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { _ in
            guard UserDefaults.standard.stopAtForcedSleep else { return }
            guard let assertion = self.assertion, assertion.enabled else { return }
            
            self.stopPreventingSleep(reason: .SystemWake)
        }
    }
    
    deinit {
        self.timeoutTimer?.invalidate()
        //self.monitorTimer?.invalidate()
    }
    
    
    // MARK: - Managing System Sleep
    private var assertion: UserAssertion?
    private var timeoutTimer: Timer?
    
    var isPreventingSleep: Bool {
        get {
            guard let assertion = self.assertion else { return false }
            return assertion.enabled
        }
    }
    
    @objc dynamic var preventDisplaySleep: Bool = true {
        didSet {
            guard let assertion = self.assertion else { return }
            assertion.preventsDisplaySleep = self.preventDisplaySleep
        }
    }
    
    var timeLeft: UInt? {
        get {
            return assertion?.timeLeft
        }
    }
    
    func preventSleep() {
        if UserDefaults.standard.endOfDaySelected {
            self.preventSleepUntilEndOfDay()
        } else {
            self.preventSleep(withTimeout: UInt(UserDefaults.standard.defaultTimeout))
        }
    }
    
    func preventSleep(until: Date) {
        self.preventSleep(withTimeout: UInt((until.timeIntervalSinceNow)))

    }
    
    func preventSleep(withTimeout timeout: UInt) {
        // Stop any running assertion
        stopPreventingSleep()
        
        // Create new assertion
        guard let assertion = UserAssertion.createAssertion(
            withName: Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String,
            timeout: timeout,
            thatPreventsDisplaySleep: UserDefaults.standard.preventDisplaySleep
            ) else { return }
        
        self.assertion = assertion
        
        if timeout > 0 {
            self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout+2), repeats: false) { _ in
                guard let assertion = self.assertion, !assertion.enabled else { return }
                self.stopPreventingSleep(reason: .Timeout)
            }
        }
        
        self.notifyStartedPreventingSleep(for: TimeInterval(timeout))
    }
    
    func preventSleepUntilEndOfDay() {
        // Find the next 3:00am date that's more than 30 minutes in the future
        var nextDate: Date = Date()
        
        let hour = min(max(UserDefaults.standard.endOfDayTime, 0), 23)
        
        repeat {
            nextDate = Calendar.current.nextDate(
                after: nextDate,
                matching: DateComponents(hour: hour, minute: 0, second: 0),
                matchingPolicy: .nextTime)!
        } while nextDate.timeIntervalSinceNow < 1800
        
        self.preventSleep(until: nextDate)
    }
    
    func stopPreventingSleep() {
        self.stopPreventingSleep(reason: .Deactivated)
    }
    
    private func stopPreventingSleep(reason: StoppedPreventingSleepReason) {
        guard let assertion = self.assertion else { return }
        
        self.timeoutTimer?.invalidate()
        self.notifyStoppedPreventingSleep(after: Date().timeIntervalSince(assertion.timeStarted), because: reason)
        self.assertion = nil
    }
    
    
    // MARK: - Obervation
    private var observers = [PowerMgmtObserver]()
    
    func addObserver(_ observer: PowerMgmtObserver) {
        observers.append(observer)
    }
    
    func removeObserver(_ observer: PowerMgmtObserver) {
        observers = observers.filter { $0 !== observer }
    }
    
    
    private func notifyStartedPreventingSleep(for timeout: TimeInterval) {
        observers.forEach { $0.startedPreventingSleep(for: timeout) }
    }
    
    private func notifyStoppedPreventingSleep(after timeout: TimeInterval, because reason: StoppedPreventingSleepReason) {
        observers.forEach { $0.stoppedPreventingSleep(after: timeout, because: reason) }
    }
}