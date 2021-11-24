//
//  GalleryView.swift
//  FridayFinish
//
//  Created by Duong Bao Long on 11/18/21.
//

import UIKit
protocol GalleryViewDelegate: AnyObject {
    func galleryViewSelectImage(_ view: UIImageView)
    func galleryViewChangeImage(_ view: UIImageView)
    func galleryDeselect()
    func changeSliderWidthImage(_ view: UIImageView)
}
class MyImageView: UIImageView {
    var beginTransform = CGAffineTransform.identity
}
class GalleryView: UIView {
    var index = 0
    var project: Project?
    var allImgae: [UIImageView] = []
    var currentScrollView: CGFloat = 1
//    var s: UIScrollView?
    weak var delegate: GalleryViewDelegate?
    
    private var didLoad = false
    
    var viewCheck: UIImageView?
    var beginTransform = CGAffineTransform.identity
    var selectedView: UIImageView?
    let buttonDelete = UIButton()
    let image = UIImage(named: "minus")
    override func draw(_ rect: CGRect) {
        if didLoad {return}
        defer {
            didLoad = true
        }
        buttonDelete.setImage(image, for: .normal)
        buttonDelete.imageView?.contentMode = .scaleAspectFit
        buttonDelete.addTarget(self, action: #selector(deleteImage(_:)), for: .touchUpInside)
        addSubview(buttonDelete)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapView(_:))))
        isUserInteractionEnabled = true
    }
    func reload() {
        guard let pr = project else {return}
        for im in allImgae {
            im.removeFromSuperview()
        }
        allImgae.removeAll()
        for i in 0..<pr.images.count {
            let imageView = UIImageView(image: pr.images[i].imageData)
            
            imageView.frame = pr.images[i].frame
            imageView.transform = pr.images[i].transform
            imageView.alpha = pr.images[i].opacity
            setUpImageView(imageView)
            
        }
    }
    //MARK: BackButton Pressed
    func backButtonPressed() {
        guard let view = selectedView else {return}
        if let pr = project {
            for im in 0..<pr.images.count {
                if pr.images[im].imageData == view.image {
                    pr.images[im].changeAlpha(view.alpha)
                }
            }
        }
    }
    

    //MARK: add or delete image
    @objc func deleteImage(_ b: UIButton) {
        guard let selectedView = selectedView,
        let index = allImgae.firstIndex(of: selectedView),
              let pr = project,
              let d = delegate else {return}
        selectedView.removeFromSuperview()
        allImgae.remove(at: index)
        pr.images.remove(at: index)
        d.galleryDeselect()
        buttonDelete.alpha = 0
    }
    func addImage(_ image: UIImage) {
        let imageView = UIImageView(image: image)
        let insideRect = bounds.insetBy(dx: 50, dy: 50)
        var width: CGFloat = 100
        var height: CGFloat = 100
        if image.size.width > 0, image.size.height > 0 {
            let imageRatio = image.size.width / image.size.height
            let insideRatio = insideRect.size.width / insideRect.size.height
            
            if imageRatio > insideRatio {
                width = insideRect.width
                height = width / imageRatio
            } else {
                height = insideRect.height
                width = height * imageRatio
            }
            imageView.frame = CGRect(x: insideRect.midX, y: insideRect.midY, width: 0, height: 0).insetBy(dx: -width/2, dy: -height/2)
        }
        setUpImageView(imageView)
        
        if let pr = project {
            let newImageId = UUID().uuidString
            let newImageData = ImageData(imageData: image, opacity: 1, frame: imageView.frame, imageId: newImageId)
            pr.images.append(newImageData)
        }
        self.delegate?.galleryViewSelectImage(imageView)
        setUpImageView(imageView)
        showButton(imageView)
    }
    
    
    //MARK: Opacity Changed
    
    func updateOpacity(_ alpha: Double) {
        guard let image = selectedView else {return}
        image.alpha = alpha
    }
    func finishChangeOpacity(_ view: UIImageView) {
        guard let pr = project else {return}
        for im in 0..<pr.images.count {
            if pr.images[im].imageData == view.image {
                pr.images[im].changeAlpha(view.alpha)
            }
        }
    }
    
    //MARK:  Change editView and buttonDelete while scroll
    
    func rebuild() {
        guard let view = selectedView, let d = delegate else {return}
        showButton(view)
        d.galleryViewSelectImage(view)
    }

    //MARK: save gallery to CameraRoll
    
    func drawImage() -> UIImage {
        let format  = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: bounds.width, height: bounds.height)
        let render = UIGraphicsImageRenderer(size: size, format: format)
        
        let image = render.image { context in
            UIColor.systemGray.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
            for im in 0..<allImgae.count {
                let centerImage = allImgae[im].transform.concatenating(CGAffineTransform(translationX: allImgae[im].frame.width, y: allImgae[im].frame.height))
                context.cgContext.concatenate(centerImage)
                let rect = CGRect(x: -allImgae[im].frame.width/2, y: -allImgae[im].frame.height/2, width: allImgae[im].frame.width, height: allImgae[im].frame.height)
                allImgae[im].image?.draw(in: rect, blendMode: .normal, alpha: allImgae[im].alpha)
                context.cgContext.concatenate(centerImage.inverted())
            }
        }
        return image
    }
    //MARK: Function user interaction
    
    func setUpSelectView(_ view: UIImageView) {
        guard let d = delegate else {return}
        self.bringSubviewToFront(view)
        buttonDelete.alpha = 1
        d.changeSliderWidthImage(view)
        selectedView = view
    }
    func popImageToFront() {
        guard let pr = project,
              let view = selectedView else {return}
        for i in 0..<allImgae.count {
            if view == allImgae[i] {
                let indexSelecView = i
                pr.rerange(fromIndex: indexSelecView)
            }
        }
    }
    func setUpImageView(_ view: UIImageView) {
        if view.isUserInteractionEnabled {return}
        
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(tapView(_:))))
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panView(_:))))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchView(_:))))
        view.addGestureRecognizer(UIRotationGestureRecognizer(target: self, action: #selector(rotateView(_:))))
        
        allImgae.append(view)
        addSubview(view)
    }

    func showButton(_ view: UIImageView) {
        let a = view.transform.a
        let c = view.transform.c
        let scale = CGFloat(sqrt(Double(a*a + c*c))*currentScrollView)
        let p = view.convert(CGPoint(x: view.bounds.midX, y: (-15)/scale), to: self)
        let rect = CGRect(origin: p, size: .zero).insetBy(dx: -10, dy: -10)
        buttonDelete.transform = .identity
        buttonDelete.frame = rect
//        buttonDelete.transform = self.transform.inverted()
        buttonDelete.transform = CGAffineTransform(scaleX: 1/currentScrollView, y: 1/currentScrollView)
        bringSubviewToFront(buttonDelete)
    }
    func finishGesture(_ view: UIImageView) {
        guard let pr = project, let i = allImgae.firstIndex(of: view) else {return}
        
        let t = view.transform
        view.transform = .identity
        pr.images[i].frame = view.frame
        pr.images[i].transform = t
        view.transform = t
    }
    @objc func tapView(_ sender: UITapGestureRecognizer) {
        guard let d = delegate else {return}
        if let view = sender.view as? UIImageView {
            switch sender.state {
            case .ended:
                if selectedView != view {
                    d.galleryViewSelectImage(view)
                    if selectedView != nil {
                        finishGesture(selectedView!)
                    }
                    selectedView = view
                    self.setUpSelectView(view)
                    popImageToFront()
                    showButton(view)
                    
                }else {
                    popImageToFront()
                    finishChangeOpacity(selectedView!)
                    d.galleryDeselect()
                    selectedView = nil
                    buttonDelete.alpha = 0
                }
            default:
                 print("end")
            }
        }else {
            guard let select = selectedView else {return}
            d.galleryDeselect()
            buttonDelete.alpha = 0
            finishChangeOpacity(select)
            selectedView = nil
        }
    }
    @objc func panView(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view as? UIImageView else {return}
        self.setUpSelectView(view)
        switch sender.state {
        case .began:
            beginTransform = view.transform
        case .changed:
            let translation = sender.translation(in: view)
            view.transform = beginTransform.translatedBy(x: translation.x, y: translation.y)
            showButton(view)
            guard let d = delegate else {return}
            d.galleryViewSelectImage(view)
        case .ended:
            finishGesture(view)
         print("end")
        default:
            print("ende")
        }
    }
    @objc func pinchView(_ sender: UIPinchGestureRecognizer) {
        guard let view = sender.view as? UIImageView else {return}
        
        self.setUpSelectView(view)
        switch sender.state {
        case .began:
            beginTransform = view.transform
        case .changed:
            view.transform = beginTransform.scaledBy(x: sender.scale, y: sender.scale)
            showButton(view)
            guard let d = delegate else {return}
            d.galleryViewChangeImage(view)
        case .ended:
            finishGesture(view)
            print("ende")
        default:
            print("ende")
        }
    }
    @objc func rotateView(_ sender: UIRotationGestureRecognizer) {
        guard let d = delegate, let view = sender.view as? UIImageView else {return}
        self.setUpSelectView(view)
        switch sender.state {
        case .began:
            beginTransform = view.transform
        case .changed:
            view.transform = beginTransform.rotated(by: sender.rotation)
            showButton(view)
            d.galleryViewSelectImage(view)
        case .ended:
            finishGesture(view)
            print("end")
        default:
            print("end")
        }
    }
    
}
