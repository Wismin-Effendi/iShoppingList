//
//  GlobalEnums_and_Struct.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/27/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CloudKit

protocol CloudKitConvertible {
    var identifier: String { get }
    var pendingDeletion: Bool { get set }
    var needsUpload: Bool { get set }
}

struct TimeIntervalConst {
    static let oneDay: Double = 3600.0 * 24.0
    static let twoDays: Double = oneDay * 2.0
    static let threeDays: Double = oneDay * 3.0
    static let fourDays: Double = oneDay * 4.0
    static let oneWeek: Double = oneDay * 7.0
    static let twoWeeks: Double = oneWeek * 2.0
    static let fourWeeks: Double = oneWeek * 4.0
    static let oneMonth: Double = oneDay * 30.0
    static let twentySixMonths: Double = oneMonth * 26.0
}

enum ItemCategory: String {
    case todo = "To-Do"
    case completed = "Completed"
    
    static func byIndex(_ index:Int) -> ItemCategory {
        guard 0...1 ~= index else { return ItemCategory.todo }
        
        let allCategories = [todo, completed]
        return allCategories[index]
    }
}

struct EntityName {
    static let GroceryItem = "GroceryItem"
    static let ShoppingList = "ShoppingList"
}

enum ItemsFilter: String {
    case todo = "To Do"
    case completed = "Completed"
}

struct CoreDataModel {
    static let iShoppingList = "iShoppingList"
}

struct ckShoppingList {
    static let title = "title"
    static let identifier = "identifier"
    static let localUpdate = "localUpdate"
}

struct ckGroceryItem {
    static let title = "title"
    static let identifier = "identifier"
    static let localUpdate = "localUpdate"
    static let reminderDate = "reminderDate"
    static let completed = "completed"
    static let completionDate = "completionDate"
    static let hasReminder = "hasReminder"
    static let isRepeatedItem = "isRepeatedItem"
    static let lastCompletionDate = "lastCompletionDate"
    static let storeName = "storeName"
}

enum CloudKitZone: String {
    case iShoppingListZone
  //  case addMeZone
  //  case deleteMeZone
    
    func recordZoneID() -> CKRecordZoneID {
        return CKRecordZoneID(zoneName: self.rawValue , ownerName: CKCurrentUserDefaultName)
    }
    
    static let allCloudKitZoneNames = [
        CloudKitZone.iShoppingListZone.rawValue,
    //    CloudKitZone.addMeZone.rawValue,
    //    CloudKitZone.deleteMeZone.rawValue
    ]
}

enum RecordType: String {
    case ShoppingList
    case GroceryItem
    case WarehouseGroceryItems
}

struct UserDefaultsKey {
    static let lastSync = "lastSync"
    static let iShoppingListZoneID = "iShoppingListZoneID"
}


enum CloudKitError: Int  {
    case  CKErrorInternalError                  = 1  /* CloudKit.framework encountered an error.  This is a non-recoverable error. */
    case  CKErrorPartialFailure                 = 2  /* Some items failed, but the operation succeeded overall. Check CKPartialErrorsByItemIDKey in the userInfo dictionary for more details. */
    case  CKErrorNetworkUnavailable             = 3  /* Network not available */
    case  CKErrorNetworkFailure                 = 4  /* Network error (available but CFNetwork gave us an error) */
    case  CKErrorBadContainer                   = 5  /* Un-provisioned or unauthorized container. Try provisioning the container before retrying the operation. */
    case  CKErrorServiceUnavailable             = 6  /* Service unavailable */
    case  CKErrorRequestRateLimited             = 7  /* Client is being rate limited */
    case  CKErrorMissingEntitlement             = 8  /* Missing entitlement */
    case  CKErrorNotAuthenticated               = 9  /* Not authenticated (writing without being logged in, no user record) */
    case  CKErrorPermissionFailure              = 10   /* Access failure (save, fetch, or shareAccept) */
    case  CKErrorUnknownItem                    = 11   /* Record does not exist */
    case  CKErrorInvalidArguments               = 12   /* Bad client request (bad record graph, malformed predicate) */
    case  CKErrorResultsTruncated               = 13
    case  CKErrorServerRecordChanged            = 14   /* The record was rejected because the version on the server was different */
    case  CKErrorServerRejectedRequest          = 15   /* The server rejected this request.  This is a non-recoverable error */
    case  CKErrorAssetFileNotFound              = 16   /* Asset file was not found */
    case  CKErrorAssetFileModified              = 17   /* Asset file content was modified while being saved */
    case  CKErrorIncompatibleVersion            = 18   /* App version is less than the minimum allowed version */
    case  CKErrorConstraintViolation            = 19   /* The server rejected the request because there was a conflict with a unique field. */
    case  CKErrorOperationCancelled             = 20   /* A CKOperation was explicitly cancelled */
    case  CKErrorChangeTokenExpired             = 21   /* The previousServerChangeToken value is too old and the client must re-sync from scratch */
    case  CKErrorBatchRequestFailed             = 22   /* One of the items in this batch operation failed in a zone with atomic updates, so the entire batch was rejected. */
    case  CKErrorZoneBusy                       = 23   /* The server is too busy to handle this zone operation. Try the operation again in a few seconds. */
    case  CKErrorBadDatabase                    = 24   /* Operation could not be completed on the given database. Likely caused by attempting to modify zones in the public database. */
    case  CKErrorQuotaExceeded                  = 25   /* Saving a record would exceed quota */
    case  CKErrorZoneNotFound                   = 26   /* The specified zone does not exist on the server */
    case  CKErrorLimitExceeded                  = 27   /* The request to the server was too large. Retry this request as a smaller batch. */
    case  CKErrorUserDeletedZone                = 28   /* The user deleted this zone through the settings UI. Your client should either remove its local data or prompt the user before attempting to re-upload any data to this zone. */
    case  CKErrorTooManyParticipants             = 29  /* A share cannot be saved because there are too many participants attached to the share */
    case  CKErrorAlreadyShared                   = 30  /* A record/share cannot be saved, doing so would cause a hierarchy of records to exist in multiple shares */
    case  CKErrorReferenceViolation              = 31  /* The target of a record's parent or share reference was not found */
    case  CKErrorManagedAccountRestricted        = 32  /* Request was rejected due to a managed account restriction */
    case  CKErrorParticipantMayNeedVerification  = 33  /* Share Metadata cannot be determined, because the user is not a member of the share.  There are invited participants on the share with email addresses or phone numbers not associated with any iCloud account. The user may be able to join the share if they can associate one of those email addresses or phone numbers with their iCloud account via the system Share Accept UI. Call UIApplication's openURL on this share URL to have the user attempt to verify their information. */

    func isRetryCase() -> Bool {
        switch self {
        case .CKErrorZoneBusy, .CKErrorServiceUnavailable, .CKErrorRequestRateLimited:
            return true
        case .CKErrorUserDeletedZone:
            return true   // should be caught by setCustomZonesCompliance, so it's okay to retry
        default: return false
        }
    }
    
    func isFatalError() -> Bool {
        switch self {
        case .CKErrorInternalError, .CKErrorServerRejectedRequest, .CKErrorInvalidArguments, .CKErrorPermissionFailure:
            return true
        default :
            return false
        }
    }
    
    var description: String {
        switch self {
        case   .CKErrorInternalError:  					return  "CKErrorInternalError"
        case   .CKErrorPartialFailure:  				return  "CKErrorPartialFailure"
        case   .CKErrorNetworkUnavailable:  			return  "CKErrorNetworkUnavailable"
        case   .CKErrorNetworkFailure:  				return  "CKErrorNetworkFailure"
        case   .CKErrorBadContainer:  					return  "CKErrorBadContainer"
        case   .CKErrorServiceUnavailable:  			return  "CKErrorServiceUnavailable"
        case   .CKErrorRequestRateLimited:  			return  "CKErrorRequestRateLimited"
        case   .CKErrorMissingEntitlement:  			return  "CKErrorMissingEntitlement"
        case   .CKErrorNotAuthenticated:  			    return  "CKErrorNotAuthenticated"
        case   .CKErrorPermissionFailure:  			    return  "CKErrorPermissionFailure"
        case   .CKErrorUnknownItem:  					return  "CKErrorUnknownItem"
        case   .CKErrorInvalidArguments:  				return  "CKErrorInvalidArguments"
        case   .CKErrorResultsTruncated:  				return  "CKErrorResultsTruncated"
        case   .CKErrorServerRecordChanged:  		    return  "CKErrorServerRecordChanged"
        case   .CKErrorServerRejectedRequest:  		    return  "CKErrorServerRejectedRequest"
        case   .CKErrorAssetFileNotFound:  				return  "CKErrorAssetFileNotFound"
        case   .CKErrorAssetFileModified:  				return  "CKErrorAssetFileModified"
        case   .CKErrorIncompatibleVersion:  			return  "CKErrorIncompatibleVersion"
        case   .CKErrorConstraintViolation:  			return  "CKErrorConstraintViolation"
        case   .CKErrorOperationCancelled:  			return  "CKErrorOperationCancelled"
        case   .CKErrorChangeTokenExpired:  			return  "CKErrorChangeTokenExpired"
        case   .CKErrorBatchRequestFailed:  			return  "CKErrorBatchRequestFailed"
        case   .CKErrorZoneBusy:  					    return  "CKErrorZoneBusy"
        case   .CKErrorBadDatabase:  					return  "CKErrorBadDatabase"
        case   .CKErrorQuotaExceeded:  					return  "CKErrorQuotaExceeded"
        case   .CKErrorZoneNotFound:  					return  "CKErrorZoneNotFound"
        case   .CKErrorLimitExceeded:  					return  "CKErrorLimitExceeded"
        case   .CKErrorUserDeletedZone:  			    return  "CKErrorUserDeletedZone"
        case   .CKErrorTooManyParticipants:  			return  "CKErrorTooManyParticipants"
        case   .CKErrorAlreadyShared:  					return  "CKErrorAlreadyShared"
        case   .CKErrorReferenceViolation:  			return  "CKErrorReferenceViolation"
        case   .CKErrorManagedAccountRestricted:  		return  "CKErrorManagedAccountRestricted"
        case   .CKErrorParticipantMayNeedVerification:  return  "CKErrorParticipantMayNeedVerification"
        }
    }
}





