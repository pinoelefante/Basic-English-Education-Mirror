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
    @IBOutlet weak var voiceText: UILabel!
    @IBOutlet weak var voiceType: UISwitch!
    @IBOutlet weak var voiceRateSlider: UISlider!
    @IBOutlet weak var voiceRateLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        self.soundOn.isOn = SettingsManager.isSoundOn
        self.textSizeSlider.value = Float(SettingsManager.fontSize)
        self.textSizeLabel.text = "\(SettingsManager.fontSize)"
        self.voiceText.text = "Voice: \(SettingsManager.isSoundVoiceFemale ? "Female" : "Male")"
        self.voiceType.isOn = SettingsManager.isSoundVoiceFemale
        self.voiceRateSlider.value = (SettingsManager.voiceRate * 10)
        self.voiceRateLabel.text = "\(SettingsManager.voiceRate * 2)"
    }
    @IBAction func soundOnChanged(_ sender: UISwitch) {
        SettingsManager.isSoundOn = soundOn.isOn
    }
    @IBAction func textsizeChanged(_ sender: UISlider) {
        let fontSize = Int(textSizeSlider.value);
        SettingsManager.fontSize = fontSize
        textSizeLabel.text = fontSize.description
    }
    @IBAction func voiceChanged(_ sender: UISwitch) {
        let voiceOn = voiceType.isOn
        voiceText.text = "Voice: \(voiceOn ? "Female" : "Male")"
        SettingsManager.isSoundVoiceFemale = voiceOn
    }
    @IBAction func voiceRateChanged(_ sender: UISlider) {
        let value = Int(sender.value)
        let f_value = Float(value)/Float(10)
        voiceRateLabel.text = "\(f_value * 2)"
        SettingsManager.voiceRate = f_value
    }
}
