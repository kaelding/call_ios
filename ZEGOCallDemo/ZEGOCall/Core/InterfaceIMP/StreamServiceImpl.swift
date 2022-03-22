//
//  StreamServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/19.
//

import Foundation
import ZegoExpressEngine

class StreamServiceImpl: NSObject {
    
}

extension StreamServiceImpl: StreamService {
    func startPlaying(_ userID: String?, streamView: UIView?) {
        guard let roomID = ServiceManager.shared.roomService.roomInfo?.roomID else { return }
        let streamID = String.getStreamID(userID, roomID: roomID)
        if streamView != nil {
            guard let streamView = streamView else { return }
            let canvas = ZegoCanvas(view: streamView)
            canvas.viewMode = .aspectFill
            if ServiceManager.shared.userService.localUserInfo?.userID == userID {
                ZegoExpressEngine.shared().startPreview(canvas)
            } else {
                ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
            }
        } else {
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
        }
    }
    
    func stopPlaying(_ userID: String?) {
        
    }
}