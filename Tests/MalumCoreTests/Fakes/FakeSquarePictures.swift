import Foundation

@testable import MalumCore

/// Makes the same square picture every time, or fails with `failure`.
struct FakeSquarePictures: SquarePictures {
    /// What every square picture holds.
    static let square = Data("square".utf8)
    /// Why making the picture fails, or nil when it works.
    var failure: PictureError?

    func squareJPEG(of path: String) throws(PictureError) -> Data {
        if let failure { throw failure }
        return Self.square
    }
}
