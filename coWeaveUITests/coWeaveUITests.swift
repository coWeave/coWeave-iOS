/**
 * This file is part of coWeave-iOS.
 *
 * Copyright (c) 2017-2018 Benoît FRISCH
 *
 * coWeave-iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * coWeave-iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with coWeave-iOS If not, see <http://www.gnu.org/licenses/>.
 */

import XCTest

class coWeaveUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
        app.terminate()
    }

    func testOpenView() {
        let open = app.buttons["Open"]
        XCTAssertTrue(open.exists)
        
        open.tap()
        XCTAssertTrue(app.navigationBars["Unassigned documents"].exists)
    }
    
    func testAddCamera() {
        let add = app.buttons["Add"]
        let camera = app.buttons["Camera"]
        let noCamera = app.alerts["Error"].buttons["Close"]
        XCTAssertTrue(add.exists)
        
        add.tap()
        
        XCTAssertTrue(camera.exists)
        camera.tap()
        XCTAssertTrue(noCamera.exists)
        noCamera.tap()
        XCTAssertTrue(camera.exists)
    }
    
    func testAddGallery() {
        let add = app.buttons["Add"]
        let gallery = app.buttons["Gallery"]
        let photos = app.navigationBars["Photos"]
        let closeButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(add.exists)
        
        add.tap()
        
        XCTAssertTrue(gallery.exists)
        gallery.tap()
        waitForElementToAppear(photos)
        XCTAssertTrue(photos.exists)
        XCTAssertTrue(closeButton.exists)
        closeButton.tap()
        XCTAssertTrue(gallery.exists)
    }
    
    func testAddAudio() {
        let add = app.buttons["Add"]
        let micro = app.buttons["Microphone"]
        let remove = app.buttons["Delete"]
        let audio = app.alerts["Playing recorded audio..."].buttons["Save"]
        
        XCTAssertTrue(add.exists)
        
        add.tap()
        
        XCTAssertTrue(micro.exists)
        micro.tap()
        micro.tap()
        XCTAssertTrue(audio.exists)
        audio.tap()
        micro.tap()
        micro.tap()
        XCTAssertFalse(audio.exists)
        XCTAssertTrue(remove.exists)
        remove.tap()
    }
    
    func waitForElementToAppear(_ element: XCUIElement) {
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
