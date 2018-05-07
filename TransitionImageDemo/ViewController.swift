//
//  ViewController.swift
//  TransitionImageDemo
//
//  Created by 钟凡 on 2018/5/7.
//  Copyright © 2018年 钟凡. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let vc = ShowImageController(sourceView: imageView)
        vc.didFinishPickingBlock = { image in
            self.imageView.image = image
        }
        vc.alertTitles = [.camera, .pickImage]
        present(vc, animated: true, completion: nil)
    }

}

