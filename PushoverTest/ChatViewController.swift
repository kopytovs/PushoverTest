//
//  ViewController.swift
//  PushoverTest
//
//  Created by Sergey Kopytov on 31.08.2018.
//  Copyright © 2018 Sergey Kopytov. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MessageViewController
import ReverseExtension
import DatePickerDialog

class ChatViewController: MessageViewController {
    
    //pushover constants
    let appToken = "aadrkip1t1n4prq531ss7vi14zup6r"
    let name = "u3ba37zs37ftt72cab43qwp2xofidn"
    
    //arrays for Table View
    private var messages: [String] = []
    private var times: [String] = []
    
    //Outlets
    @IBOutlet weak var messageTableView: UITableView!
    @IBOutlet weak var qrButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set up message View library
        self.messageViewSettings()
        //Set up Table View
        self.setTableView()
        
        //Set up storage messages
        messages = UserDefaults.standard.array(forKey: "PushoverMessages") != nil ? UserDefaults.standard.array(forKey: "PushoverMessages") as! [String] : [String]()
        times = UserDefaults.standard.array(forKey: "PushoverTimes") != nil ? UserDefaults.standard.array(forKey: "PushoverTimes") as! [String] : [String]()
        
    }
    
    @IBAction func pressQRButton(_ sender: Any) {
        //I can do smth
    }
    
    @IBAction func unwindToChat(segue:UIStoryboardSegue) { }
    
    private func messageViewSettings(){
        setup(scrollView: messageTableView)
        
        // Border
        borderColor = .lightGray
        
        // Change the appearance
        messageView.inset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        messageView.textView.placeholderText = "New message..."
        messageView.textView.placeholderTextColor = .lightGray
        messageView.font = .systemFont(ofSize: 17)
        
        // Setup the button
        messageView.setButton(title: "Send", for: .normal, position: .right)
        messageView.addButton(target: self, action: #selector(onRightButton), position: .right)
        messageView.rightButtonTint = .blue
        
        //messageView.setButton(title: "Delay", for: .normal, position: .left)
        messageView.setButton(icon: #imageLiteral(resourceName: "DelayImage"), for: .normal, position: .left)
        messageView.addButton(target: self, action: #selector(onLeftButton), position: .left)
        messageView.leftButtonTint = .orange
    }
    
    //right selector
    @objc func onRightButton(){
        self.makeBubble(delay: 0.0)
    }
    
    //left selector
    @objc func onLeftButton(){
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        DatePickerDialog().show("Delay", doneButtonTitle: "Send", cancelButtonTitle: "Cancel", defaultDate: Date(), minimumDate: Date(timeIntervalSinceNow: 1), maximumDate: Date(timeIntervalSinceNow: 86400), datePickerMode: UIDatePickerMode.time) { (date) in
            if let dt = date{
                print(dt)
                self.makeBubble(delay: dt.timeIntervalSinceNow)
            } else {
                print("Time Picker Error")
            }
        }
    }
    
    //func for making bubble of message
    private func makeBubble(delay: Double){
        
        if !messageView.text.isEmpty {
            let date = Date(timeIntervalSinceNow: delay)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm dd.MM.yy"
            let (message, time) = (messageView.textView.text!, formatter.string(from: date))
            messages.insert(message, at: 0)
            times.insert(time, at: 0)
            messageView.textView.text = ""
        
            UserDefaults.standard.set(messages, forKey: "PushoverMessages")
            UserDefaults.standard.set(times, forKey: "PushoverTimes")
            self.messageTableView.reloadData()
        
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(delay)), execute: {
            self.sendMessage(msg: message)
            })
        } else{
            let alert = UIAlertController(title: "Error", message: "You can't send empty messages", preferredStyle: UIAlertControllerStyle.alert)
            let OK = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OK)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //func for sending message to PushOver
    private func sendMessage(msg: String){
        
        let params: JSON = ["token": appToken, "user": name, "message": msg]
        
        Alamofire.request("https://api.pushover.net/1/messages.json", method: .post, parameters: params.dictionaryObject, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            switch response.result{
            case .success(let data):
                print(data)
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
}

//Set up table view
extension ChatViewController: UITableViewDelegate, UITableViewDataSource{
    
    private func setTableView(){
        self.messageTableView.dataSource = self
        self.messageTableView.delegate = self
        self.messageTableView.rowHeight = UITableViewAutomaticDimension
        self.messageTableView.re.delegate = self
        self.messageTableView.separatorStyle = .none
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
        let (message, time) = (messages[indexPath.row], times[indexPath.row])
        cell.messageLabel.text = message
        cell.timestampLabel.text = time
        cell.bubbleView.layer.cornerRadius = 10
        return cell
    }
    
}

