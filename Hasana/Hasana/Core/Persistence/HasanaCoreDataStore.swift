//
//  HasanaCoreDataStore.swift
//  Hasana
//
//  Created by iOS Swift RealityKit Developer on 2026-05-26.
//

import Foundation
import CoreData
import Combine
import CryptoKit
import SwiftUI
import Observation

// ==========================================
// MARK: - Core Data Store Errors
// ==========================================

/// Error enum representing various failure cases in the Hasana persistence layer.
public enum HasanaStoreError: LocalizedError {
    case storeCreationFailed(String)
    case entityNotFound(String)
    case migrationFailed(String)
    case serializationError(String)
    case encryptionError(String)
    case decryptionError(String)
    case backupFailed(String)
    case restoreFailed(String)
    case invalidBackupPayload
    case contextSaveFailed(Error)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .storeCreationFailed(let message):
            return "Core Data Store creation failed: \(message)"
        case .entityNotFound(let name):
            return "Entity '\(name)' not found in persistent store."
        case .migrationFailed(let details):
            return "Database progressive migration failed: \(details)"
        case .serializationError(let details):
            return "Failed to serialize/deserialize payload: \(details)"
        case .encryptionError(let details):
            return "Cryptographic encryption failed: \(details)"
        case .decryptionError(let details):
            return "Cryptographic decryption failed: \(details)"
        case .backupFailed(let details):
            return "Database backup failed: \(details)"
        case .restoreFailed(let details):
            return "Database restore failed: \(details)"
        case .invalidBackupPayload:
            return "Backup file contains invalid metadata or is corrupted."
        case .contextSaveFailed(let error):
            return "Failed to save managed object context: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unknown error occurred in the persistence layer: \(error.localizedDescription)"
        }
    }
}

// ==========================================
// MARK: - Domain Swift Structs
// ==========================================

/// Decoupled Swift model for worship logs.
public struct WorshipLog: Codable, Identifiable, Hashable {
    public var id: UUID
    public var type: String
    public var name: String
    public var value: Double
    public var targetValue: Double
    public var timestamp: Date
    public var notes: String?
    public var dateKey: String
    public var isSynced: Bool
    public var extraData: [String: String]?
    
    public init(
        id: UUID = UUID(),
        type: String,
        name: String,
        value: Double,
        targetValue: Double,
        timestamp: Date = Date(),
        notes: String? = nil,
        dateKey: String? = nil,
        isSynced: Bool = false,
        extraData: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.value = value
        self.targetValue = targetValue
        self.timestamp = timestamp
        self.notes = notes
        
        if let dateKey = dateKey {
            self.dateKey = dateKey
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            self.dateKey = formatter.string(from: timestamp)
        }
        
        self.isSynced = isSynced
        self.extraData = extraData
    }
}

/// Decoupled Swift model for settings.
public struct SettingItem: Codable, Hashable {
    public var key: String
    public var value: Data?
    public var updatedAt: Date
    
    public init(key: String, value: Data?, updatedAt: Date = Date()) {
        self.key = key
        self.value = value
        self.updatedAt = updatedAt
    }
}

/// Decoupled Swift model for cached or pre-computed worship statistics.
public struct WorshipStats: Codable, Identifiable, Hashable {
    public var id: UUID
    public var dateKey: String
    public var type: String // "daily", "weekly", "monthly", "streak"
    public var streakCount: Int
    public var completionRate: Double
    public var pointsEarned: Int64
    public var lastCalculated: Date
    public var metaData: [String: String]?
    
    public init(
        id: UUID = UUID(),
        dateKey: String,
        type: String,
        streakCount: Int = 0,
        completionRate: Double = 0.0,
        pointsEarned: Int64 = 0,
        lastCalculated: Date = Date(),
        metaData: [String: String]? = nil
    ) {
        self.id = id
        self.dateKey = dateKey
        self.type = type
        self.streakCount = streakCount
        self.completionRate = completionRate
        self.pointsEarned = pointsEarned
        self.lastCalculated = lastCalculated
        self.metaData = metaData
    }
}

/// Decoupled Swift model for migration events.
public struct MigrationRecord: Codable, Identifiable, Hashable {
    public var id: UUID
    public var sourceVersion: Int
    public var targetVersion: Int
    public var appliedAt: Date
    public var status: String
    public var migrationLog: String?
    
    public init(
        id: UUID = UUID(),
        sourceVersion: Int,
        targetVersion: Int,
        appliedAt: Date = Date(),
        status: String,
        migrationLog: String? = nil
    ) {
        self.id = id
        self.sourceVersion = sourceVersion
        self.targetVersion = targetVersion
        self.appliedAt = appliedAt
        self.status = status
        self.migrationLog = migrationLog
    }
}

/// Decoupled Swift model for database backup configuration.
public struct BackupConfig: Codable, Identifiable, Hashable {
    public var id: UUID
    public var backupName: String
    public var lastBackupDate: Date?
    public var backupFrequency: String // "daily", "weekly", "monthly", "manual"
    public var targetDestination: String // "local", "icloud"
    public var maxBackupsCount: Int
    public var isEnabled: Bool
    public var fileSize: Int64
    public var lastStatus: String?
    
    public init(
        id: UUID = UUID(),
        backupName: String,
        lastBackupDate: Date? = nil,
        backupFrequency: String = "weekly",
        targetDestination: String = "local",
        maxBackupsCount: Int = 5,
        isEnabled: Bool = true,
        fileSize: Int64 = 0,
        lastStatus: String? = nil
    ) {
        self.id = id
        self.backupName = backupName
        self.lastBackupDate = lastBackupDate
        self.backupFrequency = backupFrequency
        self.targetDestination = targetDestination
        self.maxBackupsCount = maxBackupsCount
        self.isEnabled = isEnabled
        self.fileSize = fileSize
        self.lastStatus = lastStatus
    }
}

// ==========================================
// MARK: - Core Data Managed Object Classes
// ==========================================

@objc(WorshipLogMO)
public final class WorshipLogMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorshipLogMO> {
        return NSFetchRequest<WorshipLogMO>(entityName: "WorshipLogEntity")
    }
    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var name: String
    @NSManaged public var value: Double
    @NSManaged public var targetValue: Double
    @NSManaged public var timestamp: Date
    @NSManaged public var notes: String?
    @NSManaged public var dateKey: String
    @NSManaged public var isSynced: Bool
    @NSManaged public var extraData: Data?
}

@objc(SettingsMO)
public final class SettingsMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SettingsMO> {
        return NSFetchRequest<SettingsMO>(entityName: "SettingsEntity")
    }
    @NSManaged public var key: String
    @NSManaged public var value: Data?
    @NSManaged public var updatedAt: Date
}

@objc(StatisticsMO)
public final class StatisticsMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StatisticsMO> {
        return NSFetchRequest<StatisticsMO>(entityName: "StatisticsEntity")
    }
    @NSManaged public var id: UUID
    @NSManaged public var dateKey: String
    @NSManaged public var type: String
    @NSManaged public var streakCount: Int32
    @NSManaged public var completionRate: Double
    @NSManaged public var pointsEarned: Int64
    @NSManaged public var lastCalculated: Date
    @NSManaged public var metaData: Data?
}

@objc(MigrationMO)
public final class MigrationMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MigrationMO> {
        return NSFetchRequest<MigrationMO>(entityName: "MigrationRecordEntity")
    }
    @NSManaged public var id: UUID
    @NSManaged public var sourceVersion: Int32
    @NSManaged public var targetVersion: Int32
    @NSManaged public var appliedAt: Date
    @NSManaged public var status: String
    @NSManaged public var migrationLog: String?
}

@objc(BackupConfigMO)
public final class BackupConfigMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BackupConfigMO> {
        return NSFetchRequest<BackupConfigMO>(entityName: "BackupConfigEntity")
    }
    @NSManaged public var id: UUID
    @NSManaged public var backupName: String
    @NSManaged public var lastBackupDate: Date?
    @NSManaged public var backupFrequency: String
    @NSManaged public var targetDestination: String
    @NSManaged public var maxBackupsCount: Int32
    @NSManaged public var isEnabled: Bool
    @NSManaged public var fileSize: Int64
    @NSManaged public var lastStatus: String?
}

// ==========================================
// MARK: - Mappings Extensions
// ==========================================

extension WorshipLog {
    init(from mo: WorshipLogMO) {
        self.id = mo.id
        self.type = mo.type
        self.name = mo.name
        self.value = mo.value
        self.targetValue = mo.targetValue
        self.timestamp = mo.timestamp
        self.notes = mo.notes
        self.dateKey = mo.dateKey
        self.isSynced = mo.isSynced
        
        if let data = mo.extraData,
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            self.extraData = dict
        } else {
            self.extraData = nil
        }
    }
    
    func update(mo: WorshipLogMO) {
        mo.id = self.id
        mo.type = self.type
        mo.name = self.name
        mo.value = self.value
        mo.targetValue = self.targetValue
        mo.timestamp = self.timestamp
        mo.notes = self.notes
        mo.dateKey = self.dateKey
        mo.isSynced = self.isSynced
        
        if let extra = self.extraData,
           let data = try? JSONEncoder().encode(extra) {
            mo.extraData = data
        } else {
            mo.extraData = nil
        }
    }
}

extension SettingItem {
    init(from mo: SettingsMO) {
        self.key = mo.key
        self.value = mo.value
        self.updatedAt = mo.updatedAt
    }
    
    func update(mo: SettingsMO) {
        mo.key = self.key
        mo.value = self.value
        mo.updatedAt = self.updatedAt
    }
}

extension WorshipStats {
    init(from mo: StatisticsMO) {
        self.id = mo.id
        self.dateKey = mo.dateKey
        self.type = mo.type
        self.streakCount = Int(mo.streakCount)
        self.completionRate = mo.completionRate
        self.pointsEarned = mo.pointsEarned
        self.lastCalculated = mo.lastCalculated
        
        if let data = mo.metaData,
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            self.metaData = dict
        } else {
            self.metaData = nil
        }
    }
    
    func update(mo: StatisticsMO) {
        mo.id = self.id
        mo.dateKey = self.dateKey
        mo.type = self.type
        mo.streakCount = Int32(self.streakCount)
        mo.completionRate = self.completionRate
        mo.pointsEarned = self.pointsEarned
        mo.lastCalculated = self.lastCalculated
        
        if let meta = self.metaData,
           let data = try? JSONEncoder().encode(meta) {
            mo.metaData = data
        } else {
            mo.metaData = nil
        }
    }
}

extension MigrationRecord {
    init(from mo: MigrationMO) {
        self.id = mo.id
        self.sourceVersion = Int(mo.sourceVersion)
        self.targetVersion = Int(mo.targetVersion)
        self.appliedAt = mo.appliedAt
        self.status = mo.status
        self.migrationLog = mo.migrationLog
    }
    
    func update(mo: MigrationMO) {
        mo.id = self.id
        mo.sourceVersion = Int32(self.sourceVersion)
        mo.targetVersion = Int32(self.targetVersion)
        mo.appliedAt = self.appliedAt
        mo.status = self.status
        mo.migrationLog = self.migrationLog
    }
}

extension BackupConfig {
    init(from mo: BackupConfigMO) {
        self.id = mo.id
        self.backupName = mo.backupName
        self.lastBackupDate = mo.lastBackupDate
        self.backupFrequency = mo.backupFrequency
        self.targetDestination = mo.targetDestination
        self.maxBackupsCount = Int(mo.maxBackupsCount)
        self.isEnabled = mo.isEnabled
        self.fileSize = mo.fileSize
        self.lastStatus = mo.lastStatus
    }
    
    func update(mo: BackupConfigMO) {
        mo.id = self.id
        mo.backupName = self.backupName
        mo.lastBackupDate = self.lastBackupDate
        mo.backupFrequency = self.backupFrequency
        mo.targetDestination = self.targetDestination
        mo.maxBackupsCount = Int32(self.maxBackupsCount)
        mo.isEnabled = self.isEnabled
        mo.fileSize = self.fileSize
        mo.lastStatus = self.lastStatus
    }
}

// ==========================================
// MARK: - Programmatic Schema Versions
// ==========================================

public enum HasanaSchemaVersion: Int, CaseIterable {
    case v1 = 1
    case v2 = 2
    case v3 = 3
    
    public static var current: HasanaSchemaVersion {
        return .v3
    }
    
    public func model() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        var entities: [NSEntityDescription] = []
        
        switch self {
        case .v1:
            entities.append(createWorshipLogEntityV1())
            entities.append(createSettingsEntityV1())
        case .v2:
            entities.append(createWorshipLogEntityV2())
            entities.append(createSettingsEntityV1())
            entities.append(createStatisticsEntityV2())
            entities.append(createMigrationEntityV2())
        case .v3:
            entities.append(createWorshipLogEntityV3())
            entities.append(createSettingsEntityV1())
            entities.append(createStatisticsEntityV2())
            entities.append(createMigrationEntityV2())
            entities.append(createBackupConfigEntityV3())
        }
        
        model.entities = entities
        return model
    }
    
    // MARK: - Schema Construction Details
    
    private func createWorshipLogEntityV1() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "WorshipLogEntity"
        entity.managedObjectClassName = NSStringFromClass(WorshipLogMO.self)
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let typeAttr = NSAttributeDescription()
        typeAttr.name = "type"
        typeAttr.attributeType = .stringAttributeType
        typeAttr.isOptional = false
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        
        let valueAttr = NSAttributeDescription()
        valueAttr.name = "value"
        valueAttr.attributeType = .doubleAttributeType
        valueAttr.isOptional = false
        valueAttr.defaultValue = NSNumber(value: 0.0)
        
        let targetValueAttr = NSAttributeDescription()
        targetValueAttr.name = "targetValue"
        targetValueAttr.attributeType = .doubleAttributeType
        targetValueAttr.isOptional = false
        targetValueAttr.defaultValue = NSNumber(value: 0.0)
        
        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType
        timestampAttr.isOptional = false
        
        let dateKeyAttr = NSAttributeDescription()
        dateKeyAttr.name = "dateKey"
        dateKeyAttr.attributeType = .stringAttributeType
        dateKeyAttr.isOptional = false
        
        entity.properties = [idAttr, typeAttr, nameAttr, valueAttr, targetValueAttr, timestampAttr, dateKeyAttr]
        entity.uniquenessConstraints = [["id"]]
        
        return entity
    }
    
    private func createWorshipLogEntityV2() -> NSEntityDescription {
        let entity = createWorshipLogEntityV1()
        
        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        notesAttr.isOptional = true
        
        let extraDataAttr = NSAttributeDescription()
        extraDataAttr.name = "extraData"
        extraDataAttr.attributeType = .binaryDataAttributeType
        extraDataAttr.isOptional = true
        
        entity.properties.append(notesAttr)
        entity.properties.append(extraDataAttr)
        
        return entity
    }
    
    private func createWorshipLogEntityV3() -> NSEntityDescription {
        let entity = createWorshipLogEntityV2()
        
        let isSyncedAttr = NSAttributeDescription()
        isSyncedAttr.name = "isSynced"
        isSyncedAttr.attributeType = .booleanAttributeType
        isSyncedAttr.isOptional = false
        isSyncedAttr.defaultValue = NSNumber(value: false)
        
        entity.properties.append(isSyncedAttr)
        
        return entity
    }
    
    private func createSettingsEntityV1() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SettingsEntity"
        entity.managedObjectClassName = NSStringFromClass(SettingsMO.self)
        
        let keyAttr = NSAttributeDescription()
        keyAttr.name = "key"
        keyAttr.attributeType = .stringAttributeType
        keyAttr.isOptional = false
        
        let valueAttr = NSAttributeDescription()
        valueAttr.name = "value"
        valueAttr.attributeType = .binaryDataAttributeType
        valueAttr.isOptional = true
        
        let updatedAtAttr = NSAttributeDescription()
        updatedAtAttr.name = "updatedAt"
        updatedAtAttr.attributeType = .dateAttributeType
        updatedAtAttr.isOptional = false
        
        entity.properties = [keyAttr, valueAttr, updatedAtAttr]
        entity.uniquenessConstraints = [["key"]]
        
        return entity
    }
    
    private func createStatisticsEntityV2() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "StatisticsEntity"
        entity.managedObjectClassName = NSStringFromClass(StatisticsMO.self)
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let dateKeyAttr = NSAttributeDescription()
        dateKeyAttr.name = "dateKey"
        dateKeyAttr.attributeType = .stringAttributeType
        dateKeyAttr.isOptional = false
        
        let typeAttr = NSAttributeDescription()
        typeAttr.name = "type"
        typeAttr.attributeType = .stringAttributeType
        typeAttr.isOptional = false
        
        let streakCountAttr = NSAttributeDescription()
        streakCountAttr.name = "streakCount"
        streakCountAttr.attributeType = .integer32AttributeType
        streakCountAttr.isOptional = false
        streakCountAttr.defaultValue = NSNumber(value: 0)
        
        let completionRateAttr = NSAttributeDescription()
        completionRateAttr.name = "completionRate"
        completionRateAttr.attributeType = .doubleAttributeType
        completionRateAttr.isOptional = false
        completionRateAttr.defaultValue = NSNumber(value: 0.0)
        
        let pointsEarnedAttr = NSAttributeDescription()
        pointsEarnedAttr.name = "pointsEarned"
        pointsEarnedAttr.attributeType = .integer64AttributeType
        pointsEarnedAttr.isOptional = false
        pointsEarnedAttr.defaultValue = NSNumber(value: 0)
        
        let lastCalculatedAttr = NSAttributeDescription()
        lastCalculatedAttr.name = "lastCalculated"
        lastCalculatedAttr.attributeType = .dateAttributeType
        lastCalculatedAttr.isOptional = false
        
        let metaDataAttr = NSAttributeDescription()
        metaDataAttr.name = "metaData"
        metaDataAttr.attributeType = .binaryDataAttributeType
        metaDataAttr.isOptional = true
        
        entity.properties = [idAttr, dateKeyAttr, typeAttr, streakCountAttr, completionRateAttr, pointsEarnedAttr, lastCalculatedAttr, metaDataAttr]
        entity.uniquenessConstraints = [["id"]]
        
        return entity
    }
    
    private func createMigrationEntityV2() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "MigrationRecordEntity"
        entity.managedObjectClassName = NSStringFromClass(MigrationMO.self)
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let sourceVersionAttr = NSAttributeDescription()
        sourceVersionAttr.name = "sourceVersion"
        sourceVersionAttr.attributeType = .integer32AttributeType
        sourceVersionAttr.isOptional = false
        
        let targetVersionAttr = NSAttributeDescription()
        targetVersionAttr.name = "targetVersion"
        targetVersionAttr.attributeType = .integer32AttributeType
        targetVersionAttr.isOptional = false
        
        let appliedAtAttr = NSAttributeDescription()
        appliedAtAttr.name = "appliedAt"
        appliedAtAttr.attributeType = .dateAttributeType
        appliedAtAttr.isOptional = false
        
        let statusAttr = NSAttributeDescription()
        statusAttr.name = "status"
        statusAttr.attributeType = .stringAttributeType
        statusAttr.isOptional = false
        
        let migrationLogAttr = NSAttributeDescription()
        migrationLogAttr.name = "migrationLog"
        migrationLogAttr.attributeType = .stringAttributeType
        migrationLogAttr.isOptional = true
        
        entity.properties = [idAttr, sourceVersionAttr, targetVersionAttr, appliedAtAttr, statusAttr, migrationLogAttr]
        entity.uniquenessConstraints = [["id"]]
        
        return entity
    }
    
    private func createBackupConfigEntityV3() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "BackupConfigEntity"
        entity.managedObjectClassName = NSStringFromClass(BackupConfigMO.self)
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let backupNameAttr = NSAttributeDescription()
        backupNameAttr.name = "backupName"
        backupNameAttr.attributeType = .stringAttributeType
        backupNameAttr.isOptional = false
        
        let lastBackupDateAttr = NSAttributeDescription()
        lastBackupDateAttr.name = "lastBackupDate"
        lastBackupDateAttr.attributeType = .dateAttributeType
        lastBackupDateAttr.isOptional = true
        
        let backupFrequencyAttr = NSAttributeDescription()
        backupFrequencyAttr.name = "backupFrequency"
        backupFrequencyAttr.attributeType = .stringAttributeType
        backupFrequencyAttr.isOptional = false
        
        let targetDestinationAttr = NSAttributeDescription()
        targetDestinationAttr.name = "targetDestination"
        targetDestinationAttr.attributeType = .stringAttributeType
        targetDestinationAttr.isOptional = false
        
        let maxBackupsCountAttr = NSAttributeDescription()
        maxBackupsCountAttr.name = "maxBackupsCount"
        maxBackupsCountAttr.attributeType = .integer32AttributeType
        maxBackupsCountAttr.isOptional = false
        maxBackupsCountAttr.defaultValue = NSNumber(value: 5)
        
        let isEnabledAttr = NSAttributeDescription()
        isEnabledAttr.name = "isEnabled"
        isEnabledAttr.attributeType = .booleanAttributeType
        isEnabledAttr.isOptional = false
        isEnabledAttr.defaultValue = NSNumber(value: true)
        
        let fileSizeAttr = NSAttributeDescription()
        fileSizeAttr.name = "fileSize"
        fileSizeAttr.attributeType = .integer64AttributeType
        fileSizeAttr.isOptional = false
        fileSizeAttr.defaultValue = NSNumber(value: 0)
        
        let lastStatusAttr = NSAttributeDescription()
        lastStatusAttr.name = "lastStatus"
        lastStatusAttr.attributeType = .stringAttributeType
        lastStatusAttr.isOptional = true
        
        entity.properties = [idAttr, backupNameAttr, lastBackupDateAttr, backupFrequencyAttr, targetDestinationAttr, maxBackupsCountAttr, isEnabledAttr, fileSizeAttr, lastStatusAttr]
        entity.uniquenessConstraints = [["id"]]
        
        return entity
    }
}

// ==========================================
// MARK: - Progressive Migration Manager
// ==========================================

public final class HasanaProgressiveMigrator {
    private static var pendingMigrationRecords: [MigrationRecord] = []
    private static let lock = NSLock()
    
    public static func getAndClearPendingRecords() -> [MigrationRecord] {
        lock.lock()
        defer { lock.unlock() }
        let records = pendingMigrationRecords
        pendingMigrationRecords.removeAll()
        return records
    }
    
    public static func migrateStoreIfNeeded(at storeURL: URL) throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return // Fresh database, Core Data will construct current model automatically
        }
        
        guard let currentStoreVersion = detectStoreVersion(at: storeURL) else {
            // Unrecognized schema or corrupted metadata. We will let Core Data handle it or crash safely.
            return
        }
        
        var version = currentStoreVersion
        let targetVersion = HasanaSchemaVersion.current
        
        while version.rawValue < targetVersion.rawValue {
            let nextVersion = HasanaSchemaVersion(rawValue: version.rawValue + 1)!
            print("[HasanaMigrator] Progressive migration running: V\(version.rawValue) -> V\(nextVersion.rawValue)...")
            
            let startTime = Date()
            do {
                try migrateStore(at: storeURL, from: version, to: nextVersion)
                let duration = Date().timeIntervalSince(startTime)
                
                let log = "Successfully completed progressive migration from V\(version.rawValue) to V\(nextVersion.rawValue) in \(String(format: "%.3f", duration)) seconds."
                let record = MigrationRecord(
                    sourceVersion: version.rawValue,
                    targetVersion: nextVersion.rawValue,
                    status: "success",
                    migrationLog: log
                )
                
                lock.lock()
                pendingMigrationRecords.append(record)
                lock.unlock()
            } catch {
                let errorLog = "Failed progressive migration from V\(version.rawValue) to V\(nextVersion.rawValue). Error: \(error.localizedDescription)"
                let record = MigrationRecord(
                    sourceVersion: version.rawValue,
                    targetVersion: nextVersion.rawValue,
                    status: "failed",
                    migrationLog: errorLog
                )
                
                lock.lock()
                pendingMigrationRecords.append(record)
                lock.unlock()
                
                throw HasanaStoreError.migrationFailed(errorLog)
            }
            
            version = nextVersion
        }
    }
    
    private static func detectStoreVersion(at storeURL: URL) -> HasanaSchemaVersion? {
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
            for version in HasanaSchemaVersion.allCases {
                let model = version.model()
                if model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
                    return version
                }
            }
        } catch {
            print("[HasanaMigrator] Could not read store metadata: \(error.localizedDescription)")
        }
        return nil
    }
    
    private static func migrateStore(at storeURL: URL, from sourceVersion: HasanaSchemaVersion, to targetVersion: HasanaSchemaVersion) throws {
        let sourceModel = sourceVersion.model()
        let targetModel = targetVersion.model()
        
        // Attempt to infer mapping model (all structural modifications additions/nullable additions can be inferred)
        let mappingModel = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: targetModel)
        
        let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: targetModel)
        
        // Setup temporary store
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let tempStoreURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("sqlite")
        
        try migrationManager.migrateStore(
            from: storeURL,
            sourceType: NSSQLiteStoreType,
            options: nil,
            with: mappingModel,
            toDestinationURL: tempStoreURL,
            destinationType: NSSQLiteStoreType,
            destinationOptions: nil
        )
        
        // Safely replace the old store with the newly migrated store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: targetModel)
        try coordinator.replacePersistentStore(
            at: storeURL,
            destinationOptions: nil,
            withPersistentStoreFrom: tempStoreURL,
            sourceOptions: nil,
            ofType: NSSQLiteStoreType
        )
        
        // Cleanup temp files
        try? FileManager.default.removeItem(at: tempStoreURL)
        let tempShm = tempStoreURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
        let tempWal = tempStoreURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        try? FileManager.default.removeItem(at: tempShm)
        try? FileManager.default.removeItem(at: tempWal)
    }
}

// ==========================================
// MARK: - Hasana Core Data Store Engine
// ==========================================

public final class HasanaCoreDataStore: @unchecked Sendable {
    public static let shared = HasanaCoreDataStore()
    
    private let container: NSPersistentContainer
    private let queue = DispatchQueue(label: "com.hasana.coredata.dispatch", qos: .userInitiated)
    
    public var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    // Directory mapping for sqlite files
    public static var defaultStoreURL: URL {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let hasanaDirectory = appSupportURL.appendingPathComponent("Hasana", isDirectory: true)
        
        if !fileManager.fileExists(atPath: hasanaDirectory.path) {
            try? fileManager.createDirectory(at: hasanaDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return hasanaDirectory.appendingPathComponent("HasanaStore.sqlite")
    }
    
    internal init(inMemory: Bool = false) {
        let currentModel = HasanaSchemaVersion.current.model()
        self.container = NSPersistentContainer(name: "HasanaStore", managedObjectModel: currentModel)
        
        let description = NSPersistentStoreDescription()
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let storeURL = Self.defaultStoreURL
            
            // Execute progressive migrations if needed prior to loading persistent stores
            do {
                try HasanaProgressiveMigrator.migrateStoreIfNeeded(at: storeURL)
            } catch {
                print("[HasanaCoreDataStore] Critical progressive migration failure: \(error.localizedDescription)")
            }
            description.url = storeURL
        }
        
        // Turn off automatic migration since we manage it completely programmatically
        description.shouldMigrateStoreAutomatically = false
        description.shouldInferMappingModelAutomatically = false
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { desc, error in
            if let error = error {
                fatalError("[HasanaCoreDataStore] Failed loading Core Data container: \(error.localizedDescription)")
            }
        }
        
        // Configure main view context
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Flush any pending migration logs generated during pre-load phase
        flushPendingMigrationLogs()
    }
    
    private func flushPendingMigrationLogs() {
        let pending = HasanaProgressiveMigrator.getAndClearPendingRecords()
        guard !pending.isEmpty else { return }
        
        Task {
            do {
                try await performBackgroundTask { context in
                    for record in pending {
                        let mo = MigrationMO(context: context)
                        record.update(mo: mo)
                    }
                }
                print("[HasanaCoreDataStore] Flushed \(pending.count) progressive migration logs to database.")
            } catch {
                print("[HasanaCoreDataStore] Error flushing migration records: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Thread Safety Helpers
    
    /// Thread-safe execution wrapper using private background context with async/await.
    public func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = newBackgroundContext()
        return try await context.perform {
            let result = try block(context)
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    throw HasanaStoreError.contextSaveFailed(error)
                }
            }
            return result
        }
    }
    
    /// Synchronous block execution helper using performAndWait.
    public func performBackgroundTaskSync<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        let context = newBackgroundContext()
        var result: Result<T, Error>?
        
        context.performAndWait {
            do {
                let value = try block(context)
                if context.hasChanges {
                    try context.save()
                }
                result = .success(value)
            } catch {
                result = .failure(error)
            }
        }
        
        switch result! {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

// ==========================================
// MARK: - Worship Logs CRUD Operations
// ==========================================

extension HasanaCoreDataStore {
    
    /// Saves or updates a worship log record.
    public func saveWorshipLog(_ log: WorshipLog) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = WorshipLogMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", log.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let mo: WorshipLogMO
            if let existing = try context.fetch(fetchRequest).first {
                mo = existing
            } else {
                mo = WorshipLogMO(context: context)
            }
            log.update(mo: mo)
        }
    }
    
    /// Batch saves/updates multiple worship logs efficiently.
    public func saveWorshipLogs(_ logs: [WorshipLog]) async throws {
        try await performBackgroundTask { context in
            for log in logs {
                let fetchRequest = WorshipLogMO.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", log.id as CVarArg)
                fetchRequest.fetchLimit = 1
                
                let mo: WorshipLogMO
                if let existing = try context.fetch(fetchRequest).first {
                    mo = existing
                } else {
                    mo = WorshipLogMO(context: context)
                }
                log.update(mo: mo)
            }
        }
    }
    
    /// Fetches a worship log by its UUID.
    public func fetchWorshipLog(id: UUID) async throws -> WorshipLog? {
        try await performBackgroundTask { context in
            let fetchRequest = WorshipLogMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            guard let result = try context.fetch(fetchRequest).first else { return nil }
            return WorshipLog(from: result)
        }
    }
    
    /// Fetches all logs for a specific YYYY-MM-DD date key.
    public func fetchWorshipLogs(for dateKey: String) async throws -> [WorshipLog] {
        try await performBackgroundTask { context in
            let fetchRequest = WorshipLogMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dateKey == %@", dateKey)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            let results = try context.fetch(fetchRequest)
            return results.map { WorshipLog(from: $0) }
        }
    }
    
    /// Fetches worship logs within a specific closed date range.
    public func fetchWorshipLogs(inRange range: ClosedRange<Date>) async throws -> [WorshipLog] {
        try await performBackgroundTask { context in
            let fetchRequest = WorshipLogMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "timestamp >= %@ AND timestamp <= %@",
                range.lowerBound as CVarArg,
                range.upperBound as CVarArg
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            let results = try context.fetch(fetchRequest)
            return results.map { WorshipLog(from: $0) }
        }
    }
    
    /// Fetches unsynced worship logs (isSynced == false) for cloud operations.
    public func fetchUnsyncedWorshipLogs() async throws -> [WorshipLog] {
        try await performBackgroundTask { context in
            let fetchRequest = WorshipLogMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isSynced == %@", NSNumber(value: false))
            let results = try context.fetch(fetchRequest)
            return results.map { WorshipLog(from: $0) }
        }
    }
    
    /// Deletes a specific worship log.
    public func deleteWorshipLog(id: UUID) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = WorshipLogMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            if let mo = try context.fetch(fetchRequest).first {
                context.delete(mo)
            }
        }
    }
    
    /// Clears logs of a specific type (e.g. "dhikr" or "quran").
    public func deleteWorshipLogs(type: String) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = WorshipLogMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "type == %@", type)
            let results = try context.fetch(fetchRequest)
            for mo in results {
                context.delete(mo)
            }
        }
    }
}

// ==========================================
// MARK: - Settings CRUD Operations
// ==========================================

extension HasanaCoreDataStore {
    
    /// Saves a codable setting value under a string key.
    public func saveSetting<T: Codable>(key: String, value: T) async throws {
        let serializedData = try JSONEncoder().encode(value)
        try await performBackgroundTask { context in
            let fetchRequest = SettingsMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "key == %@", key)
            fetchRequest.fetchLimit = 1
            
            let mo: SettingsMO
            if let existing = try context.fetch(fetchRequest).first {
                mo = existing
            } else {
                mo = SettingsMO(context: context)
                mo.key = key
            }
            mo.value = serializedData
            mo.updatedAt = Date()
        }
    }
    
    /// Fetches and decodes a setting value under a string key.
    public func fetchSetting<T: Codable>(key: String) async throws -> T? {
        try await performBackgroundTask { context in
            let fetchRequest = SettingsMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "key == %@", key)
            fetchRequest.fetchLimit = 1
            
            guard let mo = try context.fetch(fetchRequest).first,
                  let data = mo.value else { return nil }
            
            return try JSONDecoder().decode(T.self, from: data)
        }
    }
    
    /// Removes a setting from local persistence.
    public func deleteSetting(key: String) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = SettingsMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "key == %@", key)
            fetchRequest.fetchLimit = 1
            if let mo = try context.fetch(fetchRequest).first {
                context.delete(mo)
            }
        }
    }
    
    /// Internal helper to pull all settings as Domain structs.
    private func fetchAllSettings() async throws -> [SettingItem] {
        try await performBackgroundTask { context in
            let fetchRequest = SettingsMO.fetchRequest()
            let results = try context.fetch(fetchRequest)
            return results.map { SettingItem(from: $0) }
        }
    }
}

// ==========================================
// MARK: - Statistics CRUD Operations
// ==========================================

extension HasanaCoreDataStore {
    
    /// Persists or updates statistics for a given day/week/month.
    public func saveWorshipStats(_ stats: WorshipStats) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = StatisticsMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", stats.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let mo: StatisticsMO
            if let existing = try context.fetch(fetchRequest).first {
                mo = existing
            } else {
                mo = StatisticsMO(context: context)
            }
            stats.update(mo: mo)
        }
    }
    
    /// Fetches statistics based on key and type.
    public func fetchWorshipStats(for dateKey: String, type: String) async throws -> WorshipStats? {
        try await performBackgroundTask { context in
            let fetchRequest = StatisticsMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dateKey == %@ AND type == %@", dateKey, type)
            fetchRequest.fetchLimit = 1
            guard let result = try context.fetch(fetchRequest).first else { return nil }
            return WorshipStats(from: result)
        }
    }
    
    /// Internal helper to pull all statistics as Domain structs.
    private func fetchAllStatistics() async throws -> [WorshipStats] {
        try await performBackgroundTask { context in
            let fetchRequest = StatisticsMO.fetchRequest()
            let results = try context.fetch(fetchRequest)
            return results.map { WorshipStats(from: $0) }
        }
    }
}

// ==========================================
// MARK: - Migration Record CRUD Operations
// ==========================================

extension HasanaCoreDataStore {
    
    /// Fetches the complete database progressive migration log.
    public func fetchMigrationHistory() async throws -> [MigrationRecord] {
        try await performBackgroundTask { context in
            let fetchRequest = MigrationMO.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "appliedAt", ascending: true)]
            let results = try context.fetch(fetchRequest)
            return results.map { MigrationRecord(from: $0) }
        }
    }
}

// ==========================================
// MARK: - Backup Config CRUD Operations
// ==========================================

extension HasanaCoreDataStore {
    
    /// Saves or updates a backup destination configuration.
    public func saveBackupConfig(_ config: BackupConfig) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = BackupConfigMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", config.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let mo: BackupConfigMO
            if let existing = try context.fetch(fetchRequest).first {
                mo = existing
            } else {
                mo = BackupConfigMO(context: context)
            }
            config.update(mo: mo)
        }
    }
    
    /// Fetches all active backup configurations.
    public func fetchBackupConfigs() async throws -> [BackupConfig] {
        try await performBackgroundTask { context in
            let fetchRequest = BackupConfigMO.fetchRequest()
            let results = try context.fetch(fetchRequest)
            return results.map { BackupConfig(from: $0) }
        }
    }
    
    /// Deletes a backup configuration.
    public func deleteBackupConfig(id: UUID) async throws {
        try await performBackgroundTask { context in
            let fetchRequest = BackupConfigMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            if let mo = try context.fetch(fetchRequest).first {
                context.delete(mo)
            }
        }
    }
    
    /// Internal helper to pull all backup configs as Domain structs.
    private func fetchAllBackupConfigs() async throws -> [BackupConfig] {
        try await performBackgroundTask { context in
            let fetchRequest = BackupConfigMO.fetchRequest()
            let results = try context.fetch(fetchRequest)
            return results.map { BackupConfig(from: $0) }
        }
    }
}

// ==========================================
// MARK: - Advanced Analytics & Queries
// ==========================================

extension HasanaCoreDataStore {
    
    /// Calculates the current streak of consecutive days where the completion target is met.
    /// A completed day is one where the aggregate value matches or exceeds the target.
    ///
    /// - Parameter type: The type of worship activity (e.g. "fard_prayer")
    /// - Parameter endingOn: The day to evaluate backwards from (defaults to today)
    /// - Returns: Number of consecutive days.
    public func calculateStreak(for type: String, endingOn date: Date = Date()) async throws -> Int {
        try await performBackgroundTask { context in
            let fetchRequest = WorshipLogMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "type == %@", type)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            let logs = try context.fetch(fetchRequest)
            
            let calendar = Calendar.current
            var completedDates = Set<String>()
            
            // Group logs by dateKey
            let grouped = Dictionary(grouping: logs) { $0.dateKey }
            
            for (dateKey, dayLogs) in grouped {
                let totalValue = dayLogs.reduce(0.0) { $0 + $1.value }
                let totalTarget = dayLogs.reduce(0.0) { $0 + $1.targetValue }
                
                // Day is complete if we met 80%+ of the target, or if no target is specified, value > 0
                let isTargetMet = totalTarget > 0 ? (totalValue / totalTarget >= 0.8) : (totalValue > 0)
                if isTargetMet {
                    completedDates.insert(dateKey)
                }
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone.current
            
            var streakCount = 0
            var checkDate = calendar.startOfDay(for: date)
            
            // Allow start check on yesterday if today's activity is not yet logged/finished
            let todayKey = dateFormatter.string(from: checkDate)
            if !completedDates.contains(todayKey) {
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                    let yesterdayKey = dateFormatter.string(from: yesterday)
                    if completedDates.contains(yesterdayKey) {
                        checkDate = yesterday
                    } else {
                        return 0
                    }
                } else {
                    return 0
                }
            }
            
            while true {
                let key = dateFormatter.string(from: checkDate)
                if completedDates.contains(key) {
                    streakCount += 1
                    guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prevDate
                } else {
                    break
                }
            }
            
            return streakCount
        }
    }
    
    /// Computes and caches daily completion statistics for dashboard rendering.
    public func calculateAndCacheDailyStats(for date: Date) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        let dateKey = formatter.string(from: date)
        
        try await performBackgroundTask { context in
            // Fetch logs for that specific day
            let fetchRequest = WorshipLogMO.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "dateKey == %@", dateKey)
            let logs = try context.fetch(fetchRequest)
            
            guard !logs.isEmpty else { return }
            
            var totalValue = 0.0
            var totalTarget = 0.0
            var completedCount = 0
            
            for log in logs {
                totalValue += log.value
                totalTarget += log.targetValue
                if log.targetValue > 0 {
                    if log.value >= log.targetValue {
                        completedCount += 1
                    }
                } else if log.value > 0 {
                    completedCount += 1
                }
            }
            
            let completionRate = totalTarget > 0 ? (totalValue / totalTarget) : (Double(completedCount) / Double(logs.count))
            
            // Allocate points (e.g. 15 points per completed practice log, cap at 100)
            let pointsEarned = min(Int64(completedCount * 15), 100)
            
            // Fetch or create StatisticsMO
            let statsFetch = StatisticsMO.fetchRequest()
            statsFetch.predicate = NSPredicate(format: "dateKey == %@ AND type == %@", dateKey, "daily")
            statsFetch.fetchLimit = 1
            
            let mo: StatisticsMO
            if let existing = try context.fetch(statsFetch).first {
                mo = existing
            } else {
                mo = StatisticsMO(context: context)
                mo.id = UUID()
                mo.dateKey = dateKey
                mo.type = "daily"
            }
            
            mo.completionRate = min(completionRate, 1.0)
            mo.pointsEarned = pointsEarned
            mo.lastCalculated = Date()
            
            // Cache individual details inside metadata dictionary
            let metadata = [
                "total_logs": String(logs.count),
                "completed_logs": String(completedCount),
                "total_value": String(format: "%.2f", totalValue),
                "total_target": String(format: "%.2f", totalTarget)
            ]
            if let metaDataBytes = try? JSONEncoder().encode(metadata) {
                mo.metaData = metaDataBytes
            }
        }
    }
}

// ==========================================
// MARK: - Encrypted Backup & Restore Manager
// ==========================================

/// Master payload representation for complete local database backups.
public struct HasanaBackupPayload: Codable {
    public var version: Int
    public var timestamp: Date
    public var worshipLogs: [WorshipLog]
    public var settings: [SettingItem]
    public var statistics: [WorshipStats]
    public var backupConfigs: [BackupConfig]
}

extension HasanaCoreDataStore {
    
    // Core Key derivation via HKDF to convert a user password into a secure 256-bit symmetric key
    private static func deriveSymmetricKey(from password: String) -> SymmetricKey {
        let passwordData = password.data(using: .utf8)!
        let salt = "HasanaSecureBackupDatabaseEncryptionSalt".data(using: .utf8)!
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            outputByteCount: 32
        )
    }
    
    /// Encrypts database payload using AES-GCM encryption.
    public static func encrypt(data: Data, withPassword password: String) throws -> Data {
        let key = deriveSymmetricKey(from: password)
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw HasanaStoreError.encryptionError("SealedBox combined data is nil.")
            }
            return combined
        } catch {
            throw HasanaStoreError.encryptionError(error.localizedDescription)
        }
    }
    
    /// Decrypts database payload using AES-GCM encryption.
    public static func decrypt(encryptedData: Data, withPassword password: String) throws -> Data {
        let key = deriveSymmetricKey(from: password)
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw HasanaStoreError.decryptionError("Invalid password or corrupted backup file: \(error.localizedDescription)")
        }
    }
    
    /// Exports all database records into an encrypted JSON file.
    public func exportBackup(to url: URL, encryptWithPassword password: String? = nil) async throws {
        // Fetch all tables
        let logs = try await fetchAllWorshipLogs()
        let settings = try await fetchAllSettings()
        let statistics = try await fetchAllStatistics()
        let configs = try await fetchAllBackupConfigs()
        
        let payload = HasanaBackupPayload(
            version: HasanaSchemaVersion.current.rawValue,
            timestamp: Date(),
            worshipLogs: logs,
            settings: settings,
            statistics: statistics,
            backupConfigs: configs
        )
        
        var data: Data
        do {
            data = try JSONEncoder().encode(payload)
        } catch {
            throw HasanaStoreError.serializationError(error.localizedDescription)
        }
        
        if let password = password {
            data = try Self.encrypt(data: data, withPassword: password)
        }
        
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw HasanaStoreError.backupFailed(error.localizedDescription)
        }
    }
    
    /// Restores all database records from an encrypted backup file, purging existing database state.
    public func restoreBackup(from url: URL, decryptWithPassword password: String? = nil) async throws {
        var data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw HasanaStoreError.restoreFailed("Unable to read backup file contents: \(error.localizedDescription)")
        }
        
        if let password = password {
            data = try Self.decrypt(encryptedData: data, withPassword: password)
        }
        
        let payload: HasanaBackupPayload
        do {
            payload = try JSONDecoder().decode(HasanaBackupPayload.self, from: data)
        } catch {
            throw HasanaStoreError.serializationError("Failed decoding backup payload: \(error.localizedDescription)")
        }
        
        // Safety validation on schema versions
        guard payload.version <= HasanaSchemaVersion.current.rawValue else {
            throw HasanaStoreError.invalidBackupPayload
        }
        
        // Purge current SQLite tables completely
        try await purgeDatabase()
        
        // Import raw data inside a singular database transaction
        try await performBackgroundTask { context in
            // Import Worship Logs
            for log in payload.worshipLogs {
                let mo = WorshipLogMO(context: context)
                log.update(mo: mo)
            }
            
            // Import Settings
            for setting in payload.settings {
                let mo = SettingsMO(context: context)
                setting.update(mo: mo)
            }
            
            // Import Statistics
            for stat in payload.statistics {
                let mo = StatisticsMO(context: context)
                stat.update(mo: mo)
            }
            
            // Import Backup Configurations
            for config in payload.backupConfigs {
                let mo = BackupConfigMO(context: context)
                config.update(mo: mo)
            }
        }
    }
    
    /// Purges all tables in the database using batch delete requests.
    public func purgeDatabase() async throws {
        try await performBackgroundTask { context in
            let entities = ["WorshipLogEntity", "SettingsEntity", "StatisticsEntity", "MigrationRecordEntity", "BackupConfigEntity"]
            for entityName in entities {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                batchDeleteRequest.resultType = .resultTypeObjectIDs
                
                if let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult,
                   let objectIDs = result.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }
            }
        }
    }
    
    private func fetchAllWorshipLogs() async throws -> [WorshipLog] {
        try await performBackgroundTask { context in
            let fetchRequest = WorshipLogMO.fetchRequest()
            let results = try context.fetch(fetchRequest)
            return results.map { WorshipLog(from: $0) }
        }
    }
}

// ==========================================
// MARK: - SwiftUI & Combine Integration
// ==========================================

public struct HasanaStoreKey: EnvironmentKey {
    public static let defaultValue: HasanaCoreDataStore = .shared
}

extension EnvironmentValues {
    public var hasanaStore: HasanaCoreDataStore {
        get { self[HasanaStoreKey.self] }
        set { self[HasanaStoreKey.self] = newValue }
    }
}

/// Dynamic, observable provider that registers view triggers when saving changes to persistent store context.
@Observable
public final class HasanaPersistenceProvider {
    public var lastSavedDate: Date = Date()
    private var observer: NSObjectProtocol?
    
    public init(store: HasanaCoreDataStore = .shared) {
        observer = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: store.viewContext,
            queue: .main
        ) { [weak self] _ in
            self?.lastSavedDate = Date()
        }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// ==========================================
// MARK: - Mock Seeding & SwiftUI Previews
// ==========================================

extension HasanaCoreDataStore {
    
    /// Pre-configured preview database instance populated with historical worship logs.
    public static var preview: HasanaCoreDataStore {
        let store = HasanaCoreDataStore(inMemory: true)
        store.seedPreviewData()
        return store
    }
    
    /// Seeds 30 days of mock worship logs and statistics.
    private func seedPreviewData() {
        do {
            try performBackgroundTaskSync { context in
                let calendar = Calendar.current
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone.current
                
                // Seed settings
                let prayerSettingsKey = "hasana.prayer.settings"
                let prayerSettingsData = "{\"method\":\"ummAlQura\",\"useHanafiAsr\":false,\"latitude\":21.4225,\"longitude\":39.8262,\"cityName\":\"Makkah\",\"enableAthanNotifications\":true}".data(using: .utf8)!
                
                let settingsMO = SettingsMO(context: context)
                settingsMO.key = prayerSettingsKey
                settingsMO.value = prayerSettingsData
                settingsMO.updatedAt = Date()
                
                // Seed 30 days of logs backwards
                for dayOffset in 0..<30 {
                    guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
                    let dateKey = formatter.string(from: date)
                    
                    // 1. Fard Prayers (5 daily prayers)
                    let prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
                    for prayer in prayers {
                        let log = WorshipLogMO(context: context)
                        log.id = UUID()
                        log.type = "fard_prayer"
                        log.name = prayer
                        // Simulate occasional missed prayer (90% completion rate)
                        let completed = Double.random(in: 0...1) < 0.9
                        log.value = completed ? 1.0 : 0.0
                        log.targetValue = 1.0
                        log.timestamp = calendar.date(bySettingHour: 12 - dayOffset, minute: 0, second: 0, of: date) ?? date
                        log.notes = completed ? "Performed on time in congregation" : "Late due to work"
                        log.dateKey = dateKey
                        log.isSynced = true
                    }
                    
                    // 2. Dhikr Tasbih Logs
                    let dhikrs = ["Subhan Allah", "Alhamdulillah", "Allahu Akbar"]
                    for dhikr in dhikrs {
                        let log = WorshipLogMO(context: context)
                        log.id = UUID()
                        log.type = "dhikr"
                        log.name = dhikr
                        log.value = Double(Int.random(in: 33...100))
                        log.targetValue = 100.0
                        log.timestamp = date
                        log.dateKey = dateKey
                        log.isSynced = true
                    }
                    
                    // 3. Quran Tracker Logs
                    let quranLog = WorshipLogMO(context: context)
                    quranLog.id = UUID()
                    quranLog.type = "quran"
                    quranLog.name = "Read Surah Al-Mulk"
                    quranLog.value = Double(Int.random(in: 2...10))
                    quranLog.targetValue = 5.0
                    quranLog.timestamp = date
                    quranLog.dateKey = dateKey
                    quranLog.isSynced = true
                    
                    // 4. Sadaqah Logs (Occasionally)
                    if dayOffset % 4 == 0 {
                        let sadaqahLog = WorshipLogMO(context: context)
                        sadaqahLog.id = UUID()
                        sadaqahLog.type = "sadaqah"
                        sadaqahLog.name = "Charity Donation"
                        sadaqahLog.value = 25.0
                        sadaqahLog.targetValue = 10.0
                        sadaqahLog.timestamp = date
                        sadaqahLog.notes = "Donated to global local shelter relief fund"
                        sadaqahLog.dateKey = dateKey
                        sadaqahLog.isSynced = true
                    }
                    
                    // 5. Fasting Log (On Mondays/Thursdays)
                    let weekday = calendar.component(.weekday, from: date)
                    if weekday == 2 || weekday == 5 { // 2 = Monday, 5 = Thursday
                        let fastingLog = WorshipLogMO(context: context)
                        fastingLog.id = UUID()
                        fastingLog.type = "fasting"
                        fastingLog.name = "Sunnah Fasting"
                        fastingLog.value = 1.0
                        fastingLog.targetValue = 1.0
                        fastingLog.timestamp = date
                        fastingLog.dateKey = dateKey
                        fastingLog.isSynced = true
                    }
                }
                
                // Seed a backup configuration
                let backupConfig = BackupConfigMO(context: context)
                backupConfig.id = UUID()
                backupConfig.backupName = "Weekly Local Backup Plan"
                backupConfig.backupFrequency = "weekly"
                backupConfig.targetDestination = "local"
                backupConfig.maxBackupsCount = 5
                backupConfig.isEnabled = true
                backupConfig.fileSize = 1048576
                backupConfig.lastBackupDate = Date()
                backupConfig.lastStatus = "Backup completed successfully."
                
                // Seed a historical migration record log
                let migrationRecord = MigrationMO(context: context)
                migrationRecord.id = UUID()
                migrationRecord.sourceVersion = 1
                migrationRecord.targetVersion = 2
                migrationRecord.appliedAt = Date().addingTimeInterval(-86400 * 45) // 45 days ago
                migrationRecord.status = "success"
                migrationRecord.migrationLog = "Lightweight programmatic migration from V1 to V2 applied successfully."
            }
            
            // Recalculate stats caches for preview days
            let calendar = Calendar.current
            for dayOffset in 0..<30 {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                    try performBackgroundTaskSync { context in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        formatter.timeZone = TimeZone.current
                        let dateKey = formatter.string(from: date)
                        
                        // Fetch logs for that specific day
                        let fetchRequest = WorshipLogMO.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "dateKey == %@", dateKey)
                        let logs = try context.fetch(fetchRequest)
                        
                        guard !logs.isEmpty else { return }
                        
                        var totalValue = 0.0
                        var totalTarget = 0.0
                        var completedCount = 0
                        
                        for log in logs {
                            totalValue += log.value
                            totalTarget += log.targetValue
                            if log.targetValue > 0 {
                                if log.value >= log.targetValue { completedCount += 1 }
                            } else if log.value > 0 {
                                completedCount += 1
                            }
                        }
                        
                        let completionRate = totalTarget > 0 ? (totalValue / totalTarget) : (Double(completedCount) / Double(logs.count))
                        let pointsEarned = min(Int64(completedCount * 15), 100)
                        
                        let statsMO = StatisticsMO(context: context)
                        statsMO.id = UUID()
                        statsMO.dateKey = dateKey
                        statsMO.type = "daily"
                        statsMO.completionRate = min(completionRate, 1.0)
                        statsMO.pointsEarned = pointsEarned
                        statsMO.lastCalculated = Date()
                        
                        let metadata = [
                            "total_logs": String(logs.count),
                            "completed_logs": String(completedCount),
                            "total_value": String(format: "%.2f", totalValue),
                            "total_target": String(format: "%.2f", totalTarget)
                        ]
                        if let metaDataBytes = try? JSONEncoder().encode(metadata) {
                            statsMO.metaData = metaDataBytes
                        }
                    }
                }
            }
            
            print("[HasanaCoreDataStore] Successfully seeded database previews with 30 days of rich history.")
        } catch {
            print("[HasanaCoreDataStore] Preview seeding error: \(error.localizedDescription)")
        }
    }
}
