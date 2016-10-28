//
//  ServerTrustPolicy.swift
//  ALmo
//
//  Created by zhangyun on 28/10/2016.
//  Copyright © 2016 zhangyun. All rights reserved.
//

import Foundation


/// responsible for managing the mapping of `ServerTrustPolicy` objects to a given host.
open class ServerTrustPolicyMgr {
    
    open let policies: [String: serverp]
    
}


/// the `ServerTrustPolicy` evaluates the server trust generally provided by an `NSURLAuthenticationChallenge` when 
/// connnectiong to a server over a secure HTTPS connection.The policy configuration then evaluateds the server 
/// trust with a given set of criteria to determine whether the server trust is valid and the connection should be 
/// made.
///
/// - performDefaultEvaluation: <#performDefaultEvaluation description#>
/// - pinCertificates:          <#pinCertificates description#>
/// - pinPublicKeys:            <#pinPublicKeys description#>
/// - disableEvaluation:        <#disableEvaluation description#>
/// - customEvaluation->Bool:   <#customEvaluation->Bool description#>
public enum ServerTrustPolicy{
    case performDefaultEvaluation(validateHost:Bool)
    case pinCertificates(certificates:[SecCertificate],validateCertigicateChain: Bool,validateHost:Bool)
    case pinPublicKeys(publicKeys:[SecKey],validateCertificateChain:Bool,validateHost:Bool)
    case disableEvaluation
    case customEvaluation((_ serverTrust:SecTrust,_ host: String) ->Bool)
    
}
