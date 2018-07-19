//
//  Onboarding2ViewController.swift
//  BasicEnglishEducation
//
//  Created by D'Arco Luigi on 16/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import UIKit

class Onboarding2ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override var prefersStatusBarHidden: Bool {
        return true;
    }
    @IBAction func startTapped(_ sender: UIButton) {
        SettingsManager.isFirstStart = false
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        let nextView: ViewController = mainStory.instantiateViewController(withIdentifier: "ViewController") as!  ViewController
        let app_delegate = UIApplication.shared.delegate as! AppDelegate
        app_delegate.window?.rootViewController = nextView
    }
    
}
