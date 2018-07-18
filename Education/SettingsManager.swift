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
    private static let soundSettingName = "SoundSetting"
    private static let soundVoiceSettingName = "SoundVoiceSetting"
    private static let fontSizeSettingName = "FontSizeSetting"
    private static let userPointsSettingName = "PointsSetting"
    private static let firstStartSettingName = "FirstStartSetting"
    private static let voiceRateSettingName = "VoiceRateSetting"
    private static let listenRepeatSettingName = "ListenRepeatSetting"
    
    static var points : Int{
        get{
            return getValue(setting: userPointsSettingName, defValue: 0) as! Int
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
    static var isFirstStart : Bool {
        get{
            return getValue(setting: firstStartSettingName, defValue: true) as! Bool
        }
        set{
            setValue(setting: firstStartSettingName, value: newValue)
        }
    }
    static var voiceRate : Float {
        get {
            return getValue(setting: voiceRateSettingName, defValue: Float(0.4)) as! Float
        }
        set{
            setValue(setting: voiceRateSettingName, value: newValue)
        }
    }
    static var isListenRepeatEnabled : Bool {
        get{
            return getValue(setting: listenRepeatSettingName, defValue: true) as! Bool
        }
        set{
            setValue(setting: listenRepeatSettingName, value: newValue)
        }
    }
    
    private static func setValue(setting key:String, value:Any)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    private static func getValue(setting key:String, defValue:Any) -> Any? {
        let res = UserDefaults.standard.object(forKey: key) ?? defValue
        return res
    }
}
