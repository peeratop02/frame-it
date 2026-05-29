import XCTest

/// Drives the critical flow end-to-end: grant photo access, open a photo, and
/// land in the editor. Holds at the end so a screenshot can be captured.
final class EditorFlowUITests: XCTestCase {

    func testOpenEditorFromLibrary() {
        let app = XCUIApplication()
        app.launch()

        // Grant photo access if the contextual prompt is showing.
        let allowButton = app.buttons["Allow Access"]
        if allowButton.waitForExistence(timeout: 5) {
            allowButton.tap()

            // Handle the system photo-permission alert.
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let allowFull = springboard.buttons["Allow Full Access"]
            if allowFull.waitForExistence(timeout: 5) {
                allowFull.tap()
            }
        }

        // Tap the first photo cell to open the editor.
        let cell = app.buttons["Photo"].firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 10), "Photo grid did not appear")
        cell.tap()

        // Confirm the editor opened (its Save action exists), then hold for capture.
        let saveButton = app.buttons["Save to Photos"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 10), "Editor did not open")

        // Keep the editor on screen so an external screenshot can be taken.
        sleep(30)
    }
}
