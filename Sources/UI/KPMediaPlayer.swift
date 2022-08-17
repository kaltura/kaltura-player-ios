//
//  KPMediaPlayer.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 17/12/2021.
//

import UIKit
import PlayKit

class PPRButton: UIButton {
    enum PPRButtonState {
        case play
        case pause
        case replay
    }
    var displayState: PPRButtonState = .play {
        didSet {
            let bundle = Bundle(for: type(of: self))
            switch displayState {
            case .play:
                self.setImage(UIImage(named: "KPPlay", in: bundle, compatibleWith: nil), for: .normal)
            case .pause:
                self.setImage(UIImage(named: "KPPause", in: bundle, compatibleWith: nil), for: .normal)
            case .replay:
                self.setImage(UIImage(named: "KPReload", in: bundle, compatibleWith: nil), for: .normal)
            }
        }
    }
}

public protocol KPMediaPlayerDelegate: AnyObject {
    
    func closeButtonClicked(onMediaPlayer mediaPlayer: KPMediaPlayer)
    func errorOccurred(_ error: NSError?, onMediaPlayer mediaPlayer: KPMediaPlayer)
}

@IBDesignable
public class KPMediaPlayer: UIView {
    
    public var player: KalturaPlayer? {
        willSet {
            player?.removeObserver(self, events: KPPlayerEvent.allEventTypes)
            player?.removeObserver(self, events: KPAdEvent.allEventTypes)
        }
        didSet {
            guard let player = player else { return }

            registerPlayerEvents()
            registerAdEvents()
            
            player.view = kalturaPlayerView
            
            if player.playerOptions.autoPlay {
                playPauseButton.displayState = .pause
                showPlayerControllers(false)
            } else {
                activityIndicator.stopAnimating()
                playPauseButton.displayState = .play
                showPlayerControllers(true)
            }
        }
    }
    
    public weak var delegate: KPMediaPlayerDelegate?
    
    // MARK: -
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initSubViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }
    
    func initSubViews() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "KPMediaPlayer", bundle: bundle)
        nib.instantiate(withOwner: self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)
        self.addConstraints()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(controllersInteractiveViewTapped))
        controllersInteractiveView.addGestureRecognizer(gesture)
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
        }
        
        settingsVisualEffectView.alpha = 0.0
        middleVisualEffectView.layer.cornerRadius = 40.0
        playPauseButton.displayState = .play
        activityIndicator.layer.cornerRadius = 15.0
    }
    
    // MARK: - Private
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var kalturaPlayerView: KalturaPlayerView!
    
    // We have to have the 'controllersInteractiveView' and set the tap guesture on it and not on the 'kalturaPlayerView' because IMA's ad view is above the player's view.
    @IBOutlet private weak var controllersInteractiveView: UIView!
    @IBOutlet private weak var controllersInteractiveViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var controllersInteractiveViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var topVisualEffectView: UIVisualEffectView!
    @IBOutlet private weak var topVisualEffectViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomVisualEffectView: UIVisualEffectView!
    @IBOutlet private weak var bottomVisualEffectViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var middleVisualEffectView: UIVisualEffectView!
    @IBOutlet private weak var settingsVisualEffectView: UIVisualEffectView!
    private let topBottomVisualEffectViewHeight: Float = 50.0
    
    @IBOutlet private weak var playPauseButton: PPRButton!
    
    @IBOutlet private weak var mediaProgressSlider: KPUISlider!
    private var userSeekInProgress: Bool = false {
        didSet {
            mediaProgressSlider.isEnabled = !self.userSeekInProgress
        }
    }
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var audioTracks: [KPTrack]?
    private var textTracks: [KPTrack]?
    private var currentTextTrackID: String = "sbtl:-1"
    
    private var mediaEnded: Bool = false
    private var adsLoaded: Bool = false
    private var allAdsCompleted: Bool = false
    private var adIsPlaying: Bool = false {
        didSet {
            controllersInteractiveViewTopConstraint.constant = CGFloat(adIsPlaying ? adLearnMoreButtonHeight : 0)
            controllersInteractiveViewBottomConstraint.constant = CGFloat(adIsPlaying ? -adSkipButtonHeight : 0)
        }
    }
    
    private let adLearnMoreButtonHeight = 50.0
    private let adSkipButtonHeight = 75.0
    
    private var preferredPlaybackRate: Float = 1.0 {
        didSet {
            guard let player = player else { return }
            if player.isPlaying, !adIsPlaying {
                player.rate = preferredPlaybackRate
            }
        }
    }
    
    private func addConstraints() {
        NSLayoutConstraint.activate([self.topAnchor.constraint(equalTo: contentView.topAnchor),
                                     self.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                                     self.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                                     self.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)])
    }
    
    private func resetStates() {
        mediaEnded = false
        adsLoaded = false
        allAdsCompleted = false
        adIsPlaying = false
        preferredPlaybackRate = 1.0
    }
    
    @objc private func controllersInteractiveViewTapped() {
        let show = !(topVisualEffectViewHeightConstraint.constant == CGFloat(topBottomVisualEffectViewHeight))
        showPlayerControllers(show)
    }
    
    private func showPlayerControllers(_ show: Bool, delay: Double = 0.0) {
        let constantValue: Float = show ? topBottomVisualEffectViewHeight : 0.0
        UIView.animate(withDuration: 0.5, delay: delay, animations: {
            self.topVisualEffectViewHeightConstraint.constant = CGFloat(constantValue)
            self.bottomVisualEffectViewHeightConstraint.constant = CGFloat(constantValue)
            self.middleVisualEffectView.alpha = show ? 1.0 : 0.0
            self.layoutIfNeeded()
        })
    }
    
    private func getTimeRepresentation(_ time: TimeInterval) -> String {
        if time > 3600 {
            let hours = Int(time / 3600)
            let minutes = Int(time.truncatingRemainder(dividingBy: 3600) / 60)
            let seconds = Int(time.truncatingRemainder(dividingBy: 60))
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            let minutes = Int(time / 60)
            let seconds = Int(time.truncatingRemainder(dividingBy: 60))
            return String(format: "00:%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Public Functions
extension KPMediaPlayer {
    
    public func videoControlsOverlays() -> [UIView]? {
        return [controllersInteractiveView, topVisualEffectView, middleVisualEffectView, bottomVisualEffectView]
    }
}

// MARK: -
extension KPMediaPlayer {
    // MARK: Player Events
    
    private func registerPlayerEvents() {
        registerPlaybackEvents()
        handleTracks()
        handleProgress()
        handleBufferedProgress()
        handleDuration()
        handleError()
    }
    
    private func registerPlaybackEvents() {
        player?.addObserver(self, events: [KPPlayerEvent.sourceSelected, KPPlayerEvent.loadedMetadata, KPPlayerEvent.ended, KPPlayerEvent.play, KPPlayerEvent.playing, KPPlayerEvent.pause, KPPlayerEvent.canPlay, KPPlayerEvent.seeking, KPPlayerEvent.seeked, KPPlayerEvent.playbackStalled, KPPlayerEvent.stateChanged, KPPlayerEvent.playbackRate, KPPlayerEvent.stopped]) { [weak self] event in
            guard let self = self, let player = self.player else { return }
            
            PKLog.info("Event triggered: " + event.description)
            
            DispatchQueue.main.async {
                switch event {
                case is KPPlayerEvent.SourceSelected:
                    self.resetStates()
                    self.activityIndicator.startAnimating()
                    
                    if player.playerOptions.autoPlay {
                        self.playPauseButton.displayState = .pause
                        self.showPlayerControllers(false)
                    } else {
                        self.activityIndicator.stopAnimating()
                        self.playPauseButton.displayState = .play
                        self.showPlayerControllers(true)
                    }
                case is KPPlayerEvent.LoadedMetadata:
                    if player.isLive() {
                        self.mediaProgressSlider.thumbTintColor = UIColor.red
                    } else {
                        self.mediaProgressSlider.thumbTintColor = UIColor.white
                    }
                case is KPPlayerEvent.Ended:
                    self.mediaEnded = true
                    if self.adsLoaded == false || self.allAdsCompleted {
                        // No ads on media or all ads where completed
                        self.playPauseButton.displayState = .replay
                        self.showPlayerControllers(true)
                    }
                case is KPPlayerEvent.Play:
                    self.playPauseButton.displayState = .pause
                case is KPPlayerEvent.Playing:
                    self.activityIndicator.stopAnimating()
                    self.playPauseButton.displayState = .pause
                    self.showPlayerControllers(false)
                case is KPPlayerEvent.Pause:
                    self.playPauseButton.displayState = .play
                case is KPPlayerEvent.CanPlay:
                    self.activityIndicator.stopAnimating()
                case is KPPlayerEvent.Seeking:
                    if player.isPlaying {
                        self.showPlayerControllers(false, delay: 0.5)
                    } else {
                        self.activityIndicator.startAnimating()
                    }
                case is KPPlayerEvent.Seeked:
                    self.userSeekInProgress = false
                    self.activityIndicator.stopAnimating()
                    if player.currentTime < player.duration, self.playPauseButton.displayState == .replay {
                        self.playPauseButton.displayState = .play
                    }
                case is KPPlayerEvent.PlaybackStalled:
                    if !player.isPlaying {
                        self.activityIndicator.startAnimating()
                    }
                case is KPPlayerEvent.StateChanged:
                    switch event.newState {
                    case .buffering:
                        if !player.isPlaying {
                            self.activityIndicator.startAnimating()
                        }
                    case .ready:
                        self.activityIndicator.stopAnimating()
                    default:
                        break
                    }
                case is KPPlayerEvent.PlaybackRate:
                    if event.palybackRate == 0 {
                        self.playPauseButton.displayState = .play
                    } else {
                        self.playPauseButton.displayState = .pause
                    }
                case is KPPlayerEvent.Stopped:
                    self.mediaProgressSlider.value = 0
                    self.currentTimeLabel.text = "00:00:00"
                    self.durationLabel.text = "00:00:00"
                    self.audioTracks = nil
                    self.textTracks = nil
                    self.resetStates()
                default:
                    break
                }
            }
        }
    }
    
    private func handleTracks() {
        player?.addObserver(self, events: [KPPlayerEvent.tracksAvailable]) { [weak self] event in
            guard let self = self else { return }
            guard let tracks = event.tracks else {
                PKLog.debug("No Tracks Available")
                return
            }
            
            self.audioTracks = tracks.audioTracks
            self.textTracks = tracks.textTracks
        }
        
        player?.addObserver(self, event: KPPlayerEvent.textTrackChanged) { [weak self] event in
            self?.currentTextTrackID = event.selectedTrack?.id ?? "sbtl:-1"
        }
    }
    
    private func handleProgress() {
        player?.addObserver(self, events: [KPPlayerEvent.playheadUpdate]) { [weak self] event in
            
            guard let self = self, let player = self.player else { return }
            
            if self.userSeekInProgress { return }
            
            guard let currentTimeNumber = event.currentTime else { return }
            let currentTime = self.getTimeRepresentation(currentTimeNumber.doubleValue)
            DispatchQueue.main.async {
                self.currentTimeLabel.text = currentTime
                self.mediaProgressSlider.value = Float(currentTimeNumber.doubleValue / player.duration)
            }
        }
    }
    
    private func handleBufferedProgress() {
        player?.addObserver(self, event: KPPlayerEvent.loadedTimeRanges) { [weak self] event in
            guard let self = self, let player = self.player else { return }

            if self.userSeekInProgress { return }

            DispatchQueue.main.async {
                self.mediaProgressSlider.bufferValue = Float(player.bufferedTime / player.duration)
            }
        }
    }
    
    private func handleDuration() {
        player?.addObserver(self, events: [KPPlayerEvent.durationChanged]) { [weak self] event in
            guard let self = self, let player = self.player else { return }
            
            let duration = self.getTimeRepresentation(player.duration)
            DispatchQueue.main.async {
                self.durationLabel.text = duration
            }
        }
    }
    
    private func handleError() {
        player?.addObserver(self, events: [KPPlayerEvent.error]) { [weak self] event in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            
            self.delegate?.errorOccurred(event.error, onMediaPlayer: self)
        }
    }
    
    // MARK: - IMA Events
    
    private func registerAdEvents() {
        player?.addObserver(self, events: [KPAdEvent.adLoaded, KPAdEvent.adPaused, KPAdEvent.adResumed, KPAdEvent.adStartedBuffering, KPAdEvent.adPlaybackReady, KPAdEvent.adStarted, KPAdEvent.adComplete, KPAdEvent.adSkipped, KPAdEvent.allAdsCompleted, KPAdEvent.adDidRequestContentPause, KPAdEvent.adDidRequestContentResume]) { [weak self] adEvent in
            guard let self = self, let player = self.player else { return }
            
            PKLog.info("Event triggered: " + adEvent.description)
            
            DispatchQueue.main.async {
                switch adEvent {
                case is KPAdEvent.AdLoaded:
                    self.adsLoaded = true
                case is KPAdEvent.AdPaused:
                    self.playPauseButton.displayState = .play
                case is KPAdEvent.AdResumed:
                    self.activityIndicator.stopAnimating()
                    self.playPauseButton.displayState = .pause
                case is KPAdEvent.AdStartedBuffering:
                    if !player.isPlaying {
                        self.activityIndicator.startAnimating()
                    }
                case is KPAdEvent.AdPlaybackReady:
                    self.activityIndicator.stopAnimating()
                case is KPAdEvent.AdStarted:
                    self.activityIndicator.stopAnimating()
                    self.playPauseButton.displayState = .pause
                    self.mediaProgressSlider.isEnabled = false
                case is KPAdEvent.AdComplete:
                    self.mediaProgressSlider.isEnabled = true
                case is KPAdEvent.AdSkipped:
                    self.mediaProgressSlider.isEnabled = true
                case is KPAdEvent.AllAdsCompleted:
                    self.allAdsCompleted = true
                    // In case of a post-roll the media has ended
                    if self.mediaEnded {
                        self.playPauseButton.displayState = .replay
                        self.showPlayerControllers(true)
                    }
                case is KPAdEvent.AdDidRequestContentPause:
                    self.adIsPlaying = true
                case is KPAdEvent.AdDidRequestContentResume:
                    self.adIsPlaying = false
                    player.rate = self.preferredPlaybackRate
                default:
                    break
                }
            }
        }
    }
}

// MARK: - IBActions

extension KPMediaPlayer {
    @IBAction private func openSettingsTouched(_ sender: Any) {
        showPlayerControllers(false)
        UIView.animate(withDuration: 0.5, delay: 0, options: .transitionCrossDissolve, animations: {
            self.settingsVisualEffectView.alpha = 1.0
        }, completion: nil)
    }
    
    @IBAction private func closeSettingsTouched(_ sender: Any) {
        UIView.animate(withDuration: 0.5, delay: 0, options: .transitionCrossDissolve, animations: {
            self.settingsVisualEffectView.alpha = 0.0
        }, completion: {(succeded) in
            self.showPlayerControllers(true)
        })
    }
    
    @IBAction private func speechTouched(_ button: UIButton) {
        guard let tracks = audioTracks else { return }
        
        let alertController = UIAlertController(title: "Select Speech", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        for track in tracks {
            alertController.addAction(UIAlertAction(title: track.title,
                                                    style: UIAlertAction.Style.default,
                                                    handler: { (alertAction) in
                self.player?.selectTrack(trackId: track.id)
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
            popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
        }
        
        window?.rootViewController?.presentedViewController?.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction private func subtitleTouched(_ button: UIButton) {
        guard let tracks = textTracks else { return }
        
        let alertController = UIAlertController(title: "Select Subtitle", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        for track in tracks {
            alertController.addAction(UIAlertAction(title: track.id == currentTextTrackID ? "-> " + track.title : track.title,
                                                    style: UIAlertAction.Style.default,
                                                    handler: { (alertAction) in
                self.player?.selectTrack(trackId: track.id)
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
            popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
        }
        
        window?.rootViewController?.presentedViewController?.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction private func speedRateTouched(_ button: UIButton) {
        guard let player = player else { return }
        
        let alertController = UIAlertController(title: "Select Speed Rate", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        alertController.addAction(UIAlertAction(title: (player.rate == 1.0 ? "-> " : "") + "Normal",
                                                style: UIAlertAction.Style.default,
                                                handler: { (alertAction) in
            self.preferredPlaybackRate = 1
        }))
        alertController.addAction(UIAlertAction(title: (player.rate == 1.5 ? "-> " : "") + "x1.5",
                                                style: UIAlertAction.Style.default,
                                                handler: { (alertAction) in
            self.preferredPlaybackRate = 1.5
        }))
        alertController.addAction(UIAlertAction(title: (player.rate == 2.0 ? "-> " : "") + "x2",
                                                style: UIAlertAction.Style.default,
                                                handler: { (alertAction) in
            self.preferredPlaybackRate = 2
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
            popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
        }
        
        window?.rootViewController?.presentedViewController?.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction private func closeTouched(_ sender: Any) {
        delegate?.closeButtonClicked(onMediaPlayer: self)
    }
    
    @IBAction func mediaProgressSliderTouchDown(_ sender: UISlider) {
        userSeekInProgress = true
    }
    
    @IBAction func mediaProgressSliderTouchUpOutside(_ sender: UISlider) {
        userSeekInProgress = false
    }
    
    @IBAction func mediaProgressSliderTouchUpInside(_ sender: UISlider) {
        guard let player = self.player else { return }
        
        let currentValue = Double(sender.value)
        let seekTo = currentValue * player.duration
        player.seek(to: seekTo)
    }
    
    @IBAction private func playButtonTouched(_ sender: Any) {
        guard let player = self.player else { return }
        
        if playPauseButton.displayState == .replay {
            player.replay()
            showPlayerControllers(false, delay: 0.5)
        } else if player.isPlaying || player.rate > 0 {
            player.pause()
        } else {
            player.play()
            showPlayerControllers(false)
            if !adIsPlaying {
                player.rate = preferredPlaybackRate
            }
        }
    }
}
