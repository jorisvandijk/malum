import Foundation

/// Makes square pictures, such as the user's picture, from pictures of any shape.
public protocol SquarePictures: Sendable {
    /// The middle square of the picture at `path`, as a JPEG. Throws when it can't be read.
    func squareJPEG(of path: String) throws(PictureError) -> Data
}
