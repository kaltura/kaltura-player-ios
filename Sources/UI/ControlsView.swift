// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import PlayKit

protocol ControlsViewDelegate: class {
    func controlsViewDidRequestPlayWithoutMediaEntry(_ controlsView: ControlsView)
}

enum PlayerOption {
    case audioTracks
    case captions
    case chromecast
    
    var title: String {
        switch self {
        case .audioTracks:
            return "Audio Tracks"
        case .captions:
            return "Captions"
        case .chromecast:
            return "Chromecast"
        }
    }
    
    var image: String {
        switch self {
        case .audioTracks:
            return "audioTrack"
        case .captions:
            return "cc"
        case .chromecast:
            return "chromecastIcon"
        }
    }
}

class ControlsView: UIView {

    var view: UIView!
    weak var player: Player?
    weak var delegate: ControlsViewDelegate?
    var timer: Timer?
    var tracks: PKTracks?
    var options: [PlayerOption] = [.captions, .audioTracks, .chromecast]
    var selectedOption: PlayerOption? {
        didSet {
            o_tableView.reloadSections([0], with: selectedOption == nil ? .right : .left)
            o_backOptionsButton.isHidden = selectedOption == nil
        }
    }
    
    var bundle: Bundle? {
        if let bundleUrl = Bundle(for: type(of: self)).url(forResource: "KalturaPlayer", withExtension: "bundle") {
            return Bundle(url: bundleUrl)
        }
        return nil
    }
    
    @IBOutlet weak var o_backOptionsButton: UIButton!
    @IBOutlet weak var o_moreOptionsContainer: UIView!
    @IBOutlet weak var o_tableView: UITableView! {
        didSet {
            o_tableView.register(OptionsTableViewCell.self, forCellReuseIdentifier: "optionCells")
        }
    }
    
    @IBOutlet weak var o_currentTimeLabelWidth: NSLayoutConstraint!
    @IBOutlet weak var o_durationLabelWidth: NSLayoutConstraint!
    @IBOutlet weak var o_currentTimeLabel: UILabel!
    @IBOutlet weak var o_durationLabel: UILabel!
    @IBOutlet weak var o_playPauseButton: UIButton!
    @IBOutlet weak var o_slider: UISlider! {
        didSet {
            o_slider.setThumbImage(UIImage.init(named: "circle", in: bundle, compatibleWith: nil), for: .normal)
        }
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
    
    @IBAction func didTapPlayPause(sender: UIButton) {
        if o_playPauseButton.tag == 0 {
            if let _ = player?.mediaEntry {
                player?.play()
            } else {
                delegate?.controlsViewDidRequestPlayWithoutMediaEntry(self)
            }
        } else {
            player?.pause()
        }
    }
    
    @IBAction func didTapMore(_ sender: UIButton) {
        o_moreOptionsContainer.isHidden = false
    }
    
    @IBAction func didTapExitMoreOptions(_ sender: UIButton) {
       closeMoreOptions()
    }
    
    @objc func closeMoreOptions() {
        o_moreOptionsContainer.isHidden = true
        selectedOption = nil
    }
    
    @IBAction func didStartSliding(_ sender: UISlider) {
        timer?.invalidate()
        timer = nil
    }
    
    @IBAction func didTapBackOptions(_ sender: UIButton) {
        selectedOption = nil
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
        let events = [PlayerEvent.loadedMetadata, PlayerEvent.playing, PlayerEvent.pause, PlayerEvent.seeked, PlayerEvent.ended, PlayerEvent.tracksAvailable]
        player?.addObserver(self, events: events, block: { [weak self] (event) in
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
            } else if type(of: event) == PlayerEvent.tracksAvailable {
                self?.tracks = event.tracks
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
