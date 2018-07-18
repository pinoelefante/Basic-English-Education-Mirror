//
//  SettingsViewController.swift
//  Education
//
//  Created by Elefante Giuseppe on 12/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import UIKit

class SettingsViewController : UIViewController
{
    @IBOutlet weak var soundOn: UISwitch!
    @IBOutlet weak var textSizeSlider: UISlider!
    @IBOutlet weak var textSizeLabel: UILabel!
    @IBOutlet weak var voiceRateSlider: UISlider!
    @IBOutlet weak var voiceRateLabel: UILabel!
    @IBOutlet weak var voiceTypeSelector: UISegmentedControl!
    
    override func viewWillAppear(_ animated: Bool) {
        self.soundOn.isOn = SettingsManager.isSoundOn
        self.textSizeSlider.value = Float(SettingsManager.fontSize)
        self.textSizeLabel.text = "\(SettingsManager.fontSize)"
        self.voiceTypeSelector.selectedSegmentIndex = SettingsManager.isSoundVoiceFemale ? 0 : 1
        self.voiceTypeSelector.isHidden = !SettingsManager.isSoundOn
        self.voiceRateSlider.value = (SettingsManager.voiceRate * 10)
        self.voiceRateLabel.text = "\(SettingsManager.voiceRate * 2)"
    }
    @IBAction func soundOnChanged(_ sender: UISwitch) {
        SettingsManager.isSoundOn = soundOn.isOn
        self.voiceTypeSelector.isHidden = !soundOn.isOn
    }
    @IBAction func textsizeChanged(_ sender: UISlider) {
        let fontSize = Int(textSizeSlider.value);
        SettingsManager.fontSize = fontSize
        textSizeLabel.text = fontSize.description
    }
    @IBAction func voiceRateChanged(_ sender: UISlider) {
        let value = Int(sender.value)
        let f_value = Float(value)/Float(10)
        voiceRateLabel.text = "\(f_value * 2)"
        SettingsManager.voiceRate = f_value
    }
    @IBAction func voiceTypeChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        SettingsManager.isSoundVoiceFemale = index == 0
    }
}
