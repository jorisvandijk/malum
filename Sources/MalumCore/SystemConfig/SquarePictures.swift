import Foundation

/// Makes square pictures, such as the user's picture, from pictures of any shape.
public protocol SquarePictures: Sendable {
    /// The part `crop` of the picture at `path`, or its middle square when there's no crop, as a
    /// square JPEG. Throws when it can't be read.
    func squareJPEG(of path: String, crop: PictureCrop?) throws(PictureError) -> Data
}
