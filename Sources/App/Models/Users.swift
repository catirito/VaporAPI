//
//  Users.swift
//  App
//
//  Created by Julio César Fernández Muñoz on 12/01/2019.
//

import Vapor
import FluentSQLite
import Authentication
import Random

final class Users: Codable {
    var id:UUID?
    var userID:String
    var passwd:String
    var name:String
    var city:String
    var country:String
    
    init(userID:String, name:String, passwd:String, city:String, country:String) {
        self.userID = userID
        self.passwd = passwd
        self.name = name
        self.city = city
        self.country = country
    }
    
    var juegos:Children<Users, Juegos> {
        return children(\.userID)
    }
    
}

extension Users: SQLiteUUIDModel {}
extension Users: Content {}
extension Users: Migration {}
extension Users: Parameter {}

extension Users: TokenAuthenticatable {
    typealias TokenType = Token
}
extension Users: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \Users.userID
    static let passwordKey: PasswordKey = \Users.passwd
}


final class Token: Codable {
    var id: UUID?
    var token: String
    var userID: Users.ID
    
    init(token:String, userID:Users.ID) {
        self.token = token
        self.userID = userID
    }
    
    var user: Parent<Token,Users> {
        return parent(\.userID)
    }
    
    static func generate(for user:Users) throws -> Token {
        let random = OSRandom().generateData(count: 32)
        return try Token(token: random.base64EncodedString(), userID: user.requireID())
    }
    

}

extension Token: SQLiteUUIDModel {}
extension Token: Content {}
extension Token: Migration {}

extension Token: Authentication.Token {
    static let userIDKey:UserIDKey = \Token.userID
    typealias UserType = Users
    typealias UserIDType = Users.ID
}

extension Token: BearerAuthenticatable {
    static let tokenKey: TokenKey = \Token.token
}


struct UsersAddFieldPassword:SQLiteMigration, SQLiteModel {
    var id:Int?
    static func prepare(on conn: SQLiteConnection) -> EventLoopFuture<Void> {
        return SQLiteDatabase.update(Users.self, on: conn) { builder in
            builder.field(for: \.passwd, type: SQLiteDataType.text, .default(.literal("NO")))
            
        }
    }
    
    static func revert(on conn: SQLiteConnection) -> EventLoopFuture<Void> {
        return SQLiteDatabase.update(Users.self, on: conn) { builder in
            builder.deleteField(for: \.passwd)
            
        }
    }
}

struct UsersQuery:Content {
    let userID:String
}

struct UsersUpdate:Content {
    let username:String
    let newUsername:String
}


struct TokenResponse:Content {
    let token:String
}
