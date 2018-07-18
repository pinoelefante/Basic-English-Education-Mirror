//
//  ChallengeManager.swift
//  Education
//
//  Created by Elefante Giuseppe on 17/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import UIKit
import CoreData

class ChallengeManager
{
    private static let pItemPN="PItem"
    private static let completedChallengePN = "PChallengeComplete"
    private static let pendingChallengePN = "PChallengePending"
    
    static func start()
    {
        let pendingChallenges = getChallengePending()
        
        if(!pendingChallenges.isEmpty){
            let d_comp = getDateComponents(date: (pendingChallenges.first?.date)!)
            let n_comp = getDateComponents(date: Date())
            
            if(d_comp.year != n_comp.year || d_comp.month != n_comp.month || d_comp.day != n_comp.day)
            {
                generateChallenges()
            }
        }
        else if pendingChallenges.isEmpty
        {
            generateChallenges()
        }
    }
    private static func generateChallenges()
    {
        let todayItems = getItemsSeenToday()
        let context = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: pItemPN)
        fetchRequest.fetchLimit = 3
        fetchRequest.predicate = NSPredicate(format: "NOT (%K IN %@)", #keyPath(PItem.name), todayItems)
        do
        {
            let result = try context.fetch(fetchRequest) as! [PItem]
            if(!result.isEmpty)
            {
                for i in 0..<result.count
                {
                    let item = result[i]
                    let points = arc4random_uniform(6)+5
                    createPendingChallenge(name: item.name!, points: Int32(points))
                }
            }
        }
        catch{
            print(error.localizedDescription)
        }
    }
    private static func getItemsSeenToday() -> [String]
    {
        var todayComponents = getDateComponents(date: Date())
        todayComponents.hours = 0
        todayComponents.minutes = 0
        todayComponents.seconds = 1
        let todayDate = createDate(comp: todayComponents)
        let context = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: pItemPN)
        fetchRequest.predicate = NSPredicate(format: "%K >= %@", #keyPath(PItem.date), todayDate as NSDate)
        do{
            let result = try context.fetch(fetchRequest) as! [PItem]
            return result.map({$0.name!})
        }catch{
            print(error.localizedDescription)
        }
        return Array<String>()
    }
    private static func createPendingChallenge(name:String, points:Int32)
    {
        let context = getContext()
        let challenge = NSEntityDescription.insertNewObject(forEntityName: pendingChallengePN, into: context) as! PChallengePending
        
        challenge.name = name
        challenge.points = points
        challenge.date = Date()
    }
    private static func getContext() -> NSManagedObjectContext
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    private static func isChallenge(_ itemName:String) -> Bool
    {
        let challenge = getChallenge(itemName)
        return challenge != nil
    }
    static func getChallengePending() -> [PChallengePending]
    {
        let context = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: pendingChallengePN)
//        fetchRequest.predicate = NSPredicate(format: "order by date DESC")
        do
        {
            let result = try context.fetch(fetchRequest)
            if result.count > 0{
                return (result as? [PChallengePending])!
            }
        }
        catch{
            print(error.localizedDescription)
        }
        return Array<PChallengePending>()
    }
    static func getChallengeDone() -> [PChallengeComplete]
    {
        let context = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: completedChallengePN)
//        fetchRequest.predicate = NSPredicate(format: "order by date DESC")
        do
        {
            let result = try context.fetch(fetchRequest)
            if result.count > 0{
                return (result as? [PChallengeComplete])!
            }
        }
        catch{
            print(error.localizedDescription)
        }
        return Array<PChallengeComplete>()
    }
    private static func getChallenge(_ item:String) -> PChallengePending?
    {
        let context = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: pendingChallengePN)
        fetchRequest.predicate = NSPredicate(format: "%K== %@",#keyPath(PChallengePending.name), item)
        do{
            let result = try context.fetch(fetchRequest)
            if result.count > 0{
                return result.first as? PChallengePending
            }
        }catch{
            print(error.localizedDescription)
        }
        return nil
    }
    private static func getItem(_ item:String) -> PItem?
    {
        let context = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: pItemPN)
        fetchRequest.predicate = NSPredicate(format: "%K== %@", #keyPath(PItem.name), item)
        do{
            let result = try context.fetch(fetchRequest)
            if result.count > 0{
                return result.first as? PItem
            }
        }catch{
            print(error.localizedDescription)
        }
        return nil
    }
    static func itemSeen(item:String) -> Int32
    {
        var points:Int32 = 0
        if(isChallenge(item))
        {
            let challenge = getChallenge(item)!
            points = challenge.points
            completeChallenge(challenge: challenge)
        }
        else
        {
            if(alreadySeen(name: item))
            {
                let pitem = getItem(item)
                let lastTimeDifference = pitem?.date?.timeIntervalSinceNow as! Double
                points = lastTimeDifference > 86400 ? 1 : 0
                completeSeen(item: pitem!, points: points)
            }
            else
            {
                firstSeen(item: item)
                points = 5
            }
        }
        return points
    }
    private static func alreadySeen(name:String) -> Bool
    {
        let item = getItem(name)
        return item != nil
    }
    private static func completeChallenge(challenge:PChallengePending)
    {
        let context = getContext()
        
        let completed = NSEntityDescription.insertNewObject(forEntityName: completedChallengePN, into: context) as! PChallengeComplete
        
        completed.date = Date()
        completed.name = challenge.name
        completed.points = challenge.points
        
        let pItem = getItem(completed.name!)
        completeSeen(item: pItem!, points: completed.points)
        
        context.delete(challenge)
        
//        if getChallengePending().isEmpty{
//            generateChallenges()
//        }
    }
    private static func firstSeen(item:String)
    {
        let context = getContext()
        let pItem = NSEntityDescription.insertNewObject(forEntityName: pItemPN, into: context) as! PItem
        
        pItem.name = item
        pItem.count = 1
        pItem.date = Date()
    }
    private static func completeSeen(item:PItem, points:Int32)
    {
        item.date = points > 0 ? Date() : item.date
        item.count += 1
    }
    private static func getDateComponents(date:Date) -> DayComponents
    {
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let hours = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        return DayComponents(year: year, month: month, day: day, hours: hours, minutes: minutes, seconds: seconds)
    }
    private static func createDate(comp:DayComponents) -> Date
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return dateFormatter.date(from: "\(comp.day)/\(comp.month)/\(comp.year) \(comp.hours):\(comp.minutes):\(comp.seconds)")!
    }
    
    struct DayComponents
    {
        var year : Int
        var month : Int
        var day : Int
        
        var hours : Int
        var minutes : Int
        var seconds : Int
    }
}