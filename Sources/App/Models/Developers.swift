//
//  Developers.swift
//  App
//
//  Created by Bruno Del Greco on 13/01/2019.
//

import Vapor
import FluentSQLite

final class Developers:Codable {
    var id:UUID?
    var name:String
    var country:String
    
    init(name:String, country:String) {
        self.name = name
        self.country = country
    }
    
    var games: Siblings<Developers, Juegos, JuegosDevelopersPivot> {
        return siblings()
    }
}



extension Developers:SQLiteUUIDModel {}
extension Developers:Content {}
extension Developers:Migration {}
extension Developers:Parameter {}


final class JuegosDevelopersPivot: SQLiteUUIDPivot {
    var id: UUID?
    var gameID: Juegos.ID
    var devID: Developers.ID
    
    typealias Left = Juegos
    typealias Right = Developers
    
    static let leftIDKey: LeftIDKey = \.gameID
    static let rightIDKey: RightIDKey = \.devID
    
    init(_ userID: Developers.ID, _ gameID: Juegos.ID){
        self.devID = userID
        self.gameID = gameID
    }
}

extension JuegosDevelopersPivot:Migration {}
