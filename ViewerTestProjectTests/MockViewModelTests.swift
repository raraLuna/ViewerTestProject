//
//  MockViewModelTests.swift
//  ViewerTestProjectTests
//
//  Created by yumi on 6/11/25.
//

import XCTest
@testable import ViewerTestProject
import AVFoundation

final class MockViewModelTests: XCTestCase {
    var viewModel: PlayerViewModel!
    var mockService: MockPlayerService!

    override func setUpWithError() throws {
        mockService = MockPlayerService()
        viewModel = PlayerViewModel(service: mockService)
    }

    override func tearDownWithError() throws {
        mockService = nil
        viewModel = nil
    }

    // dummy url로 mockService 호출 성공 확인
    func testLoadVideo_callsServiceLoad() {
        let dummyUrl = URL(string: "dummy")!
        viewModel.loadVideo(url: dummyUrl)
        XCTAssertTrue(mockService.isLoadVideoCalled, "loadVideo는 내부적으로 service.loadVideo를 호출")
    }

    // Play/Pause 버튼 토글 기능 확인
    func testTogglePlayPause_callsPlayAndPause() {
        // MARK: isPlaying 상태가 즉시 업데이트 되지 않고 외부 옵저버에 의해 변경되고 있음
        //       MockPlayerService에서 play(), pause()가 호출 될 때 viewModel 알려주는 콜백 추가함
        
        // play() 호출되면 isPlaying true로 세팅됨
        mockService.onPlay = { [weak viewModel] in
            viewModel?.isPlaying = true
        }
        
        // pause() 호출되면 isPlaying flase로 세팅됨
        mockService.onPause = { [weak viewModel] in
            viewModel?.isPlaying = false
        }
        
        viewModel.togglePlayPause()
        XCTAssertTrue(mockService.isPlayCalled)
        XCTAssertTrue(viewModel.isPlaying)
        
        viewModel.togglePlayPause()
        XCTAssertTrue(mockService.isPauseCalled)
        XCTAssertFalse(viewModel.isPlaying)
        
    }
    
    // 원하는 시간으로 SeekTo 기능 작동 확인
    func testSeek_callsSeekWithCorrectTime() {
        let expectation = self.expectation(description: "Seek Completion")
        viewModel.seekTo(seconds: 12.0) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertEqual(mockService.seekTime!, 12.0, accuracy: 0.001, "seek 호출 시 전달된 시간값이 정확해야 함")
    }
    
    // 앞선 시간으로 SeekTo 기능 작동 확인
    func testSeekForward_callsSeekForwardWithCorrectTime() {
        // Mockup Player로부터 currentTime을 가져와서 비교 (현재 20초라고 가정)
        mockService.mockPlayer.mockCurrentTime = CMTime(seconds: 20.0, preferredTimescale: 600)
        viewModel.seekForward10s()
        
        XCTAssertTrue(mockService.isSeekCalled, "seek 호출되어야 함")
        XCTAssertEqual(mockService.lastSeekTime!, 30.0, accuracy: 0.001, "30초(20 + 10)로 이동해야 함")
    }
    
    // 지나간 시간으로 SeekTo 기능 작동 확인
    func testSeekBackward_callsSeekBackwardWithCorrectTime() {        
        // Mockup Player로부터 currentTime을 가져와서 비교 (현재 15초라고 가정)
        mockService.mockPlayer.mockCurrentTime = CMTime(seconds: 15.0, preferredTimescale: 600)
        viewModel.seekBackward10s()
        
        XCTAssertTrue(mockService.isSeekCalled, "seek 호출되어야 함")
        XCTAssertEqual(mockService.lastSeekTime!, 5.0, accuracy: 0.001, "5초(15 - 10)로 이동해야 함")
    }
    
    // 재생 속도 조정 확인
    func testSetPlaybackRate_updatesServiceAndPublishesValue() {
        viewModel.setPlaybackRate(1.5)
        
        XCTAssertEqual(mockService.lastSetRate!, 1.5, accuracy: 0.001, "서비스에 1.5로 설정되어야 함")
        XCTAssertEqual(viewModel.playbackRate, 1.5, accuracy: 0.001, "뷰모델에 1.5로 설정되어야 함")
    }
    
    // 재생 속도로 유효하지 않은 값은 무시하는지 테스트
    func testSetPlaybackRate_invalidValue_doesNotSet() {
        viewModel.setPlaybackRate(3.0)
        
        XCTAssertNil(mockService.lastSetRate)
        XCTAssertEqual(viewModel.playbackRate, 1.0) // 초기값 유지하기
    }
}
