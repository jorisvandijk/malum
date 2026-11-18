import Foundation
import Synchronization

@testable import MalumCore

/// Makes the same square picture every time, or fails with `failure`, and remembers the crop it
/// was asked for.
final class FakeSquarePictures: SquarePictures {
    /// What every square picture holds.
    static let square = Data("square".utf8)
    /// Why making the picture fails, or nil when it works.
    private let failure: PictureError?
    /// The crop asked for last.
    private let asked = Mutex<PictureCrop?>(nil)

    init(failure: PictureError? = nil) {
        self.failure = failure
    }

    var crop: PictureCrop? { asked.withLock { $0 } }

    func squareJPEG(of path: String, crop: PictureCrop?) throws(PictureError) -> Data {
        asked.withLock { $0 = crop }
        if let failure { throw failure }
        return Self.square
    }
}
