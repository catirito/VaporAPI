//
//  JuegosController.swift
//  App
//
//  Created by Julio César Fernández Muñoz on 13/01/2019.
//

import Vapor
import FluentSQLite

struct JuegosController:RouteCollection {
    func boot(router: Router) throws {
        let gameRoutes = router.grouped("api", "games")
        gameRoutes.post(JuegosQuery.self, at: "create", use: crearJuego)
        gameRoutes.post(GameQuery.self, at: "query", use:consultaJuego)
        gameRoutes.get("query", use: consultaJuegoGet)
    }
}

func crearJuego(_ req:Request, _ game:JuegosQuery) throws -> Future<JuegosQuery> {
    return Users.query(on: req).filter(\.userID == game.userEmail).first().unwrap(or: Abort(.notFound, reason: "No existe el usuario")).flatMap { usuario in
        let newGame = Juegos(juego: game.juego, puntuacion: game.puntuacion, nivel: game.nivel, userID: usuario.id!)
        return newGame.save(on: req).map { _ in
            return game
        }
    }
}

func consultaJuego(_ req:Request, _ game:GameQuery) throws -> Future<JuegosQuery> {
    return Users.query(on: req).filter(\.userID == game.user).first().unwrap(or: Abort(.notFound, reason: "No existe el usuario \(game.user)")).flatMap { usuario in
        return try usuario.juegos.query(on: req).filter(\.juego == game.juego).first().unwrap(or: Abort(.notFound))
            .map { juego in
                return JuegosQuery(userEmail: usuario.userID, juego: juego.juego, puntuacion: juego.puntuacion, nivel: juego.nivel)
        }
    }
}

func consultaJuegoGet(_ req:Request) throws -> Future<JuegosQuery> {
    guard let user = req.query[String.self, at: "user"], let juego = req.query[String.self, at:"juego"] else {
        throw Abort(.badRequest, reason: "Parámetros incorrectos")
    }
    let consulta = Users.query(on: req).filter(\.userID == user)
    let consultaFiltro = consulta.first().unwrap(or: Abort(.notFound, reason: "No existe el usuario \(user)"))
    return consultaFiltro.flatMap { usuario in
        let consultaJuegos = Juegos.query(on: req)
        let filtroJuegos = consultaJuegos.group(.and) { $0.filter(\.userID == usuario.id!).filter(\.juego == juego) }
        let resultado = filtroJuegos.first().unwrap(or: Abort(.notFound, reason: "No existe el juego \(juego)"))
        return resultado.map { juego in
            let newJQ = JuegosQuery(userEmail: usuario.userID, juego: juego.juego, puntuacion: juego.puntuacion, nivel: juego.nivel)
            return newJQ
        }
    }
}
