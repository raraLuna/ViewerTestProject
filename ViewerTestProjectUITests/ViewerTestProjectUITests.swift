//
//  ViewerTestProjectUITests.swift
//  ViewerTestProjectUITests
//
//  Created by yumi on 6/11/25.
//

import XCTest

final class ViewerTestProjectUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        
    }

    // Play/Pause 토글 테스트
    func testTogglePlayPause() {
        let playButton = app.buttons["Play/Pause"]
        XCTAssertTrue(playButton.exists)
        
        playButton.tap()
        sleep(1)
        playButton.tap()
    }
    
    // 10초 탐색 버튼 동작 테스트
    func testSeekTo10Seconds() {
        let seekButton = app.buttons["Seek to 10s"]
        XCTAssertTrue(seekButton.exists)
        
        seekButton.tap()
    }
    
    // 앞으로 10초 이동 버튼 동작
    func testSeekForward10Seconds() {
        let seekForwardButton = app.buttons["Forwards 10s"]
        XCTAssertTrue(seekForwardButton.exists)
        
        seekForwardButton.tap()
    }
    
    // 뒤로 10초 이동 버튼 동작
    func testSeekBackward10Seconds() {
        let seekBackwardButton = app.buttons["Backward 10s"]
        XCTAssertTrue(seekBackwardButton.exists)
        
        seekBackwardButton.tap()
    }
    
    // 속도 조절 1.5x 조정 테스트
    func testPlaybackRateChangedTo1_5x() {
        let segmentedControl = app.segmentedControls.element
        XCTAssertTrue(segmentedControl.exists)
        
        segmentedControl.buttons["1.5x"].tap()
    }
    
    // pauseOverlayView의 hidden 상태 확인 테스트
    func testPauseOverlayViewVisibility() {
        let overlay = app.otherElements["pauseOverlayView"]
        let playButton = app.buttons["Play/Pause"]
        
        // 최초상태 : 정지이면 overlay가 show
        print(app.debugDescription)
        XCTAssertTrue(overlay.waitForExistence(timeout: 2))
        XCTAssertTrue(overlay.exists)
        XCTAssertEqual(overlay.value as? String, "visible")
        
        // play버튼 클릭하면 overlay hide
        // MARK: Hide 상태에서는 waitForExistence 불가능, value 확인 불가능 -> isHittable, exists 조합으로 간접확인
        playButton.tap()
        sleep(1)
        print(app.debugDescription) // 현재 접근 가능한 뷰 계층 확인 로그
        
        XCTAssertFalse(overlay.isHittable) // 상호작용 불가능
        XCTAssertFalse(overlay.exists) // 존재하지 않음 (isHidden 상태는 UITest에서 인식되지 않음)
        // XCTAssertEqual(overlay.value as? String, "hidden") -> hide 상태에서는 인식되지 않음
        // isHidden == true 검증은 exists == true + isHittable == false 조합으로 하는 것이 더 현실적이고 안정적
        
        // accessibilityTraits: 해당 요소가 어떻게 인식되어야 하는지를 정의하는 비트값 ex).button : 버튼으로 작동함
        // 이경우에는 기본값인 .none(0)임
        //print("Traits: \(overlay.accessibilityTraits)")
        
        // play버튼 다시 클릭하면 일시정지, overlay show
        playButton.tap()
        sleep(1)
        print(app.debugDescription)
        
        XCTAssertTrue(overlay.waitForExistence(timeout: 2))
        XCTAssertTrue(overlay.exists)
        XCTAssertEqual(overlay.value as? String, "visible")
    }
    
    // 전체 UI 존재 여부 확인 테스트
    func testAllButtonExist() {
        XCTAssertTrue(app.buttons["Play/Pause"].exists)
        XCTAssertTrue(app.buttons["Seek to 10s"].exists)
        XCTAssertTrue(app.buttons["Forwards 10s"].exists)
        XCTAssertTrue(app.buttons["Backward 10s"].exists)
        XCTAssertTrue(app.segmentedControls.element.exists)
    }
}
