//
//  Onboarding3ViewController.swift
//  Education
//
//  Created by Borrazzo Mauro on 19/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import UIKit

class Onboarding3ViewController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
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
    
    @IBAction func startTapped(_ sender: Any) {
        SettingsManager.isFirstStart = false
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        let nextView:UINavigationController = mainStory.instantiateViewController(withIdentifier: "MainNavigationController") as!  UINavigationController
        let app_delegate = UIApplication.shared.delegate as! AppDelegate
        app_delegate.window?.rootViewController = nextView
    }
}
