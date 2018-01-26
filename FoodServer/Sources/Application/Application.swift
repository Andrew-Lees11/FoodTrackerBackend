import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import KituraStencil

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()
    private var mealStore: [String: Meal] = [:]
    private var fileManager = FileManager.default
    private var rootPath = StaticFileServer().absoluteRootPath
    
    public init() throws {
    }
    
    func postInit() throws {
        // Capabilities
        initializeMetrics(app: self)
        
        // Endpoints
        initializeHealthRoutes(app: self)
        
        router.post("/foodtracker", middleware: BodyParser())
        router.post("/meals", handler: storeHandler)
        router.get("/meals", handler: loadHandler)
        router.add(templateEngine: StencilTemplateEngine())
        router.get("/images", middleware: StaticFileServer())
        
        router.get("/foodtracker") { request, response, next in
            let meals: [Meal] = self.mealStore.map({ $0.value })
            var allMeals : [String: [[String:Any]]] = ["meals" : []]
            for meal in meals {
                allMeals["meals"]?.append(["name": meal.name, "rating": meal.rating])
            }
            try response.render("Example.stencil", context: allMeals).end()
            next()
        }
        
        router.post("/foodtracker") { request, response, next in
            try response.redirect("/foodtracker")
            guard let parsedBody = request.body else {
                next()
                return
            }
            let parts = parsedBody.asMultiPart
            guard let name = parts?[0].body.asText,
                let stringRating = parts?[1].body.asText,
                let rating = Int(stringRating),
                case .raw(let photo)? = parts?[2].body,
                parts?[2].type == "image/jpeg"
                else {
                    next()
                    return
            }
            guard let newMeal = Meal(name: name, photo: photo, rating: rating) else {return}
            self.mealStore[newMeal.name] = newMeal
            let path = "\(self.rootPath)/\(newMeal.name).jpg"
            self.fileManager.createFile(atPath: path, contents: newMeal.photo)
            next()
        }
    }
    
    func storeHandler(meal: Meal, completion: (Meal?, RequestError?) -> Void ) {
        mealStore[meal.name] = meal
        let path = "\(self.rootPath)/\(meal.name).jpg"
        fileManager.createFile(atPath: path, contents: meal.photo)
        completion(mealStore[meal.name], nil)
    }
    
    func loadHandler(completion: ([Meal]?, RequestError?) -> Void ) {
        let meals: [Meal] = self.mealStore.map({ $0.value })
        completion(meals, nil)
    }
    
    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
