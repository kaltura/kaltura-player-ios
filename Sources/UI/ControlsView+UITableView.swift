//
//  ControlsView+UITableView.swift
//  KalturaPlayer
//
//  Created by Vadim Kononov on 15/01/2018.
//

import UIKit
import PlayKit

extension ControlsView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedOption == .audioTracks {
            if let tracks = tracks?.audioTracks, tracks.count > 1 {
                return tracks.count
            }
            return 1
        } else if selectedOption == .captions {
            if let tracks = tracks?.textTracks, tracks.count > 1 {
                return tracks.count
            }
            return 1
        } else {
            return options.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "optionCells", for: indexPath)
        
        if selectedOption == .audioTracks {
            configureAudioTrackCell(cell, indexPath: indexPath)
        } else if selectedOption == .captions {
            configureTextTrackCell(cell, indexPath: indexPath)
        } else {
            cell.textLabel?.text = options[indexPath.row].title
            cell.imageView?.image = UIImage(named: options[indexPath.row].image, in: bundle, compatibleWith: nil)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedOption == .audioTracks || selectedOption == .captions {
            if let collection = (selectedOption == .audioTracks ? tracks?.audioTracks : tracks?.textTracks), collection.count > 1 {
                player?.selectTrack(trackId: collection[indexPath.row].id)
                Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(closeMoreOptions), userInfo: nil, repeats: false)
            }
        } else {
            let option = options[indexPath.row]
            if option == .audioTracks || option == .captions {
                selectedOption = option
            } else if option == .chromecast {
                //TODO: connect chromecast
            }
        }
    }
    
    private func getIndex(for trackId: String, in tracks: [Track]) -> Int {
        var index = 0
        for item in tracks {
            if item.id == trackId {
                return index
            }
            index += 1
        }
        return -1
    }
    
    private func configureAudioTrackCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        if o_tableView.numberOfRows(inSection: 0) == 1 {
            cell.textLabel?.text = "No additional audio tracks found"
        } else {
            if let audioTracks = tracks?.audioTracks {
                (cell as? OptionsTableViewCell)?.isSelectable = true
                cell.textLabel?.text = audioTracks[indexPath.row].title
                if let currentTrack = player?.currentAudioTrack, getIndex(for: currentTrack, in: audioTracks) == indexPath.row {
                    o_tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
    }
    
    private func configureTextTrackCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        if o_tableView.numberOfRows(inSection: 0) == 1 {
            cell.textLabel?.text = "No captions found"
        } else {
            if let textTracks = tracks?.textTracks {
                (cell as? OptionsTableViewCell)?.isSelectable = true
                cell.textLabel?.text = textTracks[indexPath.row].title
                if let currentTrack = player?.currentTextTrack, getIndex(for: currentTrack, in: textTracks) == indexPath.row {
                    o_tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
    }
}
