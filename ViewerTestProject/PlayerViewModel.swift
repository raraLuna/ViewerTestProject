//
//  PlayerViewModel.swift
//  ViewerTestProject
//
//  Created by yumi on 6/11/25.
//

import Foundation
import AVFoundation

class PlayerViewModel: ObservableObject{
    //private let playerService = PlayerService()
    let service: PlayerServiceProtocol
    private(set) var player: AVPlayer?
    var isPlaying = false {
        didSet {
            onPlaybackStateChanged?(isPlaying)
        }
    }
    
    private var timeControlStatusObserver: NSKeyValueObservation?
    var onPlaybackStateChanged: ((Bool) -> Void)?
    
    @Published private(set) var playbackRate: Float = 1.0
    
    init(service: PlayerServiceProtocol = PlayerService()) {
        self.service = service
        self.player = service.player
        
        observePlayback()
    }
    
    func loadVideo(url: URL) {
        service.loadVideo(from: url)
        self.player = service.player
        //self.isPlaying = false
        observePlayback()
    }
    
    func togglePlayPause() {
        if isPlaying {
            service.pause()
            //isPlaying = false
        } else {
            service.play()
            player?.rate = playbackRate
            //isPlaying = true
        }
        // Observer로 감지하여 변경하므로 여기서 변경하지 않음
        // AVPlayer 재생 상태를 옵저버로 확인하여 pauselayView의 hidden 여부 적용하기 위함
        //isPlaying.toggle()
    }
    
    private func observePlayback() {
        timeControlStatusObserver?.invalidate()
        guard let player = player else { return }
        
        // AVPlayer의 timeControlStatus를 감지하여 isPlaying 업데이트하기
        timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, change in
            DispatchQueue.main.async {
                self?.isPlaying = (player.timeControlStatus == .playing)
            }
            
        }
    }
    
    func seekTo(seconds: Double, completion: @escaping (Bool) -> Void) {
        service.seek(to: seconds, completion: completion)
    }
    
    func seekForward10s() {
        //service.seekForward(by: 10)
        guard let currentTime = service.player?.currentTime().seconds else { return }
        seekTo(seconds: currentTime + 10, completion: { _ in })
    }
    
    func seekBackward10s() {
        //service.seekBackward(by: 10)
        guard let currentTime = service.player?.currentTime().seconds else { return }
        seekTo(seconds: currentTime - 10, completion: { _ in })
    }
    
    func setPlaybackRate(_ rate: Float) {
        guard rate >= 0.5 && rate <= 2.0 else { return }
        playbackRate = rate
        player?.rate = rate
        service.setPlaybackRate(rate)
    }
}
