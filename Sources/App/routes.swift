import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let usersControllers = UsersController()
    try router.register(collection: usersControllers)
    let juegosControllers = JuegosController()
    try router.register(collection: juegosControllers)
}
