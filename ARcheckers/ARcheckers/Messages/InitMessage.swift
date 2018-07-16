//
//  InitMessage.swift
//  ARcheckers
//
//  Created by Denis Malykh on 16.07.2018.
//  Copyright © 2018 Yandex. All rights reserved.
//

import Foundation

struct InitMessage : Codable {
    let worldMap: Data?
    let checkerboardPosition: Data
}
