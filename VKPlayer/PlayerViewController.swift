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
    private let player = AVPlayer()
    private var musicModel: MusicModel!
    private var playerTimeObserver: AnyObject!
    
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var artistLabel: NSTextField!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var songProgress: NSSlider!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var songTable: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingIndicator.startAnimation(self)
        volumeSlider.floatValue = player.volume
        
        playerTimeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(1, 1), queue: nil, usingBlock: updatePlayerProgress)
    }
    
    override func viewDidAppear() {
        performSegueWithIdentifier("loginSegue", sender: self)
    }
    
    override func viewWillDisappear() {
        player.removeTimeObserver(playerTimeObserver)
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loginSegue" {
            if let dest = segue.destinationController as? LoginViewController {
                dest.delegate = self
            }
        }
    }
    
    @IBAction func onRewind(sender: NSButton) {
        if songTable.selectedRow - 1 > 0 {
            let index = NSIndexSet(index: songTable.selectedRow - 1)
            songTable.selectRowIndexes(index, byExtendingSelection: false)
        }
    }
    
    @IBAction func onPlay(sender: NSButton) {
        if player.rate == 0 { // Stopped.
            player.play()
        } else {
            player.pause()
        }
    }
    
    @IBAction func onForward(sender: NSButton) {
        onForward()
    }
    
    private func onForward() {
        if songTable.selectedRow + 1 < musicModel?.songCount ?? 0 {
            let index = NSIndexSet(index: songTable.selectedRow + 1)
            songTable.selectRowIndexes(index, byExtendingSelection: false)
        }
    }
    
    @IBAction func onShuffle(sender: NSButton) {
        if musicModel != nil {
            musicModel.shuffle()
            songTable.reloadData()
        }
    }
    
    @IBAction func onReplay(sender: NSButton) {
    }
    
    @IBAction func volumeValueChanged(sender: NSSlider) {
        player.volume = sender.floatValue
    }
    
    @IBAction func songProgressChanged(sender: NSSlider) {
        print("Progress Changed!")
        if player.currentItem != nil {
            let songPos = songProgress.doubleValue * CMTimeGetSeconds(player.currentItem!.duration)/100
            print("Seeking \(songPos)")
            
            player.currentItem!.seekToTime(CMTimeMakeWithSeconds(songPos, 600))
        }
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(itemEndReached), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
        player.pause()
        player.rate = 0
        player.replaceCurrentItemWithPlayerItem(playerItem)
        player.play()
    }
    
    @objc private func itemEndReached() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        onForward()
    }
    
    private func updatePlayerProgress(time: CMTime) {
        //NSLog("TICK")
        let duration = CMTimeGetSeconds(player.currentItem!.duration)
        let time = CMTimeGetSeconds(player.currentTime())
        
        songProgress.doubleValue = (time/duration)*100
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
