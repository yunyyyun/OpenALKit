//
//  SoundManager.swift
//  spriteTest
//
//  Created by mengyun on 2018/6/16.
//  Copyright © 2018年 mengyun. All rights reserved.
//

import Foundation
import AVFoundation

var alPlayer = OpenALPlayer.shared() as! OpenALPlayer;

// |0flyup|1hit|2gg|3start|
func playSoundWithTag(tag: Int32) {
    if udata.soundSetStatus==1 {
        alPlayer.doPlay(withTag: tag)
    }
}
