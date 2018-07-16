//
//  SettingsManager.swift
//  Education
//
//  Created by Elefante Giuseppe on 12/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import Foundation

class SettingsManager
{
    static let soundSettingName = "SoundSetting"
    static let soundVoiceSettingName = "SoundVoiceSetting"
    static let fontSizeSettingName = "FontSizeSetting"
    static let userPointsSettingName = "PointsSetting"
    
    static var points : Float{
        get{
            return getValue(setting: userPointsSettingName, defValue: 0) as! Float
        }
        set {
            setValue(setting: fontSizeSettingName, value: newValue)
        }
    }
    static var fontSize : Int{
        get{
            return getValue(setting: fontSizeSettingName, defValue: 16) as! Int
        }
        set{
            setValue(setting: fontSizeSettingName, value: newValue)
        }
    }
    static var isSoundOn : Bool {
        get{
            return getValue(setting: soundSettingName, defValue: true) as! Bool
        }
        set{
            setValue(setting: soundSettingName, value: newValue)
        }
    }
    static var isSoundVoiceFemale : Bool {
        get{
            return getValue(setting: soundVoiceSettingName, defValue: true) as! Bool
        }
        set{
            setValue(setting: soundVoiceSettingName, value: newValue)
        }
    }
    
    static func setValue(setting key:String, value:Any)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    static func getValue(setting key:String, defValue:Any) -> Any? {
        let res = UserDefaults.standard.object(forKey: key) ?? defValue
        return res
    }
}
