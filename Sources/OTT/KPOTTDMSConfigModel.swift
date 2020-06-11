//
//  KPOTTDMSConfigModel.swift
//  KalturaPlayer
//
//  Created by Nilit Danan on 5/13/20.
//

import Foundation
import PlayKit
import CoreData

let DMSConfigEntityName = "DMSConfig"
enum DMSConfigEntityAttribute: String {
    case analyticsUrl
    case ovpPartnerId
    case ovpServiceUrl
    case partnerId
    case uiConfId
    case createdDate
}

struct OTTDMSConfig {
    var analyticsUrl: String
    var ovpPartnerId: Int64
    var ovpServiceUrl: String
    var partnerId: Int64
    var uiConfId: Int64
    var createdDate: Date
}

class KPOTTDMSConfigModel {
    static let shared = KPOTTDMSConfigModel()
    
    private init() {}
    
    lazy var persistanteContainer: NSPersistentContainer = {
        let dmsConfigModelBundle = Bundle(for: KPOTTDMSConfigModel.self)
        guard let modelURL = dmsConfigModelBundle.url(forResource: "KPOTTDMSConfigModel", withExtension: "momd"),
            let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("KPOTTDMSConfigModel is missing from the bundle!")
        }

        let container = NSPersistentContainer(name: "KPOTTDMSConfigModel", managedObjectModel: managedObjectModel)
        
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
    
    func fetchPartnerConfig(_ partnerId: Int64) -> OTTDMSConfig? {
        var dmsConfig: DMSConfig?
        let predicate = NSPredicate(format: "partnerId == %d", partnerId)
        let managedContext = persistanteContainer.viewContext
        let fetchRequest = NSFetchRequest<DMSConfig>(entityName: DMSConfigEntityName)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        do {
            dmsConfig = try managedContext.fetch(fetchRequest).first
        } catch {
            let nsError = error as NSError
            PKLog.error("An error occurred while trying to fetch the partner config. Error: \(nsError)")
        }
        
        guard let config = dmsConfig else { return nil }
        
        guard let analyticsUrl = config.value(forKey: DMSConfigEntityAttribute.analyticsUrl.rawValue) as? String,
            let ovpPartnerId = config.value(forKey: DMSConfigEntityAttribute.ovpPartnerId.rawValue) as? Int64,
            let ovpServiceUrl = config.value(forKey: DMSConfigEntityAttribute.ovpServiceUrl.rawValue) as? String,
            let partnerId = config.value(forKey: DMSConfigEntityAttribute.partnerId.rawValue) as? Int64,
            let uiConfId = config.value(forKey: DMSConfigEntityAttribute.uiConfId.rawValue) as? Int64,
            let createdDate = config.value(forKey: DMSConfigEntityAttribute.createdDate.rawValue) as? Date else {
                return nil
        }
        
        return OTTDMSConfig(analyticsUrl: analyticsUrl,
                            ovpPartnerId: ovpPartnerId,
                            ovpServiceUrl: ovpServiceUrl,
                            partnerId: partnerId,
                            uiConfId: uiConfId,
                            createdDate: createdDate)
    }
    
    func deletePartnerConfig(_ partnerId: Int64) {
        let predicate = NSPredicate(format: "partnerId == %d", partnerId)
        let managedContext = persistanteContainer.viewContext
        let fetchRequest = NSFetchRequest<DMSConfig>(entityName: DMSConfigEntityName)
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
    
    func addPartnerConfig(partnerId: Int64, ovpPartnerId: Int64, analyticsUrl: String, ovpServiceUrl: String, uiConfId: Int64) {
        // Delete previous config
        deletePartnerConfig(partnerId)
        
        let managedContext = persistanteContainer.viewContext
        let managedObjectModel = persistanteContainer.managedObjectModel
        
        guard let entity = managedObjectModel.entitiesByName[DMSConfigEntityName] else {
            fatalError("Could not add Partner Config, the entity does not exist!")
        }
        
        let config = NSManagedObject(entity: entity, insertInto: managedContext)
        
        config.setValue(partnerId, forKey: DMSConfigEntityAttribute.partnerId.rawValue)
        config.setValue(ovpPartnerId, forKey: DMSConfigEntityAttribute.ovpPartnerId.rawValue)
        config.setValue(analyticsUrl, forKey: DMSConfigEntityAttribute.analyticsUrl.rawValue)
        config.setValue(ovpServiceUrl, forKey: DMSConfigEntityAttribute.ovpServiceUrl.rawValue)
        config.setValue(uiConfId, forKey: DMSConfigEntityAttribute.uiConfId.rawValue)
        config.setValue(Date(), forKey: DMSConfigEntityAttribute.createdDate.rawValue)
        saveChanges()
    }
}
