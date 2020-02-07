//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public extension TSGroupModel {
    var allPendingMembers: Set<SignalServiceAddress> {
        guard let groupsV2PendingMemberRoles = self.groupsV2PendingMemberRoles else {
            return Set()
        }
        return Set(groupsV2PendingMemberRoles.keys.map {
            SignalServiceAddress(uuid: $0)
        })
    }

    var allPendingAndNonPendingMembers: Set<SignalServiceAddress> {
        return groupMembership.allUsers
    }

    func groupAccessOrDefault() throws -> GroupAccess {
        if let groupAccess = self.groupAccess {
            return groupAccess
        }
        switch groupsVersion {
        case .V1:
            return GroupAccess.forV1
        case .V2:
            throw OWSAssertionError("Missing groupAccess.")
        }
    }
}

// MARK: -

public extension TSGroupModel {
    var groupMembership: GroupMembership {
        switch groupsVersion {
        case .V1:
            return GroupMembership(v1Members: Set(groupMembers))
        case .V2:
            var nonAdminMembers = Set<SignalServiceAddress>()
            var administrators = Set<SignalServiceAddress>()
            for member in groupMembers {
                switch role(forGroupsV2Member: member) {
                case .administrator:
                    administrators.insert(member)
                default:
                    nonAdminMembers.insert(member)
                }
            }

            var pendingNonAdminMembers = Set<SignalServiceAddress>()
            var pendingAdministrators = Set<SignalServiceAddress>()
            for member in allPendingMembers {
                switch self.role(forGroupsV2PendingMember: member) {
                case .administrator:
                    pendingAdministrators.insert(member)
                default:
                    pendingNonAdminMembers.insert(member)
                }
            }

            return GroupMembership(nonAdminMembers: nonAdminMembers,
                                   administrators: administrators,
                                   pendingNonAdminMembers: pendingNonAdminMembers,
                                   pendingAdministrators: pendingAdministrators)
        }
    }
}