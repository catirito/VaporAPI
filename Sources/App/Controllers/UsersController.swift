//
//  UsersController.swift
//  App
//
//  Created by Julio César Fernández Muñoz on 12/01/2019.
//

import Vapor
import FluentSQLite
import Random
import Authentication
import Crypto

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let userRoutes = router.grouped("api", "users")
        userRoutes.post(Users.self, use: createUser)
        
        let basicAuthMiddleware = Users.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = userRoutes.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: login)
        
        let userAuthRouters = router.grouped("api","app")
        let tokenAuthMiddleware = Users.tokenAuthMiddleware()
        let tokenAuthGroup = userAuthRouters.grouped(tokenAuthMiddleware)
        
        tokenAuthGroup.get("queryAll", use: queryAllUsers)
        tokenAuthGroup.get(Users.parameter, "queryOne", use:queryOne)
        tokenAuthGroup.post(UsersQuery.self, at: "query", use: queryUserID)
        tokenAuthGroup.get("queryGet", use: queryUserIDGet)
        tokenAuthGroup.put(Users.parameter, use: updateUserID)
        tokenAuthGroup.put(UsersUpdate.self, at: "updateUser", use: updateUserName)
        tokenAuthGroup.delete(Users.parameter, use: deleteUserName)
    }
}

func createUser(_ req:Request, _ user:Users) throws -> Future<HTTPStatus> {
    return Users.query(on: req).filter(\.userID == user.userID).first().flatMap { existingUser in
        guard existingUser == nil else {
            throw Abort(.badRequest)
        }
        let digest = try req.make(BCryptDigest.self)
        let hashedPassword = try digest.hash(user.passwd)
        //let newUser = Users(userID: user.userID, name: user.name, passwd: hashedPassword, city: user.city, country: user.country)
        user.passwd = hashedPassword
        
        return user.save(on: req).transform(to: .created)
    }
}

func login(_ req:Request) throws ->Future<TokenResponse> {
    let user = try req.requireAuthenticated(Users.self)
    let token = try Token.generate(for: user)
    return token.save(on: req).map { tokenInfo in
        return TokenResponse(token: tokenInfo.token)
    }
}

func queryAllUsers(_ req:Request) throws -> Future<[Users]> {
    let _ = try req.requireAuthenticated(Users.self)
    return Users.query(on: req).all()
}

func queryOne(_ req:Request) throws -> Future<Users> {
    return try req.parameters.next(Users.self)
}

func queryUserID(_ req:Request, _ query:UsersQuery) throws -> Future<Users> {
    return Users.query(on: req).filter(\.userID == query.userID).first().unwrap(or: Abort(.notFound, reason: "Username not exists"))
}

func queryUserIDGet(_ req:Request) throws -> Future<Users> {
    guard let parametro = req.query[String.self, at:"userID"] else {
        throw Abort(.badRequest, reason: "No existe el parámetro UserID")
    }
    return Users.query(on: req).filter(\.userID == parametro).first().unwrap(or: Abort(.notFound, reason: "Username not exists"))
}

func updateUserID(_ req:Request) throws -> Future<HTTPStatus> {
    return try flatMap(req.parameters.next(Users.self), req.content.decode(Users.self)) {
        (user, newUser) in
        user.userID = newUser.userID
        user.name = newUser.name
        return user.update(on: req).transform(to: .ok)
    }
}

func updateUserName(_ req:Request,_ update:UsersUpdate) throws -> Future<Users> {
    return Users.query(on: req).filter(\.userID == update.username).first().unwrap(or: Abort(.notFound, reason:"No existe el username")).flatMap {
        $0.userID = update.newUsername
        return $0.update(on: req)
    }
}

func deleteUserName(_ req:Request) throws -> Future<HTTPStatus> {
    return try req.parameters.next(Users.self).flatMap {
        return $0.delete(on: req).transform(to: .noContent)
    }
}
