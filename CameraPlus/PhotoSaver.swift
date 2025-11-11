
import UIKit

final class PhotoSaver: NSObject {
    private var onComplete: ((Error?) -> Void)?

    func writeToPhotoAlbum(image: UIImage, completion: @escaping (Error?) -> Void) {
        self.onComplete = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        onComplete?(error)
        onComplete = nil
    }
}

