//
//  PageViewController.swift
//  BasicEnglishEducation
//
//  Created by D'Arco Luigi on 16/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var pageControl = UIPageControl()
    
    lazy var subViewControllers:[UIViewController] = {
        return [
            UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "Onboarding1ViewController") as! Onboarding1ViewController,
            UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "Onboarding2ViewController") as! Onboarding2ViewController,
            UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "Onboarding3ViewController") as! Onboarding3ViewController
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.dataSource = self
        
        setViewControllers([subViewControllers[0]], direction: .forward, animated: true, completion: nil)
        
        configurePageControl()
    }
    
    func configurePageControl() {
        // The total number of pages that are available is based on how many available colors we have.
        pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.maxY - 150,width: UIScreen.main.bounds.width,height: 50))
        self.pageControl.numberOfPages = subViewControllers.count
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.black
        self.pageControl.pageIndicatorTintColor = UIColor.white
        self.pageControl.currentPageIndicatorTintColor = UIColor.black
        self.view.addSubview(pageControl)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return subViewControllers.count
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.pageControl.currentPage = subViewControllers.index(of: pageContentViewController)!
    }
    
    //Page load before
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex:Int = subViewControllers.index(of: viewController) ?? 0
        if (currentIndex <= 0) {
            return nil
        }
        return subViewControllers[currentIndex-1]
    }
    
    //Page load after
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentIndex:Int = subViewControllers.index(of: viewController) ?? 0
        if (currentIndex >= subViewControllers.count - 1) {
            return nil
        }
        return subViewControllers[currentIndex+1]
    }
    
    override var prefersStatusBarHidden: Bool {
        return true;
    }
    
}
