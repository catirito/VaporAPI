//
//  Juegos.swift
//  App
//
//  Created by Julio César Fernández Muñoz on 13/01/2019.
//

import Vapor
import FluentSQLite

final class Juegos {
    var id:UUID?
    var juego:String
    var puntuacion:Double
    var nivel:Int
    var userID:Users.ID
    
    init(juego:String, puntuacion:Double, nivel:Int, userID:Users.ID) {
        self.juego = juego
        self.puntuacion = puntuacion
        self.nivel = nivel
        self.userID = userID
    }
    
    var user:Parent<Juegos, Users> {
        return parent(\.userID)
    }
    
    var developers: Siblings<Juegos, Developers, JuegosDevelopersPivot> {
        return siblings()
    }
}

extension Juegos:SQLiteUUIDModel {}
extension Juegos:Content {}
extension Juegos:Migration {}
extension Juegos:Parameter {}

struct JuegosQuery:Content {
    let userEmail:String
    let juego:String
    let puntuacion:Double
    let nivel:Int
}

struct GameQuery:Content {
    let user:String
    let juego:String
}
