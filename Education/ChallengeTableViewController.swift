//
//  ChallengeTableViewController.swift
//  Education
//
//  Created by Elefante Giuseppe on 17/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import UIKit

class ChallengeTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pendingChallenges = ChallengeManager.getChallengePending()
        completedChallenges = ChallengeManager.getChallengeDone()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    var pendingChallenges : [PChallengePending]!
    var completedChallenges : [PChallengeComplete]!
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch (section) {
        case 0:
            return pendingChallenges.count == 0 ? 1 : pendingChallenges.count
        case 1:
            return completedChallenges.count == 0 ? 1 : completedChallenges.count
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Pending activities"
        case 1:
            return "Completed activities"
        case 2:
            return "Points"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! ChallengeTableCell
        
        switch indexPath.section {
        case 0:
            if(pendingChallenges.count > 0){
                let p_item = pendingChallenges[indexPath.row]
                cell.challengeNameLabel.text = p_item.name
                cell.challengePointsLabel.text = "\(p_item.points)"
            }
            else
            {
                cell.challengeNameLabel.text = "There aren't challenges"
                cell.challengePointsLabel.text = ""
            }
        case 1:
            if(completedChallenges.count > 0){
                let c_itemn = completedChallenges[indexPath.row]
                cell.challengeNameLabel.text = c_itemn.name
                cell.challengePointsLabel.text = "\(c_itemn.points)"
            }
            else{
                cell.challengeNameLabel.text = "There aren't challenges"
                cell.challengePointsLabel.text = ""
            }
        case 2:
            cell.challengeNameLabel.text = "Total points"
            cell.challengePointsLabel.text = "\(SettingsManager.points)"
        default:
            break
        }
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
class ChallengeTableCell : UITableViewCell{
    @IBOutlet weak var challengeNameLabel: UILabel!
    @IBOutlet weak var challengePointsLabel: UILabel!
    
}
