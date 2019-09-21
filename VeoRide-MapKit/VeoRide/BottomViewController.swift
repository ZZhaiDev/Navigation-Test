//
//  BottomViewController.swift
//  VeoRide
//
//  Created by zijia on 9/20/19.
//  Copyright © 2019 zijia. All rights reserved.
//

import UIKit

struct Turndata {
    var instruction: String
    var distance: Double
    var totleDistance: Double
    var totleTime: Double
    
    init(instruction: String, distance: Double, totleDistance: Double, totleTime: Double) {
        self.instruction = instruction
        self.distance = distance
        self.totleTime = totleTime
        self.totleDistance = totleDistance
    }
}

protocol BottomViewControllerDelegate: class{
    func bottomViewControllerDelegateCancelButtonClicked()
}

class BottomViewController: UIViewController {
    
    var datas: Turndata? {
        didSet {
            guard let datas = datas else { return }
            instructionLabel.text = String(datas.instruction)
            distanceLabel.text = String(datas.distance)
            totelDistance.text = String(datas.totleDistance)
            totleTime.text = String(datas.totleTime)
        }
    }
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var totelDistance: UILabel!
    @IBOutlet weak var totleTime: UILabel!
    
    weak var delegate: BottomViewControllerDelegate?

    @IBAction func cancelButtonClicked(_ sender: Any) {
        delegate?.bottomViewControllerDelegateCancelButtonClicked()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
