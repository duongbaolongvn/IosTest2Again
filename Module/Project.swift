//
//  Projects.swift
//  FridayFinish
//
//  Created by Duong Bao Long on 11/17/21.
//

import UIKit
import Alamofire

class Project {
    var id: String
    var name: String
    
    var images: [ImageData] = []
    
    var busy = false
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    func rerange(fromIndex: Int) {
       let removeImage =  images.remove(at: fromIndex)
        images.append(removeImage)
    }
    
    func saveData() {
        var saveObject: [ImageBase?] = []
        
        for im in 0..<images.count {
            let imageId = images[im].imageId
            let imageBase = images[im].imageToObject(imageId)
            saveObject.append(imageBase)
        }
        
        let listImage = ListImage(id: id , name: name, images: saveObject)
        let encoder = JSONEncoder()
        if let dataOutPut = try? encoder.encode(listImage),
           let string = String(data: dataOutPut, encoding: .utf8) {
            UserDefaults.standard.set(string, forKey: "project\(id)")
        }
    }
    func loadData(_ id: String) -> Bool {
        if images.count > 0 {return true}
        guard let stringData = UserDefaults.standard.string(forKey: "project\(id)") else {
            return false
        }
        let decoder = JSONDecoder()
        if let data = stringData.data(using: .utf8),
            let sameListImage = try? decoder.decode(ListImage.self, from: data) {
            images.removeAll()
            for im in 0..<sameListImage.images.count {
                if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                   let imageIdLoad = sameListImage.images[im]?.imageIdData {
                    let fileUrl = url.appendingPathComponent("image\(imageIdLoad).jpg")
                    if let imageFromFile = UIImage(contentsOfFile: fileUrl.path) {
                        let imageData = ImageData(imageData: imageFromFile, opacity: sameListImage.images[im]!.opacity, frame: sameListImage.images[im]!.frame1, imageId: imageIdLoad)
                        imageData.transform = sameListImage.images[im]?.transform ?? .identity
                        self.images.append(imageData)
                    }
                }
            }
        }
           return true
    }
    func getDetail(_ completion: (() -> Void)? = nil,_ id: String) {
        if loadData(id) {
            if let p = completion {
                p()
            }
            return
        }
        AF.request("https://tapuniverse.com/xprojectdetail", method: .post, parameters: ["id": id])
            .validate()
            .responseJSON { response in
                let value = response.value
                if let json = value as? [String: Any],
                   let photo = json["photos"] as? [[String: Any]] {
                    if photo.count == 0 {self.busy = false}
                    self.images.removeAll()
                    for i in 0..<photo.count {
                        if let url = photo[i]["url"] as? String,
                           let frame = photo[i]["frame"] as? [String: Any],
                           let x = frame["x"] as? CGFloat,
                           let y = frame["y"] as? CGFloat,
                           let height = frame["height"] as? CGFloat,
                           let width = frame["width"] as? CGFloat {
                            let frame = CGRect(x: x, y: y, width: width, height: height)
                            AF.request(url)
                                .validate()
                                .responseData { response in
                                   if let data = response.value,
                                      let image1 = UIImage(data: data) {
                                       let imageData = ImageData(imageData: image1, opacity: 1, frame: frame, imageId: UUID().uuidString)
                                       self.images.append(imageData)
                                       if let c = completion {
                                           c()
                                       }
                                   }
                                }
                        }
                           
                    }
                }
            }
    }
}
class ImageData {
    var imageData: UIImage
    var transform = CGAffineTransform.identity
    var opacity: CGFloat
    var frame: CGRect
    var imageId: String
    
    
    init( imageData: UIImage, opacity: CGFloat, frame: CGRect, imageId: String) {
        self.imageData = imageData
        self.opacity = opacity
        self.frame = frame
        self.imageId = imageId
    }
    
    func changeAlpha(_ alpha: CGFloat) {
        self.opacity = alpha
    }
    func imageToObject(_ imageId: String) -> ImageBase? {
        if let data = imageData.jpegData(compressionQuality: 1),
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileUrl = url.appendingPathComponent("image\(imageId).jpg")
            do {
                try data.write(to: fileUrl)
                let object = ImageBase(url: fileUrl.path, frame1: frame, opacity: opacity, imageIdData: imageId, transform: transform)
                return object
            }catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

struct ListImage: Codable {
    var id: String
    var name: String
    var images: [ImageBase?]
}
struct ImageBase: Codable{
    var url: String
    var frame1 =  CGRect.zero
    var opacity: CGFloat
    var imageIdData: String
    var transform: CGAffineTransform = .identity
}
