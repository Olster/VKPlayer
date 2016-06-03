//
//  PlayerViewController.swift
//  VKPlayer
//
//  Created by Pavlo Denysiuk on 5/18/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa
import AVFoundation

class PlayerViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, LoginDelegate, MusicModelDelegate {
    let player = AVPlayer()
    var musicModel: MusicModel!
    
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var artistLabel: NSTextField!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var songProgress: NSSlider!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var songTable: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingIndicator.startAnimation(self)
    }
    
    override func viewDidAppear() {
        performSegueWithIdentifier("loginSegue", sender: self)
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loginSegue" {
            if let dest = segue.destinationController as? LoginViewController {
                dest.delegate = self
            }
        }
    }
    
    @IBAction func onRewind(sender: NSButton) {
    }
    
    @IBAction func onPlay(sender: NSButton) {
        if player.rate == 0 { // Stopped.
            player.play()
        } else {
            player.pause()
        }
    }
    
    @IBAction func onForward(sender: NSButton) {
    }
    
    @IBAction func onShuffle(sender: NSButton) {
    }
    
    @IBAction func onReplay(sender: NSButton) {
    }
    
    // MARK: - Song list setup.
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return musicModel?.songCount ?? 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if musicModel == nil {
            return nil
        }
        
        let audio = musicModel.audioAt(row)
        if let view = tableView.makeViewWithIdentifier("SongCellView", owner: self) as? SongCellView {
            view.artistTitle = "\(audio.artist) - \(audio.title)"
            view.duration = audio.duration
            return view
        }
        
        return nil
    }
    
    // MARK: - Song list handler.
    func tableViewSelectionDidChange(notification: NSNotification) {
        // Don't care about removing selection.
        if songTable.numberOfSelectedRows > 0 {
            loadingIndicator.startAnimation(self)
            
            musicModel.providePlayableAt(songTable.selectedRow, handler: play)
        }
    }
    
    private func play(audio: Audio?, url: NSURL?) {
        loadingIndicator.stopAnimation(self)
        
        guard url != nil && audio != nil else {
            NSLog("Can't play song: path to file is nil")
            return
        }
        
        let asset = AVAsset(URL: url!)
        guard asset.playable else {
            NSLog("Asset for audio (\(audio)) isn't playable")
            return
        }
        
        artistLabel.stringValue = audio!.artist
        titleLabel.stringValue = audio!.title
        
        let playerItem = AVPlayerItem(asset: asset)
        player.pause()
        player.rate = 0
        player.replaceCurrentItemWithPlayerItem(playerItem)
        player.play()
    }
    
    // MARK: - LoginDelegate implementation
    func loginSucceeded(token: String, expiresIn: String, userID: String) {
        musicModel = MusicModel(userID: userID, token: token, expiresIn: expiresIn)
        musicModel.delegate = self
        musicModel.loadMusicInfo()
    }
    
    func loginFailed(url: String) {
        NSLog("Error logging in: \(url)")
        // TODO: Display an error and handle the situation.
    }
    
    // MARK: - MusicModelDelegate implementation
    func loadMusicInfoSucceded() {
        loadingIndicator.stopAnimation(self)
        songTable.reloadData()
    }
    
    func loadMusicInfoFailed(error: NSError) {
        loadingIndicator.stopAnimation(self)
        NSLog("Failed to load music info: \(error)")
    }
}
