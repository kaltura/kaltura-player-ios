//
//  KPOVPConfigModel.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 8/6/20.
//

import Foundation
import PlayKit
import CoreData

let OVPConfigEntityName = "OVPConfig"
enum OVPConfigEntityAttribute: String {
    case analyticsUrl
    case analyticsPersistentSessionId
    case createdDate
    case partnerId
}

struct OVPPartnerConfig {
    var analyticsUrl: String
    var analyticsPersistentSessionId: Bool
    var createdDate: Date
    var partnerId: Int64
}

class KPOVPConfigModel {
    static let shared = KPOVPConfigModel()
    
    private init() {}
    
    lazy var persistanteContainer: NSPersistentContainer = {
        
        var dmsConfigModelBundle = Bundle(for: KPOVPConfigModel.self)
        
        #if KalturaPlayerOVP_Package
        dmsConfigModelBundle = Bundle.module
        #endif
        
        guard let modelURL = dmsConfigModelBundle.url(forResource: "KPOVPConfigModel", withExtension: "momd"),
            let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("KPOVPConfigModel is missing from the bundle!")
        }

        let container = NSPersistentContainer(name: "KPOVPConfigModel", managedObjectModel: managedObjectModel)
        
        container.loadPersistentStores { (persistentStoreDescription, error) in
            if let nsError = error as NSError? {
                PKLog.error("An error occurred while loading the ConfigModel. Error: \(nsError)")
            }
        }
        return container
    }()
    
    func saveChanges() {
        let managedContext = persistanteContainer.viewContext
        if managedContext.hasChanges {
            do {
                try managedContext.save()
            } catch {
                let nsError = error as NSError
                PKLog.error("An error occurred while trying to save. Error: \(nsError)")
            }
        }
    }
    
    func fetchPartnerConfig(_ partnerId: Int64) -> OVPPartnerConfig? {
        var ovpConfig: OVPConfig?
        let predicate = NSPredicate(format: "partnerId == %d", partnerId)
        let managedContext = persistanteContainer.viewContext
        let fetchRequest = NSFetchRequest<OVPConfig>(entityName: OVPConfigEntityName)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        do {
            ovpConfig = try managedContext.fetch(fetchRequest).first
        } catch {
            let nsError = error as NSError
            PKLog.error("An error occurred while trying to fetch the partner config. Error: \(nsError)")
        }
        
        guard let config = ovpConfig else { return nil }
        
        guard let analyticsUrl = config.value(forKey: OVPConfigEntityAttribute.analyticsUrl.rawValue) as? String,
            let partnerId = config.value(forKey: OVPConfigEntityAttribute.partnerId.rawValue) as? Int64,
            let analyticsPersistentSessionId = config.value(forKey: OVPConfigEntityAttribute.analyticsPersistentSessionId.rawValue) as? Bool,
            let createdDate = config.value(forKey: OVPConfigEntityAttribute.createdDate.rawValue) as? Date else {
                return nil
        }
        
        return OVPPartnerConfig(analyticsUrl: analyticsUrl,
                                analyticsPersistentSessionId: analyticsPersistentSessionId,
                                createdDate: createdDate,
                                partnerId: partnerId)
    }
    
    func deletePartnerConfig(_ partnerId: Int64) {
        let predicate = NSPredicate(format: "partnerId == %d", partnerId)
        let managedContext = persistanteContainer.viewContext
        let fetchRequest = NSFetchRequest<OVPConfig>(entityName: OVPConfigEntityName)
        fetchRequest.predicate = predicate
        do {
            let configs = try managedContext.fetch(fetchRequest)
            for config in configs {
                managedContext.delete(config)
            }
            saveChanges()
        } catch {
            let nsError = error as NSError
            PKLog.error("An error occurred while trying to delete the partner config. Error: \(nsError)")
        }
    }
    
    func addPartnerConfig(partnerId: Int64, analyticsUrl: String, analyticsPersistentSessionId: Bool) {
        // Delete previous config
        deletePartnerConfig(partnerId)
        
        let managedContext = persistanteContainer.viewContext
        let managedObjectModel = persistanteContainer.managedObjectModel
        
        guard let entity = managedObjectModel.entitiesByName[OVPConfigEntityName] else {
            fatalError("Could not add Partner Config, the entity does not exist!")
        }
        
        let config = NSManagedObject(entity: entity, insertInto: managedContext)
        
        config.setValue(partnerId, forKey: OVPConfigEntityAttribute.partnerId.rawValue)
        config.setValue(analyticsUrl, forKey: OVPConfigEntityAttribute.analyticsUrl.rawValue)
        config.setValue(analyticsPersistentSessionId, forKey: OVPConfigEntityAttribute.analyticsPersistentSessionId.rawValue)

        config.setValue(Date(), forKey: OVPConfigEntityAttribute.createdDate.rawValue)
        saveChanges()
    }
}
