//
//  SocialViewController.swift
//  ThePost
//
//  Created by Andrew Robinson on 1/25/17.
//  Copyright © 2017 The Post. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorageUI

class SocialViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private var ref: FIRDatabaseReference!
    private var socialRef: FIRDatabaseReference?
    private var socialPosts: [SocialPost]!
        
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        ref = FIRDatabase.database().reference()
        socialPosts = []
        
        if socialRef == nil {
            socialRef = ref.child("social-posts")

            let firstOfWeek = Date().startOfWeek.timeIntervalSince1970 * 1000
            let endOfWeek = firstOfWeek + 604800000 // Add a week in milliseconds.
            let query = socialRef!.queryOrdered(byChild: "datePosted")
                .queryStarting(atValue: firstOfWeek).queryEnding(atValue: endOfWeek).queryLimited(toLast: 200)

            query.observe(.childAdded, with: { snapshot in
                if let socialDict = snapshot.value as? [String: AnyObject] {
                    
                    let date = Date(timeIntervalSince1970: Double(socialDict["datePosted"] as! NSNumber) / 1000)
                    var likes = socialDict["likeCount"] as? Int
                    if let _ = likes {
                    } else {
                        likes = 0
                    }

                    let post = SocialPost(withUid: snapshot.key, imageUrl: socialDict["image"] as! String, ownerId: socialDict["owner"] as! String, date: date, amountOfLikes: likes!)
                    
                    self.placeInOrder(post: post)
                    self.tableView.reloadData()
                }
            })
            
            socialRef!.observe(.childRemoved, with: { snapshot in
                if let socialDict = snapshot.value as? [String: AnyObject] {
                    
                    let date = Date(timeIntervalSince1970: Double(socialDict["datePosted"] as! NSNumber) / 1000)
                    var likes = socialDict["likeCount"] as? Int
                    if let _ = likes {
                    } else {
                        likes = 0
                    }

                    let post = SocialPost(withUid: snapshot.key, imageUrl: socialDict["image"] as! String, ownerId: socialDict["owner"] as! String, date: date, amountOfLikes: likes!)
                    let index = self.indexOfPost(post)
                    
                    if index != -1 {
                        self.socialPosts.remove(at: index)
                        self.tableView.reloadData()
                    }
                    
                }
            })
        }

    }
    
    
    // MARK: - TableView datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return socialPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let socialCell = tableView.dequeueReusableCell(withIdentifier: "socialCell", for: indexPath) as! JeepSocialTableViewCell
        let post = socialPosts[indexPath.row]
        
        socialCell.postImageView.image = nil
        socialCell.profileImageView.image = nil
        
        socialCell.likeCountLabel.text = "0 likes"
        socialCell.timeLabel.text = post.relativeDate
        
        socialCell.postKey = post.uid
        socialCell.ownerKey = post.ownerId
        
        return socialCell
    }
    
    // MARK: - TableView delegate
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let socialCell = cell as? JeepSocialTableViewCell {
            socialCell.grabPostImage(forKey: socialPosts[indexPath.row].uid, withURL: socialPosts[indexPath.row].imageUrl)
            socialCell.grabProfile(forKey: socialPosts[indexPath.row].ownerId)
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let socialCell = cell as? JeepSocialTableViewCell {
            socialCell.likesRef.removeAllObservers()
        }
    }
    
    // MARK: - Helpers

    private func placeInOrder(post: SocialPost) {
        if socialPosts.count == 0 {
            socialPosts.append(post)
        } else {
            var iteratorIndex = 0
            var indexToPlaceAt = -1
            for oldPost in socialPosts {
                if indexToPlaceAt == -1 {
                    if post.likes >= oldPost.likes {
                        indexToPlaceAt = iteratorIndex
                    }
                }

                iteratorIndex += 1
            }

            if indexToPlaceAt == -1 {
                indexToPlaceAt = socialPosts.count
            }

            socialPosts.insert(post, at: indexToPlaceAt)
        }
    }

    private func indexOfPost(_ snapshot: SocialPost) -> Int {
        var index = 0
        for post in socialPosts {
            
            if snapshot.uid == post.uid {
                return index
            }
            index += 1
        }
        return -1
    }

}