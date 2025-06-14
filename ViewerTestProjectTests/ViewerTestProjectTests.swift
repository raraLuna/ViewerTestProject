//
//  ViewerTestProjectTests.swift
//  ViewerTestProjectTests
//
//  Created by yumi on 6/11/25.
//

import XCTest
@testable import ViewerTestProject
import AVFoundation

final class ViewerTestProjectTests: XCTestCase {
    var viewModel: PlayerViewModel!
    var sampleURL: URL!

    override func setUpWithError() throws {
        // 테스트 코드 호출 전에 호출 됨 init
        viewModel = PlayerViewModel()
        // 앱 내 리소스에서 url 생성
        guard let path = Bundle(for: type(of: self)).path(forResource: "SampleVideo_1280x720_30mb_h264_AAC", ofType: ".mp4") else {
            XCTFail("sample.mp4 파일을 찾을 수 없습니다. Copy Bundle Resource 확인 필요함")
            return
        }
        sampleURL = URL(fileURLWithPath: path)
    }

    override func tearDownWithError() throws {
        // 테스트 코드 호출 후에 호출 deinit
        viewModel = nil
        sampleURL = nil
    }
    
    // MARK: waitUntilPlaying, waitUntilNotPlaying
    // isPlaying이 AVPlayer.timeControlStatus를 KVO로 감지해 비동기적으로 업데이트 하므로 play 및 pause 버튼 클릭 시 상태가 바로 변경되지 않을 수 있음
    func waitUntilPlaying(_ timeout: TimeInterval = 1.0, completion: @escaping () -> Void) {
        let deadline = Date().addingTimeInterval(timeout)
        
        func check() {
            if self.viewModel.isPlaying || Date() > deadline {
                completion()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    check()
                }
            }
        }
        check()
    }
    
    func waitUntilNotPlaying(_ timeout: TimeInterval = 1.0, completion: @escaping () -> Void) {
        let deadline = Date().addingTimeInterval(timeout)
        
        func check() {
            if !self.viewModel.isPlaying || Date() > deadline {
                completion()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    check()
                }
            }
        }
        check()
    }

    // 영상 업로드 후 AVPlayer 인스턴스 실행 확인
    func testLoadVideo_setPlayer() throws {
        viewModel.loadVideo(url: sampleURL)
        XCTAssertNotNil(viewModel.player, "loadVideo 호출 후 player가 nil이면 안 됨.")
    }
    
    // 잘못된 경로 입력 시 player 런타임 오류 재생 실패 확인
    // 잘못된 경로가 들어가도 AVPlayer는 nil을 반환하지 않고 내부적으로 AVPlayerItemFailedToPlayToEndTime 등의 런타임 에러를 낸다
    // 즉, AVPlayerItem의 상태를 관찰해야함
    func testLoadVideo_withInvalidURL_shouldNotSetPlayer() {
        let expectation = XCTestExpectation(description: "Invalid URL should not be playable")
        let invalidURL = URL(fileURLWithPath: "invalid-url")
        
        viewModel.loadVideo(url: invalidURL)
        
        // 1초 이내 AVPlayerItem의 상태를 확인 (실제 실패는 약간 지연됨)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let playerItem = self.viewModel.player?.currentItem else {
                XCTFail("playerItem 설정되지 않음")
                return
            }
            
            switch playerItem.status {
            case .failed:
                expectation.fulfill()
            case .readyToPlay, .unknown:
                XCTFail("잘못된 URL이어도 status 실패하지 않음")
            @unknown default:
            XCTFail("알 수 없는 상태")
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // togglePlayerPause 호출 시 재생 상태가 바뀌는지 확인
    func testTogglePlayPause_switchPlayState() throws {
        // MARK: isPlaying toggle 상태를 observer통해 변경 감지하여 바꾸도록 코드가 수정되었으므로,  togglePlayPause() 함수 안에서 바뀌지 않음
        //       service.play() 또는 service.pause() 호출 후에 isPlaying 값이 바뀌려면, service가 내부 AVPlayer 상태를 관찰하여 업데이트 이벤트를 발생시켜야함
        //       테스트 환경에서는 Observer가 제대로 작동하지 않거나, 비동기적으로 작동하여 테스트 시점에 isPlaying 상태가 바꾸지 않을 수 있음
        //       -> 테스트에서 상태 변경이 비동기적임을 반영하여 XCTestExpectation과 딜레이를 활용해야 함
        
        viewModel.loadVideo(url: sampleURL)
        
        let playExpectation = expectation(description: "Player should start playing")
        viewModel.togglePlayPause()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssert(self.viewModel.isPlaying, "재생 상태여야 합니다.")
            playExpectation.fulfill()
        }
        wait(for: [playExpectation], timeout: 1.0)
        
        let pauseExpectation = expectation(description: "Player should pause")
        viewModel.togglePlayPause()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.viewModel.isPlaying, "일시 정지 상태여야 함")
            pauseExpectation.fulfill()
        }
        wait(for: [pauseExpectation], timeout: 1.0)
        
    }
    
    // 지정된 시간으로 정상적으로 seek 되는지 확인
    func testSeekTo_vaildSeekTime_callsCompletion() throws {
        // expectation: 비동기 작업을 위한 테스트 코드
        let expectation = self.expectation(description: "seekTo completion")
        viewModel.loadVideo(url: sampleURL)
        
        // AVPlayerItem 준비된 이후에 seekTo 호출하도록 지연
        // : 영상 로드 직후에는 currentTime.duration이 .invalid / .indefinte일 수 있음
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.viewModel.seekTo(seconds: 5.0) { success in
                XCTAssertTrue(success, "seek 성공 여부 확인")
                expectation.fulfill() // 비동기 작업이 끝나는 시점 fulfill() 호출
            }
        }

        // 3초 대기 후 넘어감
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    // 재생 상태에 따라 pauseOverlayView isHidden 상태 확인
    func testPauseOverlayView_ShowAndHideBasedOnPlaybackState() throws {
        let vc = ViewController()
        _ = vc.view // pauseOverlayView가 viewDidLoad 내부에서 초기화되므로 여기서 강제 로드해야함
        
        // 1. 재생 중일 때: pauseOverlayView 숨겨짐
        vc.viewModel.onPlaybackStateChanged?(true)
        XCTAssertTrue(vc.pauseOverlayView.isHidden, "재생 중에는 pauseOverlayView Hide")
        
        // 2. 일시정지 중일 때: pauseOverlayview 보임
        vc.viewModel.onPlaybackStateChanged?(false)
        XCTAssertFalse(vc.pauseOverlayView.isHidden, "일시정지 중에는 pauseOverlayView Show")
    }
    
    // Forwards 10s Button 클릭 시 10초 이후 시간으로 이동하는지 확인
    func testSeekForward10s_increaseCurrentTimeBy10Seconds() throws {
        let expectation = self.expectation(description: "Seek forward completion")
        
        viewModel.loadVideo(url: sampleURL)
        
        // 0.5초 후 seek 시작함 (AVPlayer가 준비되는 시간 고려)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.seekTo(seconds: 5.0) { _ in
                self.viewModel.seekForward10s()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let newTime = self.viewModel.service.player?.currentTime().seconds ?? 0
                    XCTAssertGreaterThan(newTime, 14.9, "10초 이후 시간으로 이동")
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    // Backwards 10s Button 클릭 시 10초 이전 시간으로 이동하는지 확인
    func testSeekBackward10s_decreaseCurrentTimeBy10Seconds() throws {
        let expectation = self.expectation(description: "Seek backward completion")
        
        viewModel.loadVideo(url: sampleURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.seekTo(seconds: 15.0) { _ in
                self.viewModel.seekBackward10s()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let newTime = self.viewModel.service.player?.currentTime().seconds ?? 0
                    XCTAssertLessThan(newTime, 5.5, "10초 이전 시간으로 이동")
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    // 음수 값으로 seekTo 시도 시 실패 확인
    func testSeekTo_negativeTime_callsCompletionWithFalse() {
        viewModel.loadVideo(url: sampleURL)
        
        let expectation = self.expectation(description: "Seek completion for negative time")
        viewModel.seekTo(seconds: -5.0) { success in
            XCTAssertFalse(success, "음수 시간은 실패 처리되어야 함")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // 초과 값으로 seekTo 시도 시 실패 확인
    func testSeekTo_exceedDuration_callsCompletionWithFalse() {
        viewModel.loadVideo(url: sampleURL)
        
        let expectation = self.expectation(description: "Seek completion for exceed duration")
        viewModel.seekTo(seconds: 100.0) { success in
            XCTAssertFalse(success, "초과하는 시간에는 실패 처리되어야 함")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // 유효한 값으로 재생 속도 조정 시 성공 확인
    func testSetPlaybackRate_validValue_setPlaybackRate() throws {
        viewModel.loadVideo(url: sampleURL)
        
        // 유효한 값을 적용하는 경우 AVPlayer.rate는 일시정지 중에서도 임의 설정이 가능하고 내부적으로 값을 유지할 수 있다
        // 그러므로 테스트 중에 재생 상태가 아니어도 테스트를 성공 시킬 수 있음
        viewModel.setPlaybackRate(1.5)
        
        XCTAssertEqual(viewModel.playbackRate, 1.5, "유효한 값이 정상적으로 적용되어야 함")
        XCTAssertEqual(viewModel.service.player?.rate, 1.5, "AVPlayer의 rate도 동일하게 설정되어야 함")
    }
    
    // 무효한 값으로 재생 속도 조정 시 성공 확인
    func testSetPlaybackRate_invalidValue_setPlaybackRate() throws {
        viewModel.loadVideo(url: sampleURL)
        
        // 재생 시작하여 rate가 적용되는 상태로 만들기 (일시정지 상태인 경우는 항상 0.0)
        // MARK: 유효한 값과 달리 무효한 값을 테스트할때는 재생 상태로 만들어야 하는 이유가 무엇인가?
        // AVPlayer.rate는 일지정지 일때에도 상태을 설정할 수 있으나,
        // 비정상적인 값을 설정할 때에는 재생상태가 아니면 이를 무시할 가능성이 있고, 그러면 실제 무효한 값이 적용이 되었다고 보장하기 어려움
        // 즉, 실제로 무효한 값이 적용되려 할때의 테스트를 위해서는 재생 상태로 만들어야 함
        viewModel.togglePlayPause()
        
        let expectation = expectation(description: "재생 후 속도 설정 확인")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.setPlaybackRate(3.0)
            
            XCTAssertEqual(self.viewModel.playbackRate, 1.0, "잘못된 값 입력 시 기본 값 유지")
            XCTAssertEqual(self.viewModel.service.player?.rate ?? 1.0, 1.0, "AVPlayer의 rate 값 변경하지 않음")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // 음수 값으로 재생 속도 조정 시 실패 확인
    func testSetPlaybackRate_negativeValue_doesNotChangeRate() throws {
        viewModel.loadVideo(url: sampleURL)
        
        viewModel.togglePlayPause()
        
        let expectation = expectation(description: "재생 후 속도 설정 확인")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.setPlaybackRate(-1.0)
            
            XCTAssertEqual(self.viewModel.playbackRate, 1.0, "음수 값이 입력되면 무시되어야 함")
            XCTAssertEqual(self.viewModel.service.player?.rate, 1.0, "AVPlayer rate 변경 없어야 함")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // 0 값으로 재생 속도 조정 시 실패 확인
    func testSetPlaybackRate_zeroValue_doesNotChangeRate() throws {
        viewModel.loadVideo(url: sampleURL)
        
        viewModel.togglePlayPause()
        
        let expectation = expectation(description: "재생 후 속도 설정 확인")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.setPlaybackRate(0.0)
            
            XCTAssertEqual(self.viewModel.playbackRate, 1.0, "0 값이 입력되면 무시되어야 함")
            XCTAssertEqual(self.viewModel.service.player?.rate, 1.0, "AVPlayer rate 변경 없어야 함")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

    }
    
    // load -> play -> seek -> pause -> playbackRate 변경 시나리오 테스트
    func testPlaybackScenario_no1() throws {
        let scenarioExpetation = expectation(description: "Playback scenario_no1 complete")
        
        // load
        viewModel.loadVideo(url: sampleURL)
        XCTAssertNotNil(viewModel.player, "loadVideo 호출 후 player가 not nil.")
        
        // play
        self.viewModel.togglePlayPause()
        self.waitUntilPlaying {
            XCTAssertTrue(self.viewModel.isPlaying, "Play 버튼 클릭 시 isPlaying == true")
        }

        
        // seek to 10s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.seekTo(seconds: 10.0) { sucess in
                XCTAssertTrue(sucess, "Seek to 10secondes 성공")
            }
        }
        
        // pause
            self.viewModel.togglePlayPause()
            self.waitUntilNotPlaying {
                XCTAssertFalse(self.viewModel.isPlaying, "Pause 버튼 클릭 시 isPlaying == false")
            }

        
        // playback rate to 1.5x
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.setPlaybackRate(1.5)
            XCTAssertEqual(self.viewModel.playbackRate, 1.5, "속도 변경 후 playbackRate == 1.5")
            XCTAssertEqual(self.viewModel.service.player?.rate, 1.5, "AVPlayer.rate == 1.5")
            scenarioExpetation.fulfill()
        }
        wait(for: [scenarioExpetation], timeout: 3.0)
    }
    
    // 사용자가 영상 재생 중 영상을 일시 정지 할 경우, 다시 돌아와을때 재생 위치와 속도 상태 확인
    func testPlaybackScenario_no2_shouldRetainPlaybackTimeAndRate() throws {
        let scenarioExpetation = expectation(description: "Playback scenario_no2 complete")
        
        viewModel.loadVideo(url: sampleURL)
        
        // 5초 지점으로 이동 후 1.5배 속도 조정
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.seekTo(seconds: 5.0) { _ in
                self.viewModel.setPlaybackRate(1.5)
                self.viewModel.togglePlayPause() // 재생 시작함
                
                // 0.5초 후 일시정지
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.viewModel.togglePlayPause() // 일시 정지
                    
                    let pausedTime = self.viewModel.service.player?.currentTime().seconds ?? -1
                    //let pausedRate = self.viewModel.service.player?.rate ?? -1
                    
                    self.waitUntilNotPlaying { // 재생 상태 바뀌기를 잠시 기다림
                        XCTAssertFalse(self.viewModel.isPlaying)
                        XCTAssertEqual(self.viewModel.playbackRate, 1.5)
                        
                        self.viewModel.togglePlayPause() // 다시 재생 시작
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let resumedTime = self.viewModel.service.player?.currentTime().seconds ?? -1
                            let resumedRate = self.viewModel.service.player?.rate ?? -1
                            
                            XCTAssertTrue(self.viewModel.isPlaying, "다시 재생 중이어야 함")
                            XCTAssertEqual(self.viewModel.playbackRate, 1.5, accuracy: 0.01)
                            XCTAssertGreaterThan(resumedTime, pausedTime, "재생 시점이 일시정지 시점보다 커야 함")
                            XCTAssertEqual(resumedRate, 1.5, accuracy: 0.01)
                            
                            scenarioExpetation.fulfill()
                        }
                    }

                }
            }
        }
        wait(for: [scenarioExpetation], timeout: 3.0)
    }
    
    // 연속적으로 재생 속도가 변경되는 경우의 비정상 상태 유무 확인
    func testPlaybackScenario_no3_shouldNotCrashAndRetainFinalSpeedRateState() {
        let scenarioExpetation = expectation(description: "Playback scenario_no3 complete")
        
        viewModel.loadVideo(url: sampleURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.togglePlayPause() // 재색 시작
            
            // 속도 변경
            self.viewModel.setPlaybackRate(0.5)
            self.viewModel.setPlaybackRate(2.0)
            self.viewModel.setPlaybackRate(1.0)
            
            // Seek 조정 발생
            self.viewModel.seekTo(seconds: 10.0) { success in
                XCTAssertTrue(success, "seek 성공 해야 함")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let currentTime = self.viewModel.service.player?.currentTime().seconds ?? 0
                    let currentRate = self.viewModel.service.player?.rate ?? 0
                    
                    XCTAssertGreaterThan(currentTime, 10.0, "seek 이후 정상 재생 중이어야 함")
                    XCTAssertEqual(currentRate, 1.0, accuracy: 1.0, "최종 재생 속도가 유지되고 있어야 함")
                    
                    scenarioExpetation.fulfill()
                }
            }
        }
        wait(for: [scenarioExpetation], timeout: 3.0)
    }
}
