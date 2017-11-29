//
//  ControlsView.swift
//  KalturaPlayer
//
//  Created by Vadik on 23/11/2017.
//

import UIKit
import PlayKit

class ControlsView: UIView {

    var view: UIView!
    weak var player: Player?
    var timer: Timer?
    
    var bundle: Bundle? {
        if let bundleUrl = Bundle(for: type(of: self)).url(forResource: "KalturaPlayer", withExtension: "bundle") {
            return Bundle(url: bundleUrl)
        }
        return nil
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadXib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
    }
    
    init(player: Player) {
        super.init(frame: CGRect.zero)
        self.player = player
        loadXib()
        registerToEvents()
    }
    
    func loadXib() {
        if let bundle = bundle {
            view = bundle.loadNibNamed("ControlsView", owner: self, options: nil)?[0] as! UIView
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0))
        }
    }
    
    @IBOutlet weak var o_currentTimeLabelWidth: NSLayoutConstraint!
    @IBOutlet weak var o_durationLabelWidth: NSLayoutConstraint!
    @IBOutlet weak var o_currentTimeLabel: UILabel!
    @IBOutlet weak var o_durationLabel: UILabel!
    @IBOutlet var o_playPauseButton: UIButton!
    @IBOutlet weak var o_slider: UISlider! {
        didSet {
            o_slider.setThumbImage(UIImage.init(named: "circle", in: bundle, compatibleWith: nil), for: .normal)
        }
    }
    
    @IBAction func didTapPlayPause(sender: UIButton) {
        if o_playPauseButton.tag == 0 {
            player?.play()
        } else {
            player?.pause()
        }
    }
    @IBAction func didStartSliding(_ sender: UISlider) {
        timer?.invalidate()
        timer = nil
    }
    
    @IBAction func didStopSliding(_ sender: UISlider) {
        player?.currentTime = (player?.duration ?? 0) * Double(o_slider.value)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if let duration = player?.duration, !duration.isNaN {
            o_currentTimeLabel.text = getTimeRepresentation(time: duration * Double(sender.value))
        }
    }
    
    func registerToEvents() {
        player?.addObserver(self, events: [PlayerEvent.loadedMetadata, PlayerEvent.playing, PlayerEvent.pause, PlayerEvent.seeked, PlayerEvent.ended], block: { [weak self] (event) in
            if type(of: event) == PlayerEvent.loadedMetadata {
                self?.playbackUpdate()
            } else if type(of: event) == PlayerEvent.playing {
                self?.o_playPauseButton.setImage(UIImage.init(named: "pause", in: self?.bundle, compatibleWith: nil), for: .normal)
                self?.o_playPauseButton.tag = 1
                self?.startSliderTimer()
            } else if type(of: event) == PlayerEvent.pause {
                self?.o_playPauseButton.setImage(UIImage.init(named: "play", in: self?.bundle, compatibleWith: nil), for: .normal)
                self?.o_playPauseButton.tag = 0
                self?.stopSliderTimer()
            } else if type(of: event) == PlayerEvent.seeked {
                if self?.player?.isPlaying == true {
                    self?.startSliderTimer()
                } else {
                    self?.playbackUpdate()
                }
            } else if type(of: event) == PlayerEvent.ended {
                self?.o_playPauseButton.setImage(UIImage.init(named: "play", in: self?.bundle, compatibleWith: nil), for: .normal)
                self?.o_playPauseButton.tag = 0
                self?.stopSliderTimer()
                self?.player?.currentTime = 0
            }
        })
    }
    
    @objc func playbackUpdate() {
        if let player = player {
            let currentTime = player.currentTime
            let duration = player.duration
            
            if currentTime.isNaN || duration.isNaN {
                return
            }
            
            if duration > 3600 {
                o_durationLabelWidth.constant = 62
                o_currentTimeLabelWidth.constant = 62
            } else {
                o_durationLabelWidth.constant = 40
                o_currentTimeLabelWidth.constant = 40
            }
            
            o_slider.value = Float(currentTime / duration)
            o_currentTimeLabel.text = getTimeRepresentation(time: currentTime)
            o_durationLabel.text = getTimeRepresentation(time: duration)
        }
    }
    
    func startSliderTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(playbackUpdate), userInfo: nil, repeats: true)
    }
    
    func stopSliderTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func getTimeRepresentation(time: TimeInterval) -> String {
        if time > 3600 {
            let hours = Int(time / 3600)
            let minutes = Int(time.truncatingRemainder(dividingBy: 3600) / 60)
            let seconds = Int(time.truncatingRemainder(dividingBy: 60))
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            let minutes = Int(time / 60)
            let seconds = Int(time.truncatingRemainder(dividingBy: 60))
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
