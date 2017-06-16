//
//  SwiftRedDot.swift
//  SwiftRedDot
//
//  Created by yumez on 2017/6/15.
//  Copyright © 2017年 yuez. All rights reserved.
//

import UIKit

enum AdhesivePlateStatus {
    case stickers  // 黏上
    case separate  // 分开
}


class SwiftRedDot: UIView {
    typealias SeparateClosure = ((UIView) -> Bool)
    
    let maxDistance: CGFloat        //黏贴效果最大距离
    let bubbleColor: UIColor
    var prototypeView: UIImageView
    var separateClosureDictionary: NSMutableDictionary
    
    
    var touchView: UIView?          // 被手势拖动的View
    var deviationPoint: CGPoint?    // 拖动坐标和 原始 view 中心的距离差
    var shapeLayer: CAShapeLayer?   // 黏贴效果的形状。
    var bubbleWidth: CGFloat?       // 被拖动的 view 的最小边长
    
    var R1, R2, X1, X2, Y1, Y2: CGFloat! //原始 view 和拖动的 view 的半径和圆心坐标
    
    // offset 指的是  pointA- pointEA2, pointEA1- pointE... 的距离，当该值设置为正方形边长的 1/3.6 倍时，画出来的圆弧近似贴合 1/4 圆;
    var offset1, offset2: CGFloat!
    
    var centerDistance: CGFloat!     // 原始view和拖动的 view 圆心距离
    var oldBackViewCenter: CGPoint?  // 原始 view 的中心坐标
    var fillColorForCute: UIColor?   // 填充黏贴效果的颜色
    var sStatus: AdhesivePlateStatus?// 黏贴状态
    var cosDigree: CGFloat!          // 两圆心所在直线和Y轴夹角的 cosine 值
    var sinDigree: CGFloat!          // 两圆心所在直线和Y轴夹角的 sine 值
    var percentage: CGFloat!         //  centerDistance/ maxDistance
    
    //圆的关键点 A,B,E 是初始位置上圆的左右后三点，C，D,F 是移动位置上的圆的三点，O，P两个圆之间画弧线所需要的点， pointTemp是辅助点。
    var pointA, pointB, pointC, pointD, pointE, pointF, pointO, pointP, pointTemp, pointTemp2: CGPoint!
    //画圆弧的辅助点
    var  pointDF1, pointDF2, pointFC1, pointFC2, pointBE1, pointBE2, pointEA1, pointEA2, pointAO1, pointAO2, pointOD1, pointOD2, pointCP1, pointCP2, pointPB1, pointPB2: CGPoint!
    
    
    var cutePath: UIBezierPath! //贝塞尔曲线
    
    
    init(maxDistance: CGFloat, bubbleColor: UIColor) {
        self.maxDistance = maxDistance
        self.bubbleColor = bubbleColor
        self.prototypeView = UIImageView()
        self.separateClosureDictionary =  NSMutableDictionary()
        
        super.init(frame: CGRect.zero)
        
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func attach(item: UIView, With separateClosure: SeparateClosure?) {
        let viewValue: NSValue = NSValue(nonretainedObject: item)
        
        if separateClosureDictionary[viewValue] == nil {
            let panG = UIPanGestureRecognizer(target: self, action: #selector(handlerPanGesture(_ :)))
            item.isUserInteractionEnabled = true
            item.addGestureRecognizer(panG)
        }
        if separateClosure != nil {
            separateClosureDictionary.setObject(separateClosure!, forKey: viewValue)
        } else {
            let closure: SeparateClosure = { UIView in  return false }
            separateClosureDictionary.setObject(closure, forKey: viewValue)
        }
        
    }
    
    
    func handlerPanGesture(_  pan: UIPanGestureRecognizer) {
        let dragPoint: CGPoint = pan.location(in: self)
        
        if pan.state == .began {
            touchView = pan.view
            let dragPontInView = pan.location(in: pan.view)
            deviationPoint = CGPoint(x: dragPontInView.x - (pan.view?.frame.size.width)! / 2, y: dragPontInView.y - (pan.view?.frame.size.height)! / 2)
            
            setUp()
        } else if pan.state == .changed {
            prototypeView.center = CGPoint(x: dragPoint.x - (deviationPoint?.x)!, y: dragPoint.y - (deviationPoint?.y)!)
            drawRect()
        } else if pan.state == .ended || pan.state == .cancelled || pan.state == .failed {
          
            if centerDistance > maxDistance {
                
                let value = NSValue(nonretainedObject: touchView)
                if let closure = separateClosureDictionary.object(forKey: value) as? SeparateClosure {
                    let animationBool = closure(touchView!)
                    if animationBool {
                        prototypeView.removeFromSuperview()
                        explosion(centerPint: prototypeView.center, radius: bubbleWidth!)
                    } else {
                        springBack(view: prototypeView, point: oldBackViewCenter!)
                    }
                }
            } else {
                fillColorForCute = .clear
                shapeLayer?.removeFromSuperlayer()
                springBack(view: prototypeView, point: oldBackViewCenter!)
            }
        }
    }
    
    
    func setUp() {
        guard let wd = UIApplication.shared.delegate?.window else { return }
        wd?.addSubview(self)
        let animationViewOrigin = touchView?.convert(CGPoint(x: 0, y: 0), to: self)
        
        prototypeView.frame = CGRect(x: (animationViewOrigin?.x)!, y: (animationViewOrigin?.y)!, width: (touchView?.frame.size.width)!, height: (touchView?.frame.size.height)!)
        prototypeView.image = getImageFrom(touchView!)
        self.addSubview(prototypeView)
        
        shapeLayer = CAShapeLayer()
        bubbleWidth = min(prototypeView.frame.size.width, prototypeView.frame.size.height) - 1
        R2 = bubbleWidth! / 2
        offset2 = R2! * 2 / 3.6
        centerDistance = 0
        oldBackViewCenter = CGPoint(x: (animationViewOrigin?.x)! + (touchView?.frame.size.width)! / 2, y: (animationViewOrigin?.y)! + (touchView?.frame.size.height)! / 2)
        X1 = oldBackViewCenter?.x
        Y1 = oldBackViewCenter?.y
        
        fillColorForCute = bubbleColor
        
        touchView?.isHidden = true
        self.isUserInteractionEnabled = true
        self.sStatus = .stickers
    }
    
    
    func drawRect() {
        X2 = prototypeView.center.x
        Y2 = prototypeView.center.y
        
        let ax: CGFloat = (X2 - X1) * (X2 - X1)
        let ay: CGFloat = (Y2 - Y1) * (Y2 - Y1)
        
        centerDistance = CGFloat( sqrtf( Float( ax + ay) ))
        if (sStatus == .separate) {
            return
        }
        
        if centerDistance > maxDistance {
            sStatus = AdhesivePlateStatus.separate
            fillColorForCute = .clear
            shapeLayer?.removeFromSuperlayer()
            return
        }
        
        if centerDistance == 0 {
            cosDigree = 1
            sinDigree = 0
        } else {
            cosDigree = (Y2 - Y1) / centerDistance
            sinDigree = (X2 - X1) / centerDistance
        }
        
        percentage = centerDistance / maxDistance
        R1 = (2 - percentage / 2) * bubbleWidth! / 4
        offset1 = R1 * 2 / 3.6
        offset2 = R2 * 2 / 3.6
        
        pointA = CGPoint(x: X1 - R1 * cosDigree, y: Y1 + R1 * sinDigree);
        pointB = CGPoint(x: X1 + R1 * cosDigree, y: Y1 - R1 * sinDigree);
        pointE = CGPoint(x: X1 - R1 * sinDigree, y: Y1 - R1 * cosDigree);
        pointC = CGPoint(x: X2 + R2 * cosDigree, y: Y2 - R2 * sinDigree);
        pointD = CGPoint(x: X2 - R2 * cosDigree, y: Y2 + R2 * sinDigree);
        pointF = CGPoint(x: X2 + R2 * sinDigree, y: Y2 + R2 * cosDigree);
        
        pointEA2 = CGPoint(x: pointA.x - offset1*sinDigree, y: pointA.y - offset1*cosDigree);
        pointEA1 = CGPoint(x: pointE.x - offset1*cosDigree, y: pointE.y + offset1*sinDigree);
        pointBE2 = CGPoint(x: pointE.x + offset1*cosDigree, y: pointE.y - offset1*sinDigree);
        pointBE1 = CGPoint(x: pointB.x - offset1*sinDigree, y: pointB.y - offset1*cosDigree);
        
        pointFC2 = CGPoint(x: pointC.x + offset2*sinDigree, y: pointC.y + offset2*cosDigree);
        pointFC1 = CGPoint(x: pointF.x + offset2*cosDigree, y: pointF.y - offset2*sinDigree);
        pointDF2 = CGPoint(x: pointF.x - offset2*cosDigree, y: pointF.y + offset2*sinDigree);
        pointDF1 = CGPoint(x: pointD.x + offset2*sinDigree, y: pointD.y + offset2*cosDigree);
        
        pointTemp = CGPoint(x: pointD.x + percentage*(X2 - pointD.x), y: pointD.y + percentage*(Y2 - pointD.y));//关键点
        pointTemp2 = CGPoint(x: pointD.x + (2 - percentage)*(X2 - pointD.x), y: pointD.y + (2 - percentage)*(Y2 - pointD.y));
        
        pointO = CGPoint(x: pointA.x + (pointTemp.x - pointA.x)/2, y: pointA.y + (pointTemp.y - pointA.y)/2);
        pointP = CGPoint(x: pointB.x + (pointTemp2.x - pointB.x)/2, y: pointB.y + (pointTemp2.y - pointB.y)/2);
        
        offset1 = centerDistance/8;
        offset2 = centerDistance/8;
        
        pointAO1 = CGPoint(x: pointA.x + offset1*sinDigree, y: pointA.y + offset1*cosDigree);
        pointAO2 = CGPoint(x: pointO.x - (3*offset2-offset1)*sinDigree, y: pointO.y - (3*offset2-offset1)*cosDigree);
        pointOD1 = CGPoint(x: pointO.x + 2*offset2*sinDigree, y: pointO.y + 2*offset2*cosDigree);
        pointOD2 = CGPoint(x: pointD.x - offset2*sinDigree, y: pointD.y - offset2*cosDigree);
        
        pointCP1 = CGPoint(x: pointC.x - offset2*sinDigree, y: pointC.y - offset2*cosDigree);
        pointCP2 = CGPoint(x: pointP.x + 2*offset2*sinDigree, y: pointP.y + 2*offset2*cosDigree);
        pointPB1 = CGPoint(x: pointP.x - (3*offset2-offset1)*sinDigree, y: pointP.y - (3*offset2-offset1)*cosDigree);
        pointPB2 = CGPoint(x: pointB.x + offset1*sinDigree, y: pointB.y + offset1*cosDigree);
        
        
        cutePath = UIBezierPath()
        
        cutePath.move(to: pointB)
        cutePath.addCurve(to: pointE, controlPoint1: pointBE1, controlPoint2: pointBE2)
        cutePath.addCurve(to: pointA, controlPoint1: pointEA1, controlPoint2: pointEA2)
        cutePath.addCurve(to: pointO, controlPoint1: pointAO1, controlPoint2: pointAO2)
        cutePath.addCurve(to: pointD, controlPoint1: pointOD1, controlPoint2: pointOD2)
        
        cutePath.addCurve(to: pointF, controlPoint1: pointDF1, controlPoint2: pointDF2)
        cutePath.addCurve(to: pointC, controlPoint1: pointFC1, controlPoint2: pointFC2)
        cutePath.addCurve(to: pointP, controlPoint1: pointCP1, controlPoint2: pointCP2)
        cutePath.addCurve(to: pointB, controlPoint1: pointPB1, controlPoint2: pointPB2)
        
        shapeLayer?.path = cutePath.cgPath
        shapeLayer?.fillColor = fillColorForCute?.cgColor
        self.layer.insertSublayer(shapeLayer!, below: prototypeView.layer)
    }
    
    //爆炸效果 💥
    func explosion(centerPint: CGPoint, radius: CGFloat) {
        var imageArr = [UIImage]()
        for i in 1...6 {
            if let image = UIImage(named: "red_dot_image_\(i)") {
                imageArr.append(image)
            }
        }
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        imageView.center = centerPint
        imageView.animationImages = imageArr
        imageView.animationDuration = 0.25
        imageView.animationRepeatCount = 1
        imageView.startAnimating()
        self.addSubview(imageView)
        
        self.perform(#selector(explosionComplete), with: nil, afterDelay: 0.25, inModes: [RunLoopMode.defaultRunLoopMode])
    }
    
    func explosionComplete() {
        touchView?.isHidden = true
        self.removeFromSuperview()
    }
    
    
    // 回弹效果
    func springBack(view: UIView, point: CGPoint) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            view.center = point
        }) { finished in
            if finished {
                self.touchView?.isHidden = false
                self.isUserInteractionEnabled = false
                view.removeFromSuperview()
                self.removeFromSuperview()
            }
        }
    }
    
    func getImageFrom(_ view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    
}
