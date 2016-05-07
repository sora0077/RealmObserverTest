//
//  ViewController.swift
//  RealmObserverTest
//
//  Created by 林達也 on 2016/05/07.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import RealmSwift


func async(delay: Double, _ block: () -> Void) {
    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    
    dispatch_after(when, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
}


func tick() {
    dispatch_async(dispatch_get_main_queue()) {
        NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
    }
}


class ViewController: UIViewController {
    
    let doTick = true
    
    let tableView = UITableView()

    let dataSource = (try! Realm()).objects(User)
    
    var token: NotificationToken!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        token = dataSource.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .Initial:
                tableView.reloadData()
            case let .Update(_, deletions: deletions, insertions: insertions, modifications: modifications):
                tableView.beginUpdates()
                
                tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
                tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
                tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
                tableView.endUpdates()
                
            case .Error(let error):
                fatalError("\(error)")
            }
        }
        
        if !dataSource.isEmpty {
            fetch()
        }
    }
    
    private var fetching = false
    private func fetch() {
        if fetching { return }
        fetching = true
        async(0.1) {
            let realm = try! Realm()
            try! realm.write {
                for _ in 0..<20 {
                    let user = User()
                    user.name = "\(arc4random_uniform(10000))"
                    realm.add(user)
                }
            }
            print("fetched!")
            self.fetching = false
            if self.doTick {
                tick()
            }
        }
    }
    
    private func removeAll() {
        
        async(0.1) {
            let realm = try! Realm()
            try! realm.write {
                realm.delete(realm.objects(User))
            }
            self.fetch()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let user = dataSource[indexPath.row]
        cell.textLabel?.text = user.name
        
        if max(0, dataSource.count - 20) == indexPath.row {
            fetch()
        }
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        removeAll()
    }
}
