//
//  ViewController.swift
//  ViewerTestProject
//
//  Created by yumi on 6/11/25.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    internal let viewModel = PlayerViewModel()
    private var playerLayer: AVPlayerLayer?
    
    private let playButton = UIButton(type: .system)
    private let seekButton = UIButton(type: .system)
    private let seekForward10Button = UIButton(type: .system)
    private let seekBackward10Button = UIButton(type: .system)
    
    internal let pauseOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.accessibilityIdentifier = "pauseOverlayView"
        view.isHidden = true
        
        //let imageView = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        let imageView = UIImageView(image: UIImage(systemName: "pause.circle.fill"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setupViewModel()
        loadSampleVideo()
    }
    
    private func setUI() {
        view.backgroundColor = .white
        
        playButton.setTitle("Play/Pause", for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = .black
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        
        seekButton.setTitle("Seek to 10s", for: .normal)
        seekButton.tintColor = .white
        seekButton.backgroundColor = .black
        seekButton.addTarget(self, action: #selector(seekTo10Seconds), for: .touchUpInside)
        
        seekForward10Button.setTitle("Forwards 10s", for: .normal)
        seekForward10Button.tintColor = .white
        seekForward10Button.backgroundColor = .black
        seekForward10Button.addTarget(self, action: #selector(Forward10Seconds), for: .touchUpInside)
        
        seekBackward10Button.setTitle("Backward 10s", for: .normal)
        seekBackward10Button.tintColor = .white
        seekBackward10Button.backgroundColor = .black
        seekBackward10Button.addTarget(self, action: #selector(Backward10Seconds), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [
            playButton,
            seekButton,
            seekForward10Button,
            seekBackward10Button
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        
        // 속도 조정 segmentedControl 추가
        let speedSegmentedControl = UISegmentedControl(items: ["0.5x", "1.0x", "1.5x", "2.0x"])
        speedSegmentedControl.selectedSegmentIndex = 1 // 기본값 1.0x
        speedSegmentedControl.addTarget(self, action: #selector(playbackPateChanged(_:)), for: .valueChanged)
        speedSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedSegmentedControl)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            speedSegmentedControl.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 24),
            speedSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speedSegmentedControl.widthAnchor.constraint(equalToConstant: 250)
        ])
        
    }
    
    private func setupViewModel() {
        viewModel.onPlaybackStateChanged = { [weak self] isPlaying in
            self?.updateUIForPlaybackState(isPlaying: isPlaying)
        }
    }
    
    private func loadSampleVideo() {
        if let path = Bundle.main.path(forResource: "SampleVideo_1280x720_30mb_h264_AAC", ofType: "mp4") {
            let url = URL(fileURLWithPath: path)
            viewModel.loadVideo(url: url)
            
            if let player = viewModel.player {
                playerLayer = AVPlayerLayer(player: player)
                let playerFrame = CGRect(x: 0, y: 80, width: view.bounds.width, height: 250)
                playerLayer?.frame = playerFrame
                if let playerLayer = playerLayer {
                    view.layer.addSublayer(playerLayer)
                }
                
                pauseOverlayView.frame = playerFrame
                view.addSubview(pauseOverlayView)
            }
        }
    }
    
    @objc private func togglePlay() {
        viewModel.togglePlayPause()
    }
    
    private func updateUIForPlaybackState(isPlaying: Bool) {
        pauseOverlayView.isHidden = isPlaying
        pauseOverlayView.accessibilityValue = isPlaying ? "hidden" : "visible"
        playButton.isEnabled = true
    }

    @objc private func seekTo10Seconds() {
        viewModel.seekTo(seconds: 10.0) { success in
        }
    }
    
    @objc private func Forward10Seconds() {
        viewModel.seekForward10s()
    }
    
    @objc private func Backward10Seconds() {
        viewModel.seekBackward10s()
    }
    
    @objc private func playbackPateChanged(_ sender: UISegmentedControl) {
        let selectedRate: Float
        switch sender.selectedSegmentIndex {
        case 0: selectedRate = 0.5
        case 1: selectedRate = 1.0
        case 2: selectedRate = 1.5
        case 3: selectedRate = 2.0
        default : selectedRate = 1.0
        }
        
        viewModel.setPlaybackRate(selectedRate)
    }

}

