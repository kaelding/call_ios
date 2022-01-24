//
//  Request.swift
//  ZEGOLiveDemo
//
//  Created by Larry on 2021/12/27.
//

import UIKit

enum HTTPMethod: String {
    case GET
    case POST
}

protocol Request {
    var path: String { get }
    var method: HTTPMethod { get }
    associatedtype Response: Decodable
    var parameter: [String: AnyObject] { get }
}

extension Request {
    var header: [String: String]{
        return ["Accept": "application/json"];
    }
}

protocol RequestSender {
    var host: String { get }
    func send<T: Request>(_ r: T, handler: @escaping (T.Response?) -> Void)
} 

extension RequestSender {
    var host: String {
        return "http://192.168.100.44:3128"
    }
}

protocol Decodable {
    static func parse(_ json: Dictionary<String, Any>) -> Self?
}
