//
//  FirebaseTool.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/30.
//

import Foundation
import Firebase
import FirebaseCore
import FirebaseAuth

protocol LoginManagerDelegate: AnyObject {
    func onReceiveUserKickout()
}

class LoginManager {
    
    typealias loginCallback = (_ userID: String?, _ userName: String?, _ error: Int) -> Void
    
    static let shared = LoginManager()
    
    private var ref: DatabaseReference
    private var fcmToken: String?
    
    init() {
//        Database.database().isPersistenceEnabled = true
        ref = Database.database().reference()
        
        addConnectedListener()
    }
    
    private var _user: User? {
        willSet {
            if newValue?.uid != _user?.uid && newValue != nil {
                UserListManager.shared.addOnlineUsersListener()
                addUserToDatabase(newValue!)
            } else if newValue == nil {
                UserListManager.shared.removeOnlineUsersListener()
            }
        }
    }
    var user: User? {
        get {
            _user = Auth.auth().currentUser
            return _user
        }
    }
    
    weak var delegate: LoginManagerDelegate?
    
    func login(_ token: String, callback: @escaping loginCallback) {
        
        let credential = GoogleAuthProvider.credential(withIDToken: token,
                                                       accessToken: "")
        Auth.auth().signIn(with: credential) { result, error in
            
            guard let user = result?.user else {
                callback(nil, nil, 1)
                return
            }
            self._user = user
            callback(user.uid, user.displayName, 0)
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        resetData()
    }
}

extension LoginManager {
    
    private func resetData(_ removeUserData: Bool = true) {
        if let uid = user?.uid {
            let tokenRef = self.ref.child("online_user").child(uid).child("token_id")
            tokenRef.removeAllObservers()
            
            let userRef = self.ref.child("online_user").child(uid)
            userRef.cancelDisconnectOperations()
            if removeUserData {
                userRef.removeValue()
            }
        }
        _user = nil
    }
    
    private func addConnectedListener() {
        ref.child(".info/connected").observe(.value) { snapshot in
            guard let connected = snapshot.value as? Bool, connected else { return }
            guard let user = self.user else { return }
            self.addUserToDatabase(user)
        }
    }
    
    private func addUserToDatabase(_ user: User) {
        
        func addUser(_ user: User, token: String?) {
            // setup database
            let data: [String : Any?] = [
                "user_id" : user.uid,
                "display_name" : user.displayName,
                "token_id" : fcmToken,
                "last_changed" : Int(Date().timeIntervalSince1970 * 1000)
            ]
            let userRef = self.ref.child("online_user").child(user.uid)
            userRef.setValue(data)
            userRef.onDisconnectRemoveValue()
        }
        
        if fcmToken == nil {
            Messaging.messaging().token { token, error in
                guard let token = token else { return }
                self.fcmToken = token
                addUser(user, token: self.fcmToken)
                self.addFcmTokenListener()
            }
        } else {
            addUser(user, token: self.fcmToken)
        }
    }
    
    private func addFcmTokenListener() {
        guard let uid = user?.uid else { return }
        let tokenRef = self.ref.child("online_user").child(uid).child("token_id")
        tokenRef.observe(.value) { snapshot in
            guard let token = snapshot.value as? String else { return }
            if token == self.fcmToken { return }
            print("[*] Current User is logging at other device.")
            
            try? Auth.auth().signOut()
            self.resetData(false)
            CallManager.shared.resetCallData()
            self.delegate?.onReceiveUserKickout()
        }
    }
}
