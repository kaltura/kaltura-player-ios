// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import Foundation
import KalturaNetKit
import SwiftyJSON

let uiConfDirectoryPath = "/UIConfFiles"

public class PlayerConfigManager {
    
    public static let shared = PlayerConfigManager()
    
    private var timeIntervalForUpdating: Double = 24 * 3600
    private var timeIntervalForExpiry: Double = 3 * 24 * 3600

    private var _directoryPath: String?
    private var directoryPath: String {
        if _directoryPath == nil {
            let cachesDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory , FileManager.SearchPathDomainMask.userDomainMask, true)[0]
            _directoryPath = cachesDirectory + uiConfDirectoryPath
        }
        return _directoryPath!
    }
    
    init() {
        createRootFolder()
    }
    
    public func configure(timeIntervalForUpdating: Double, timeIntervalForExpiry: Double) {
        self.timeIntervalForUpdating = timeIntervalForUpdating
        self.timeIntervalForExpiry = timeIntervalForExpiry
    }
    
    public func retrieve(by id: Int, baseUrl: String, partnerId: Int? = nil, ks: String? = nil, completion: @escaping (PlayerConfigObject?, PlayerConfigError?) -> Void) {
        var uiConfFound = false
        
        if let tuple = readFromDisk(configId: id) {
            if let uiconf = UIConfResponseParser.parse(data: tuple.0) as? PlayerConfigObject {
                uiConfFound = true
                completion(uiconf, nil)
                
                if tuple.1 { //update if needed
                    loadFromRemote(by: id, baseUrl: baseUrl, partnerId: partnerId, ks: ks) { (data, error) in
                        if let data = data {
                            self.saveToDisk(configId: id, configJsonObject: data)
                        }
                    }
                }
            }
        }
        if !uiConfFound {
            loadFromRemote(by: id, baseUrl: baseUrl, partnerId: partnerId, ks: ks) { (data, error) in
                if let data = data {
                    let result = UIConfResponseParser.parse(data: data)
                    if let error = result as? PlayerConfigError {
                        completion(nil, error)
                    } else if let uiconf = result as? PlayerConfigObject {
                        self.saveToDisk(configId: id, configJsonObject: data)
                        completion(uiconf, nil)
                    }
                } else {
                    completion(nil, PlayerConfigError(message: error?.localizedDescription, code: nil, args: nil))
                }
            }
        }
    }
    
    private func readFromDisk(configId: Int) -> (Any, Bool)? {
        let filePath = configPath(id: configId)
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }
        
        var shouldUpdateFile = false
        let fileUrl = URL(fileURLWithPath: filePath)
        do {
            let date = try fileUrl.resourceValues(forKeys: Set([URLResourceKey.attributeModificationDateKey])).attributeModificationDate
            if let date = date {
                let timeIntervalSinceLastModify = Date().timeIntervalSince(date)
                if timeIntervalSinceLastModify > timeIntervalForExpiry {
                    return nil
                } else if timeIntervalSinceLastModify > timeIntervalForUpdating {
                    shouldUpdateFile = true
                }
            } else {
                print("retrieving date of file failed: reason unknown")
                return nil
            }
        } catch let error as NSError {
            print("retrieving date of file failed: \(error.localizedDescription)")
            return nil
        }
        
        do {
            let data = try Data.init(contentsOf: fileUrl, options: NSData.ReadingOptions())
            do {
                return (try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()), shouldUpdateFile)
            } catch let error as NSError {
                print("converting data to json failed: \(error.localizedDescription)")
                return nil
            }
        } catch let error as NSError {
            print("reading file failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func saveToDisk(configId: Int, configJsonObject: Any) {
        do {
            let data = try JSONSerialization.data(withJSONObject: configJsonObject, options: JSONSerialization.WritingOptions())
            do {
                try data.write(to: URL(fileURLWithPath: configPath(id: configId)))
            } catch let error as NSError {
                print("writing json to file failed: \(error.localizedDescription)")
            }
            
        } catch let error as NSError {
            print("converting json to data failed: \(error.localizedDescription)")
        }
    }
    
    private func configPath(id: Int) -> String {
        return directoryPath + "/\(id)"
    }
    
    private func loadFromRemote(by id: Int, baseUrl: String, partnerId: Int?, ks: String?, completion: @escaping (Any?, Error?) -> Void) {
        if let request = UIConfService.get(baseUrl: baseUrl + (baseUrl.hasSuffix("/") ? "" : "/") + "api_v3", uiconfId: id, partnerId: partnerId, ks: ks) {
            setBasicParams(on: request)
            request.set(completion: { (response) in
                completion(response.data, response.error)
            })
            USRExecutor.shared.send(request: request.build())
        }
    }
    
    private func setBasicParams(on request: KalturaRequestBuilder) {
        request.setClientTag(clientTag: "kalturaPlayer")
        request.setApiVersion(apiVersion: "3.3.0")
        request.setFormat(format: 1)
    }
    
    private func createRootFolder() {
        let directoryAlreadyCreated = FileManager.default.fileExists(atPath: directoryPath)
        if !directoryAlreadyCreated {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        }
    }
}
