ViewerTestProject

프로젝트 목적: 간단한 영상 재생 프로그램을 제작 후 XCTest Code를 작성하여 프로젝트 코드의 테스트 자동화를 가능하도록 한다.

[PlayerService]
 - AVPlayer 클래스를 이용하여 영상의 동작을 실제로 처리한다. 
 - 구현 동작 : 
	(1) loadVideo() : 프로젝트 내부 resource의 영상을 load 한다.
	(2) play(): 영상을 재생한다.
	(3) pause(): 영상을 일시정지한다.
	(4) seek(): 파라미터로 전달받은 seconds 위치로 영상 재생위치를 조정한다.
	(5) seekFoarward(): 파라미터로 전달받은 seconds 만큼 재생위치를 앞으로 이동 조정한다.
	(6) seekBackward(): 파라미터로 전달받은 seconds 만큼 재생위치를 뒤로 이동 조정한다.
	(7) setPlaybackRate(): 파마리터로 전달받은 rate로 재생 속도를 조정한다.

[PlayerViewModel]
 - ViewController와 PlayverService 사이에서 명령을 전달함과 동시에 명령의 내용을 구체회 시킨다.
 - 처리 동작 : 
	(1) laodVideo(): 전달받은 url의 영상 로드 명령을 service에 전달하고 Playback 상태를 관찰할 observePlayback 함수를 호출한다
	(2) togglePlayPause(): ViewController에서 Play/Pause 버튼이 클릭되면 service의 play() 또는 pause() 함수로 명령을 전달한다.
	(3) observePlayback(): player의 time 상태를 확인하여 재생 중인지 확인한다. 
	(4) seekTo(): 재생 위치 조정 명령을 service로 전달한다.
	(5) seekForward10s(): 재생 위치를 앞으로 10초 앞당기도록 service에 명령을 전달한다.
	(6) seekBackward10s(): 재생 위치를 뒤로 10초 되돌리도록 service에 명령을 전달한다.
	(7) setPlaybakcRate(): ViewController로부터 전달된 수치로 재생 속도를 조정하도록 service에 명령을 전달한다. 

[ViewController]
 - 영상 재생 화면의 UI를 세팅하고 각 버튼에 관한 기능 수행 명령을 PlayverViewModel에 전달한다. 
 - 처리 동작 : 
	(1) UI 구성: 
		a. playverLayer: 영상을 띄울 layer 생성
		b. playButton: 영상을 재생 시키거나 일시중지 시키는 버튼
		c. seekButton: 영상의 재생 위치를 10초 부분으로 이동 시키는 버튼
		d. seekForward10Button: 영상의 재생 위치를 현재로부터 10초 앞으로 이동 시키는 버튼
		e. seekBackward10Button: 영상의 재생 위치를 현재로부터 10초 뒤로 이동 시키는 버튼 
		f. pauseOverlayView: 영상이 일시중지 중일때 화면에 씌울 일시정지 표시 layer.
	(2) setUI(): 각 버튼의 설정과 배치를 처리한다. 영상 재생 속도 선택 컨트롤러를 생성하고 세팅한다. 
	(3) setupViewModel(): 영상 재생창의 상태가 변하면 viewModel에 재생 중 상태를 전달한다. 
	(4) loadSampleVideo(): load할 영상의 url을 viewModel에 전달하고  playerLayer의 상태를 세팅한다. 
	(5) togglePlay(): "Play/Pause" 버튼이 클릭되면 viewModel에 명령을 전달한다. 
	(6) updateUIForPlaybackState(): Player의 재생 상태에 따라서 pauseOverlayView의 표시 여부를 결정한다. 
	(7) seekTo10Seconds(): "Seek to 10s" 버튼이 클릭되면 viewModel에 명령을 전달한다. 
	(8) forward10Seconds(): "Forwards 10s" 버튼이 클릭되면 viewModel에 명령을 전달한다.
	(9) bakcward10Seconds(): "Backward 10s” 버튼이 클릭되면 viewModel에 명령을 전달한다.
	(10) playbackRateChanged(): 재생 속도 segmentControl를 통해 재생 속도가 변하는 경우 viewModel에 명령을 전달한다. 

[ViewerTestProjectTests]
 - PlayerViewModel의 각 함수들을 Text하는 코드를 작성하여 각 기능들의 XCTestCase를 동작시킨다. 
 - Test Cases: 
	(1) testLoadVideo_setPlayer(): 영상 업로드 후 AVPlayer 인스턴스 생성 여부 확인한다
	(2) testLoadVideo_withInvalidURL_shouldNotSetPlayer() : 유효하지 않은 영상 url 전달 시 AVPlayer 상태를 확인한다.
	(3) testTogglePlayPause_switchPlayState(): viewModel.togglePlayPause()가 동작할 때 영상의 재생 상태(isPlaying)의 변화를 확인한다.
	(4) testSeekTo_vaildSeekTime_callsCompletion(): viewModel.seekTo()가 전달되는 seconds로 영상 재생 위치를 변경 시키는지 확인한다.
	(5) testPauseOverlayView_ShowAndHideBasedOnPlaybackState(): 재생 상태에 따라 pauselayView가 표시되는지 확인한다. 
	(6) testSeekForward10s_increaseCurrentTimeBy10Seconds(): 재생 위치가 10초 이후 시간으로 변경되는지 확인한다.
	(7) testSeekBackward10s_decreaseCurrentTimeBy10Seconds(): 재생 위치가 10초 이전 시간으로 변경되는지 확인한다. 
	(8) testSeekTo_negativeTime_callsCompletionWithFalse(): 음수 값이 전달 될 경우 재생 위치가 변경되는지 확인한다. 
	(9) testSeekTo_exceedDuration_callsCompletionWithFalse(): 총 재생시간보다 초과된 시간 값이 전달 된 경우 재생 위치가 변경되는지 확인한다. 
	(10) testSetPlaybackRate_validValue_setPlaybackRate() : 유효한 값으로 재생 속도가 전달된 경우 재생 속도가 변경되는지 확인한다. 
	(11) testSetPlaybackRate_invalidValue_setPlaybackRate() : 무효한 값으로 재생 속도가 전달된 경우 재생 속도가 변경되는지 확인한다. 
	(12) testSetPlaybackRate_negativeValue_doesNotChangeRate(): 음수 값으로 재생 속도가 전달된 경우 재생 속도가 변경되는지 확인한다. 
	(13) testSetPlaybackRate_zeroValue_doesNotChangeRate(): 0 값으로 재생 속도가 전달된 경우 재생 속도가 변경되는지 확인한다. 
	(14) testPlaybackScenario_no1(): load -> play -> seek -> pause -> playbackRate 변경이 발생할 경우 순서대로 동작이 성공하는지 확인한다. 
	(15) testPlaybackScenario_no2_shouldRetainPlaybackTimeAndRate(): 영상이 일시정지 했다가 다시 재생될 경우 재생 위치와 속도가 설정대로 유지되는지 확인한다. 
	(16) testPlaybackScenario_no3_shouldNotCrashAndRetainFinalSpeedRateState(): 연속적으로 재생 속도가 변경될 때 마지막으로 선택된 재생 속도로 영상이 재생하는지 확인한다. 
	
[MockPlyaerService] 
 - 실제 PlayerService 코드에 영향을 주지 않고 mockup 버전의 PlayerService를 만들어서 실제 재생 없이 TestCase를 동작할 수 있도록 한다. 
 - PlayerService와 MockPlayerService는 PlayerServiceProtocol를 통해 동일한 함수들을 보유함을 보장한다. 
 - 콜백 및 Bool 타입의 변수로 각 동작 함수 결과의 상태를 확인한다. 

[MockPlayer] 
 - MockPlayerService 에서 사용할 가상의 AVPlayer를 생성하고 재생 시간을 확인하는 함수를 가진다. 

[MockViewModelTests]
 - MockPlayerService로 명령을 전달하여 각 기능의 수행을 확인한다. 
 - Test Cases: 
	(1) testLoadVideo_callsServiceLoad(): dummy 영상 url를 이용하여 영상 load 기능을 확인한다. 
	(2) testTogglePlayPause_callsPlayAndPause(): Play / Pause	 버튼 toggle 기능 함수의 동작을 확인힌다. 
	(3) testSeek_callsSeekWithCorrectTime(): 원하는 재생 위치로 player의 상태가 변경되는지 확인한다. 
	(4) testSeekForward_callsSeekForwardWithCorrectTime(): 재생 위치가 앞으로 변경되는지 확인한다. 
	(5) testSeekBackward_callsSeekBackwardWithCorrectTime(): 재생 위치가 뒤로 변경되는지 확인한다. 
	(6) testSetPlaybackRate_updatesServiceAndPublishesValue(): 재생 속도가 변경되는지 확인한다. 
	(7) testSetPlaybackRate_invalidValue_doesNotSet(): 재생 속도로 무효한 값이 들어오는 경우의 결과를 확인한다. 

[ViewerTestProjectUITests]
 - ViewController에서 구성된 각 UI가 정상적으로 동작하는지 확인한다. 
 - Test Cases: 
	(1) testTogglePlayPause(): "Play/Pause" 버튼의 동작을 확인한다.
	(2) testSeekTo10Seconds(): "Seek to 10s" 버튼의 동작을 확인한다. 
	(3) testSeekForward10Seconds(): "Forwards 10s" 버튼의 동작을 확인한다. 
	(4) testSeekBackward10Seconds(): "Backward 10s" 버튼의 동작을 확인한다. 
	(5) testPlaybackRateChangedTo1_5x(): 재생속도 segment의 동작을 확인한다. 
	(6) testPauseOverlayViewVisibility(): pauseOverlayview()의 상태 변화를 확인한다. 
	(7) testAllButtonExist(): 모든 버튼과 segment의 존재 유무를 확인한다. 
