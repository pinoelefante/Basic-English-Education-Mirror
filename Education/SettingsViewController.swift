//
//  SettingsViewController.swift
//  Education
//
//  Created by Elefante Giuseppe on 12/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import UIKit

class SettingsViewController : UITableViewController
{
    @IBOutlet weak var soundOn: UISwitch!
    @IBOutlet weak var voiceRateSlider: UISlider!
    @IBOutlet weak var voiceRateLabel: UILabel!
    @IBOutlet weak var voiceTypeSelector: UISegmentedControl!
    lazy var cartoonFont = UIFont(name: "Cartoon Relief", size: 28)
    override func viewDidLoad() {
//        voiceTypeSelector.setTitleTextAttributes([NSAttributedStringKey.font: cartoonFont!], for: .normal)
    }
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = cartoonFont
    }
    override func viewWillAppear(_ animated: Bool) {
        self.soundOn.isOn = SettingsManager.isSoundOn
        
        self.voiceTypeSelector.selectedSegmentIndex = SettingsManager.isSoundVoiceFemale ? 0 : 1
        self.voiceRateSlider.value = (SettingsManager.voiceRate * 10)
        self.voiceRateLabel.text = "\(SettingsManager.voiceRate * 2)"
    }
    @IBAction func soundOnChanged(_ sender: UISwitch) {
        SettingsManager.isSoundOn = soundOn.isOn
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
