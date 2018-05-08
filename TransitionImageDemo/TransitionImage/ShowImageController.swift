//
//  ShowImageController.swift
//
//  Created by 钟凡 on 15/12/24.
//  Copyright © 2015年 zhongfan. All rights reserved.
//

import UIKit
import AVFoundation

enum ImageAlertType:String {
    case camera = "拍照"
    case pickImage = "从相册选择"
    case saveImage = "保存到本地"
}
class ShowImageController: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    lazy var showPicDelegate = ShowPicAnimator()
    var didFinishPickingBlock:((UIImage) -> ())?
    lazy var alertTitles:[ImageAlertType] = {
       return [ImageAlertType]()
    }()
    /// 图像的缩放比例
    var scale: CGFloat = 1
    /// 滚动视图
    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView(frame: self.view.bounds)
        s.backgroundColor = UIColor.black
        // 支持缩放
        // 1. 设置代理
        s.delegate = self
        // 2. 最小大缩放比例
        s.minimumZoomScale = 1
        s.maximumZoomScale = 2.0
        
        return s
    }()
    /// 图像视图
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        
        return iv
    }()
    
    init(sourceView:UIImageView) {
        super.init(nibName: nil, bundle: nil)
        
        self.setImage(image: sourceView.image)
        let window = UIApplication.shared.keyWindow
        self.showPicDelegate.dummyView = sourceView.snapshotView(afterScreenUpdates: false)
        self.showPicDelegate.sourceRect = sourceView.convert(sourceView.bounds, to: window)
        self.showPicDelegate.destRect = imageSize(sourceView.image!)
        self.transitioningDelegate = self.showPicDelegate
        modalPresentationStyle = UIModalPresentationStyle.custom
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.keyWindow?.windowLevel = UIWindowLevelAlert
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.keyWindow?.windowLevel = UIWindowLevelNormal
    }
    deinit {
        print("ShowImageController deinit")
    }
    /// 计算图像大小
    func imageSize(_ image: UIImage?) -> CGRect {
        if image == nil {
            return .zero
        }
        let size = scaleImageSize(image!)
        var origin:CGPoint = .zero
        if size.height <= view.bounds.height {
            origin = CGPoint(x: scrollView.center.x - size.width * 0.5, y: scrollView.center.y - size.height * 0.5)
        }
        return CGRect(origin: origin, size: size)
    }
    func setImage(image: UIImage?) {
        // 设置图像
        imageView.image = image
        let rect = imageSize(image)
        imageView.frame = rect
        scrollView.contentSize = rect.size
    }
    /// 按照屏幕宽度计算缩放后的图像尺寸
    func scaleImageSize(_ image: UIImage) -> CGSize {
        let scale = image.size.width / view.bounds.size.width
        let h = image.size.height / scale
        
        return CGSize(width: view.bounds.size.width, height: h)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加滚动视图
        view.addSubview(scrollView)
        // 将图像视图添加到滚动视图中
        scrollView.addSubview(imageView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ShowImageController.close))
        self.view.addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ShowImageController.alertWithTitle(_:)))
        self.view.addGestureRecognizer(longPress)
    }
    //关闭图片查看器
    @objc func close() {
        dismiss(animated: true, completion: nil)
    }
    @objc func alertWithTitle(_ longpress:UILongPressGestureRecognizer) {
        if alertTitles.count <= 0 {
            return
        }
        if longpress.state == UIGestureRecognizerState.began {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            for title in alertTitles {
                alert.addAction(UIAlertAction(title: title.rawValue, style: .default, handler: { (action) in
                    self.handleAction(type: title)
                }))
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            }))
            
            present(alert, animated: true, completion: nil)
        }
    }
    func handleAction(type: ImageAlertType) {
        switch type {
        case .camera:
            self.camera()
            break
        case .pickImage:
            self.pickImage()
            break
        case .saveImage:
            self.saveImage()
            break
        }
    }
    // MARK:- 上传图片
    func camera() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch(authorizationStatus) {
        case .notDetermined:
            break
        case .authorized:
            break
        case .denied:
            let alert = UIAlertController(title: "您拒绝了使用相机的授权", message: "请在设备的'设置-隐私-相机'中允许应用访问相机。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { (action) in
                self.close()
            }))
            present(alert, animated: true, completion: nil)
        case .restricted:
            self.showImageNotAccessable()
        }
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    func showImageNotAccessable() {
        let alert = UIAlertController(title: "相机设备无法访问", message: "请在设备的'设置-隐私-相机'中允许应用访问相机。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { (action) in
            self.close()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    func pickImage() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if authStatus == AVAuthorizationStatus.restricted || authStatus == AVAuthorizationStatus.denied {
            self.showImageNotAccessable()
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    func saveImage() {
        
    }
    // MARK: -  imagePickerController delegate
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let editImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            didFinishPickingBlock?(editImage)
            self.setImage(image: editImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    // MARK:- 保存图片到本地
    func saveToLocal(_ image:UIImage?) {
        if image != nil {
            UIImageWriteToSavedPhotosAlbum(image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer){
        if error == nil {
            print("保存成功，到相册中查看")
        }else {
            print("保存失败，请重试")
        }
    }
    // MARK: - ScrollView 的代理
    /// 返回要缩放的视图
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var rect = imageView.frame
        rect.origin.x = 0
        rect.origin.y = 0
        if rect.width < scrollView.bounds.width {
            rect.origin.x = (scrollView.bounds.width - rect.width) / 2.0
        }
        if rect.height < scrollView.bounds.height {
            rect.origin.y = (scrollView.bounds.height - rect.height) / 2.0
        }
        imageView.frame = rect
    }
}
