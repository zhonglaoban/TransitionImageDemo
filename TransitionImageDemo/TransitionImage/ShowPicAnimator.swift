//
//  ShowPicAnimator.swift
//
//  Created by 钟凡 on 15/12/27.
//  Copyright © 2015年 zhongfan. All rights reserved.
//

import UIKit

class ShowPicAnimator: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    var isPresent: Bool = true
    var dummyView: UIView?
    var sourceRect: CGRect = CGRect.zero
    var destRect: CGRect = CGRect.zero
    // 指定谁负责转场动画
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresent = true
        return self
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresent = false
        return self
    }
    //UIViewControllerAnimatedTransitioning
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    /* self实现动画
    1. 计算动画的起始位置
    2. 计算动画的目标位置
    */
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)

        if isPresent {
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
            let toView = toVC!.view
            //添加临时视图
            let blackView = UIView(frame: toView!.bounds)
            blackView.backgroundColor = UIColor.black
            transitionContext.containerView.addSubview(blackView)
            transitionContext.containerView.addSubview(dummyView!)
            
            dummyView?.frame = sourceRect
            dummyView?.alpha = 0
            blackView.alpha = 0
            UIView.animate(withDuration: duration, animations: { () -> Void in
                self.dummyView?.frame = self.destRect
                self.dummyView?.alpha = 1
                blackView.alpha = 1
            },completion: { (_) -> Void in
                // 删除临时视图
                blackView.removeFromSuperview()
                self.dummyView!.removeFromSuperview()
                //添加目标视图
                transitionContext.containerView.insertSubview(toView!, at: 0)
                transitionContext.completeTransition(true)
            })

        }else {
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
            // 隐藏 fromView
            fromVC!.view?.isHidden = true
            // 将fromView 添加到容器视图中
            transitionContext.containerView.addSubview(dummyView!)
            
            UIView.animate(withDuration: duration,
                animations: { () -> Void in
                    self.dummyView!.frame = self.sourceRect
                }, completion: { (_) -> Void in
                    transitionContext.completeTransition(true)
            })
        }
    }
}
