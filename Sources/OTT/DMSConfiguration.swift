//
//  DMSConfiguration.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/17/20.
//

import Foundation

struct DMSConfiguration: Codable {
    var params: DMSConfigParams
}

struct DMSConfigParams: Codable {
    var analyticsUrl: String
    var ovpServiceUrl: String
    var ovpPartnerId: Int64
    var uiConfId: Int64
}
