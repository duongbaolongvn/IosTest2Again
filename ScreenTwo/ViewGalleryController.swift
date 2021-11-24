//
//  ViewGalleryController.swift
//  FridayFinish
//
//  Created by Duong Bao Long on 11/18/21.
//
import UIKit
import Photos
class ViewGalleryController: ViewOneController, UINavigationControllerDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var editView: EditView!
    @IBOutlet weak var sliderView: SliderView!
    @IBOutlet weak var galleryView: GalleryView!
    var project: Project?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        galleryView.project = project
        sliderView.delegate = self
        sliderView.isHidden = true
        galleryView.delegate = self
        scrollView.delegate = self

        guard let pr = project else {return}
        pr.getDetail({
            self.galleryView.reload()
            self.editView.hide()
        }, pr.id)
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        guard let pr = project else {return}
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Save Project", message: "Save Changed Project?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Don't save", style: .cancel) { _ in
                self.navigationController?.popViewController(animated: true)
            }
            let saveAction = UIAlertAction(title: "Save project", style: .default) { _ in
                self.galleryView.backButtonPressed()
                pr.saveData()
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(cancelAction)
            alert.addAction(saveAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func tapToCameraRoll(_ sender: UIButton) {
        guard let screen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CollectionView") as? ScreenThreeViewController else {return}
        screen.delegate = self
        present(screen, animated: true, completion: nil)
    }
    
    @IBAction func exportButton(_ sender: UIButton) {
        DispatchQueue.main.async {
            let galleryImage = self.galleryView.drawImage()
            let alert = UIAlertController(title: "Export", message: "Export or Share", preferredStyle: .alert)
            let exportGallery = UIAlertAction(title: "Export", style: .default) { _ in
                UIImageWriteToSavedPhotosAlbum(galleryImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
            let shareGallery = UIAlertAction(title: "Share", style: .default) { _ in
                let activityViewController = UIActivityViewController(activityItems: [galleryImage], applicationActivities: nil)
                self.present(activityViewController, animated: true, completion: nil)
            }
            alert.addAction(shareGallery)
            alert.addAction(exportGallery)
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
}
extension ViewGalleryController: GalleryViewDelegate {
    func changeSliderWidthImage(_ view: UIImageView) {
        sliderView.changeSliderWithImage(view)
    }
    
    func galleryViewSelectImage(_ view: UIImageView) {
        sliderView.isHidden = false
        editView.show(view)
    }
    func galleryDeselect() {
        editView.hide()
        sliderView.isHidden = true
    }
    func galleryViewChangeImage(_ view: UIImageView) {
        editView.show(view)
        sliderView.isHidden = false
    }
}

extension ViewGalleryController: SliderViewDelegate {
    func alphaChanged(_ alpha: Double) {
        galleryView.updateOpacity(alpha)
    }
}

extension ViewGalleryController: CustomPhotoPickerDelegate {
    func imageDidSelected(_ image: UIImage) {
        galleryView.addImage(image)
    }
}

extension ViewGalleryController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return galleryView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        reloadView(scrollView)
        
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        reloadView(scrollView)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        reloadView(scrollView)
    }
    func reloadView(_ scrollView: UIScrollView) {
        galleryView.currentScrollView = scrollView.zoomScale
        galleryView.rebuild()
        
    }
}
