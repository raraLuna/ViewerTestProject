//
//  PlayerService.swift
//  ViewerTestProject
//
//  Created by yumi on 6/11/25.
//

import Foundation
import AVFoundation

protocol PlayerServiceProtocol {
    var player: AVPlayer? { get }
    func loadVideo(from url: URL)
    func play()
    func pause()
    func seek(to seconds: Double, completion: @escaping (Bool) -> Void)
    func seekForward(by seconds: Double)
    func seekBackward(by seconds: Double)
    func setPlaybackRate(_ rate: Float)
}

class PlayerService: PlayerServiceProtocol {
    internal var player: AVPlayer?
    
    // 영상 로드
    func loadVideo(from url: URL) {
        player = AVPlayer(url: url)
    }
    
    // 재생
    func play() {
        player?.play()
    }
    
    // 일시정지
    func pause() {
        player?.pause()
    }
    
    // seconds 위치로 이동
    func seek(to seconds: Double, completion: @escaping (Bool) -> Void) {
        // 음수 및 초과 값에 대한 예외처리 추가 버전
        guard let player = player,
              let currentTime = player.currentItem else {
            completion(false)
            return
        }
        
        let duration = currentTime.duration
        guard duration.isNumeric else {
            completion(false)
            return
        }
        
        let totalSeconds = CMTimeGetSeconds(duration)
        guard seconds >= 0, seconds <= totalSeconds else {
            completion(false)
            return
        }
        
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player.seek(to: time) { finished in
            completion(finished)
        }
    }
    
    // seconds 만큼 앞으로 이동
    func seekForward(by seconds: Double) {
        guard let currentTime = player?.currentTime().seconds,
              let duration = player?.currentItem?.duration.seconds,
              !duration.isNaN else { return }
        
        let newTime = min(currentTime + seconds, duration)
        let cmTime = CMTime(seconds: newTime, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    // seconds 만큼 뒤로 이동
    func seekBackward(by seconds: Double) {
        guard let currentTime = player?.currentTime().seconds else { return }
        
        let newTime = max(currentTime - seconds, 0)
        let cmTime = CMTime(seconds: newTime, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    // 재생 중 여부 확인
    var isPlaying: Bool {
        guard let player = player else { return false }
        return player.rate != 0 // rate가 0이면 재생 중이 아님
    }
    
    // 재생 속도 rate로 조정
    func setPlaybackRate(_ rate: Float) {
        guard let player = player else { return }
        // 재생 중 일때만 속도 조정함 
        if player.timeControlStatus == .playing {
            player.rate = rate
        }
    }
}
