import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct DsimportTests {
    @Test func photoFileNamesTheUserAndThePicture() {
        #expect(
            Dsimport.photoFile(of: "test", photo: "/tmp/a.jpg") == """
                0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName \
                externalbinary:dsAttrTypeStandard:JPEGPhoto
                test:/tmp/a.jpg

                """)
    }
}
