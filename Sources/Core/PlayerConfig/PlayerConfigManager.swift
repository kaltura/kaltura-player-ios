//
//  UIConfManager.swift
//  KalturaPlayer
//
//  Created by Vadim Kononov on 10/12/2017.
//

import Foundation
import KalturaNetKit
import SwiftyJSON

let uiConfDirectoryPath = "/UIConfFiles"

public class PlayerConfigManager {
    
    public static let shared = PlayerConfigManager()
    
    private var data: [Int : PlayerConfigObject] = [:]
    
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
    
    public func retrieve(by id: Int, baseUrl: String, partnerId: Int? = nil, ks: String? = nil, completion: @escaping (PlayerConfigObject?, PlayerConfigError?) -> Void) {
        if let uiconf = data[id] {
            completion(uiconf, nil)
        } else if let jsonObject = readFromDisk(configId: id) {
            if let uiconf = UIConfResponseParser.parse(data: jsonObject) as? PlayerConfigObject {
                data[id] = uiconf
                completion(uiconf, nil)
            } else {
                completion(nil, PlayerConfigError(message: "Unknown error on parse json object", code: nil, args: nil))
            }
        } else {
            loadFromRemote(by: id, baseUrl: baseUrl, partnerId: partnerId, ks: ks) { (data, error) in
                if let data = data {
                    let result = UIConfResponseParser.parse(data: data)
                    if let error = result as? PlayerConfigError {
                        completion(nil, error)
                    } else if let uiconf = result as? PlayerConfigObject {
                        self.saveToDisk(configId: id, configJsonObject: data)
                        self.data[id] = uiconf
                        completion(uiconf, nil)
                    }
                } else {
                    completion(nil, PlayerConfigError(message: error?.localizedDescription, code: nil, args: nil))
                }
            }
        }
    }
    
    private func readFromDisk(configId: Int) -> Any? {
        let filePath = configPath(id: configId)
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }
        
        do {
            let data = try Data.init(contentsOf: URL(fileURLWithPath: filePath), options: NSData.ReadingOptions())
            do {
                return try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
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
            request.setOVPBasicParams()
            request.set(completion: { (response) in
                completion(response.data, response.error)
            })
            USRExecutor.shared.send(request: request.build())
        }
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
