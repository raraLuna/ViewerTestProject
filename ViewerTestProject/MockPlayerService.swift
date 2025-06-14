//
//  MockPlayerService.swift
//  ViewerTestProject
//
//  Created by yumi on 6/11/25.
//

import Foundation
import AVFoundation

// 테스트용 playerService (mockup)
final class MockPlayerService: PlayerServiceProtocol {
    var player: AVPlayer? {
        return mockPlayer
    }
    
    var mockPlayer = MockPlayer()
    
    var lastSeekTime: Double?
    var isSeekCalled = false
    
    private(set) var isPlayCalled = false
    private(set) var isPauseCalled = false
    private(set) var isLoadVideoCalled = false
    private(set) var seekTime: Double?
    
    // MockPlayerService에서 play(), pause()가 호출 될 때 viewModel에 알려주는 콜백
    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    
    private(set) var isSeekForwardCalled = false
    private(set) var isSeekBackwardCalled = false
    private(set) var seekForwardSeconds: Double?
    private(set) var seekBackwardSeconds: Double?

    var lastSetRate: Float?
    	
    func setPlayer(_ player: AVPlayer) {}
    
    func loadVideo(from url: URL) {
        isLoadVideoCalled = true
    }
    
    func play() {
        isPlayCalled = true
        onPlay?()
    }
    
    func pause() {
        isPauseCalled = true
        onPause?()
    }
    
    func seek(to seconds: Double, completion: @escaping (Bool) -> Void) {
        seekTime = seconds
        isSeekCalled = true
        lastSeekTime = seconds
        completion(true)
    }
    
    func seekForward(by seconds: Double) {
        isSeekForwardCalled = true
        seekForwardSeconds = seconds
    }
    
    func seekBackward(by seconds: Double) {
        isSeekBackwardCalled = true
        seekBackwardSeconds = seconds
    }
    
    func setPlaybackRate(_ rate: Float) {
        lastSetRate = rate
    }
}

// mockup 용 가짜 currentTime 값을 반환하는 AVPlayer
class MockPlayer: AVPlayer {
    var mockCurrentTime: CMTime = CMTime(seconds: 0, preferredTimescale: 600)
    override func currentTime() -> CMTime {
        return mockCurrentTime
    }
}
