//
//  PreferencesViewController.swift
//  Barista
//
//  Created by Franz Greiling on 21.06.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {
    @IBOutlet weak var launchAtLoginButton: NSButton!
    
    @IBOutlet @objc weak var buttonTurnOffAfter: NSButton!
    @IBOutlet weak var buttonTurnOffMorning: NSButton!
    
    @IBOutlet weak var slider: TimeIntervalSlider!
    @IBOutlet weak var selectedTimeField: NSTextField!
    
    @objc dynamic private var defaultTimeout: Int = 0
    
    // MARK: - View Events
    override func viewDidLoad() {
        super.viewDidLoad()
        
        slider.timeIntervals = [60, 300, 600, 900, 1800, 2700, 3600, 5400, 7200, 10800, 14400, 18000, 21600]
        slider.labelForTickMarks = [0, 3, 6, 9, 12]
        
        // Register Timeout with User Defaults
        self.defaultTimeout = UserDefaults.standard.defaultTimeout
        UserDefaults.standard.bind(
            NSBindingName(rawValue: UserDefaults.Keys.defaultTimeout),
            to: self,
            withKeyPath: #keyPath(defaultTimeout),
            options: nil)
        
        slider.timeValue = Double(self.defaultTimeout)
        slider.isEnabled = !UserDefaults.standard.endOfDaySelected

        self.launchAtLoginButton.bind(
            NSBindingName("value"),
            to: NSApp.delegate as! AppDelegate,
            withKeyPath: #keyPath(AppDelegate.launchAtLogin),
            options: [
                NSBindingOption.raisesForNotApplicableKeys: true,
                NSBindingOption.conditionallySetsEnabled: true
            ]
        )
    }
    
    // MARK: - Interface Actions
    @IBAction func defaultDurationTypeSelected(_ sender: NSButton) {
        slider.isEnabled = sender == buttonTurnOffAfter
    }
    
    @IBAction func durationSliderChanged(_ sender: TimeIntervalSlider) {
        switch NSApp.currentEvent!.type {
        case .leftMouseDown:
            selectedTimeField.isHidden = false
            fallthrough
        case .leftMouseDragged:
            selectedTimeField.stringValue =
                sender.timeValue > 0 ? sender.timeValue.simpleFormat()! : sender.infinityLabel
            self.defaultTimeout = Int(sender.timeValue/60) * 60
        case .leftMouseUp:
            selectedTimeField.isHidden = true
        default:
            break
        }
    }
}