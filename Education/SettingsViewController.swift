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
    
    
    override func viewDidLoad() {
        
    }
    override func viewWillAppear(_ animated: Bool) {
        self.soundOn.isOn = SettingsManager.isSoundOn
        self.textSizeSlider.value = Float(SettingsManager.fontSize)
        self.textSizeLabel.text = "\(SettingsManager.fontSize)"
        self.voiceText.text = "Voice: \(SettingsManager.isSoundVoiceFemale ? "Female" : "Male")"
        self.voiceType.isOn = SettingsManager.isSoundVoiceFemale
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
}
