# Adding a Website Frontend to Kitura FoodServer with Stencil

<p align="center">
<img src="https://www.ibm.com/cloud-computing/bluemix/sites/default/files/assets/page/catalog-swift.svg" width="120" alt="Kitura Bird">
</p>

<p align="center">
<a href= "http://swift-at-ibm-slack.mybluemix.net/">
<img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg"  alt="Slack">
</a>
</p>

Now that there is a FoodServer as a backend for the [FoodTracker](https://github.com/IBM/FoodTrackerBackend) app, you can add a website frontend so that the page displayed by your server is more visually appealing than a JSON array of the meals. The steps below demonstrate how to make your server use a Stencil template to return dynamic html, using [Kitura-TemplateEngine](https://github.com/IBM-Swift/Kitura-TemplateEngine) and [Kitura-StencilTemplateEngine](https://github.com/IBM-Swift/Kitura-StencilTemplateEngine).


## Pre-Requisites:
These instructions follow on from the FoodTracker application and server created by following the [FoodTrackerBackend](https://github.com/IBM/FoodTrackerBackend) tutorial. If you have completed the FoodTracker Backend there are no further pre-requisites.

If you have not completed the [FoodTrackerBackend](https://github.com/IBM/FoodTrackerBackend) tutorial go to the [CompletedFoodTracker](https://github.com/IBM/FoodTrackerBackend/tree/CompletedFoodTracker) branch and follow the README instructions.

## Using A Stencil Template
The Food Tracker application is taken from the Apple tutorial for building your first iOS application. In [FoodTrackerBackend Tutorial](https://github.com/IBM/FoodTrackerBackend), we created a server and connected it to the iOS application. This means created meals are posted to the server and a user can then view these meals on [localhost:8080/meals](http://localhost:8080/meals). When you perform a HTTP GET request to the server, you are returned a JSON array with all your stored meals. To present this data in a more appealing way we will use [Stencil](https://github.com/kylef/Stencil). Stencil is a template language for Swift which allows you to embed code into a html document for a dynamic webpage.

### Create the Stencil File
To use templates with a Kitura router, you must create a .stencil template file which describes how to embed code into the returned html. By default, Kitura Router gets the template files from the `./Views/` directory in the directory where Kitura runs. You can change the Views directory per Router instance by setting the `Router.viewsPath` variable, but for our tutorial we use the default `Views` folder.

1. In terminal, move to the FoodServer directory:
```
cd ~/FoodTrackerBackend/FoodServer
```
2. Create and move into the Views folder.
```
mkdir Views
cd Views
```
3. Create a FoodTemplate.stencil file.

We will use terminal commands for file creation but you can use a text editor of your choice.
```
cat > FoodTemplate.stencil
```
**Note:** You can exit cat using `CTRL+D`

4. Add the following Stencil code for displaying meals:
```
<html>
There are {{ meals.count }} meals. <br />

{% for meal in meals %}
    - {{ meal.name }} with rating {{ meal.rating }}. <br />
    <br />
{% endfor %}
</html>
```
When, the above code is rendered it will display the number of meals in your meal store and then loop through the mealstore, displaying the meal name and rating. Stencil will work with html tags such as <br /> for a line break. For more details about Stencil templates see the [Stencil User Guide](http://stencil.fuller.li/en/latest/).


### Add Kitura-StencilTemplateEngine dependencies to your server
[Kitura-TemplateEngine](https://github.com/IBM-Swift/Kitura-TemplateEngine) is a template engine abstraction layer, that works alongside a specific template engine, such as [Kitura-StencilTemplateEngine](https://github.com/IBM-Swift/Kitura-StencilTemplateEngine), to allow a user to easily use a template engine in swift. These two libraries are added to our `Package.swift` file, so the server can access them.

1. In terminal, go to your servers `Package.swift` file.
```
cd ~/FoodTrackerBackend/FoodServer
open Package.swift
```
2. Add the Kitura-StencilTemplateEngine package.
```swift
.package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", from: "1.8.0")
```
3. Change the target for Application to include Kitura-StencilTemplateEngine.
```swift
.target(name: "Application", dependencies: [ "Kitura", "Configuration", "CloudEnvironment", "SwiftMetrics", "Health", "KituraStencil"]),
```
### Generate your FoodServer Xcode project
Now we have added the dependencies to our `Package.swift` file we can generate our FoodServer Xcode project to make editing the code easier. The FoodServer is a pure Swift project and so the following steps could also be achieved by editing the .swift files.

1. Generate the server Xcode project:
```
swift package generate-xcodeproj
open FoodServer.xcodeproj/
```
2. Click on the "FoodServer-Package" text on the top-left of the toolbar and select "Edit scheme" from the dropdown menu.
3. In "Run" click on the "Executable" dropdown, select FoodServer and click Close.

Now when you press play, Xcode will start your FoodTracker server listening on port 8080. You can see this by going to [http://localhost:8080/](http://localhost:8080/ ) which will show the default Kitura landing page.

### Add the Stencil template engine
1. Open your `Sources > Application > Application.swift` file
2. Add KituraStencil to the import statements:
```swift
import KituraStencil
```
3. Add the template engine to the router.

Inside the `postInit()` function, insert the following line, below `router.get("/meals", handler: loadHandler)`:
```swift
router.add(templateEngine: StencilTemplateEngine())
```

The router will now use a `StencilTemplateEngine()` for rendering templates. you can use multiple template engines in one file and `router.setDefault(templateEngine: StencilTemplateEngine())` can be used to set the default.

### Adding a route for the template
We will define a new route for our server which we will use to return the formatted html. This is done using Kitura 1 style routing with request, response and next. We will render the .stencil file and add this to the response.

1. Add a Kitura 1 style GET route for "/foodtracker".

Add the following code beneath `router.add(templateEngine: StencilTemplateEngine())`:
```swift
router.get("/foodtracker") { request, response, next in
    next()
}
```
2. Build a JSON string description of the FoodTracker mealstore.

Add the following code inside your “/foodtracker" route above `next()`:
```swift
let meals: [Meal] = self.mealStore.map({ $0.value })
var allMeals : [String: [[String:Any]]] = ["meals" : []]
for meal in meals {
    allMeals["meals"]?.append(["name": meal.name, "rating": meal.rating])
}
```
3. Render the template and add it to your response.

Add the following line above `next()`:
```swift
try response.render("FoodTemplate.stencil", context: allMeals).end()
```
This will render the `FoodTemplate.stencil` file using "allMeals" to embed variables from the code.

4. Your completed `foodtracker` route should now look as follows:
```swift
router.get("/foodtracker") { request, response, next in
    let meals: [Meal] = self.mealStore.map({ $0.value })
    var allMeals : [String: [[String:Any]]] = ["meals" : []]
    for meal in meals {
        allMeals["meals"]?.append(["name": meal.name, "rating": meal.rating])
    }
    try response.render("FoodTemplate.stencil", context: allMeals).end()
    next()
}
```
We can test this route by running the FoodTracker application and the FoodServer. Add a meal in the app and then go to [http://localhost:8080/foodtracker](http://localhost:8080/foodtracker). This will now display a line saying how many meals are present in the app and a list of the meal names and ratings.

## Displaying a Photo using a Static File Server
Our meal tracker application allows users to upload a photograph of their meal. We would like to add this photograph to our webpage as a picture and not as a string of data as it is currently displayed. We will save user photos and then implement a Static File Server which will serve the photos using the Stencil template.

### Saving photos on the server
1. Using terminal, create the "public" directory.
```
cd ~/FoodTrackerBackend/FoodServer
mkdir public
```
The default location for a static file server is the ./public directory so we will create one in our server as the location for saving our users' pictures.

2. Open your `Sources > Application > Application.swift` file.
3. Setup the file handler to write to the web hosting directory by adding the following under the `mealStore` declaration:
```swift
private var fileManager = FileManager.default
private var rootPath = StaticFileServer().absoluteRootPath
```
4. Save pictures received by the server.

Add the following code to your `storehandler` function beneath `mealStore[meal.name] = meal`:
```swift
let path = "\(self.rootPath)/\(meal.name).jpg"
fileManager.createFile(atPath: path, contents: meal.photo)
```
This will create a file with the name of your meal and a .jpg extension inside the public directory of your server. If the file already exists it will overwrite it with a new picture. You can test this by re-running the FoodServer with your changes and adding a meal - the photo should appear in the "public" directory you just created.

4. your storehandler should now look as follows:
```swift
func storeHandler(meal: Meal, completion: (Meal?, RequestError?) -> Void ) {
    mealStore[meal.name] = meal
    let path = "\(self.rootPath)/\(meal.name).jpg"
    fileManager.createFile(atPath: path, contents: meal.photo)
    completion(mealStore[meal.name], nil)
}
```
### Adding the photos to the Stencil template
1. Add a static file server route for images.

Insert the following line below `router.get("/meals", handler: loadHandler)`:
```swift
router.get("/images", middleware: StaticFileServer())
```
2. Open your "FoodTemplate.stencil" file:
```
cd ~/FoodTrackerBackend/FoodServer/Views
open FoodTemplate.stencil
```
3. Add the following line in your `for` loop below the line  `- {{ meal.name }} with rating {{ meal.rating }}. <br />`
```
<img src="images/{{ meal.name }}.jpg" alt="meal image" height="100"> <br />
```
This will make a call to the server for the image saved with the meal and display it.

Restart your server to add your new changes. Then add a new meal and view your frontend mealstore at [http://localhost:8080/foodtracker](http://localhost:8080/foodtracker). You should see a webpage displaying the total number of meals and a list of the meal names, rating and as well as a picture of the meal.
Congratulations! You have now taken a meal from the app, set up a Kitura server to receive the data and displayed it embedded in html to a webpage.

## Submitting a Meal from the Webpage
The user wants to be able to submit meals from the webpage as well as the app. We will use a html form to post data to the Kitura server. Then using body parser we will parse the received data to add a meal to our mealstore and display the new meal.

### Adding a Form to the Webpage

1. In terminal, move to the `Views` directory:
```
cd ~/FoodTrackerBackend/FoodServer/Views
```
2. Open your `FoodTemplate.stencil` file:
```
open FoodTemplate.stencil
```
3. Add the following code below `{% endfor %}`:
```
<form action="foodtracker" method="post" enctype="multipart/form-data">
    Name: <input type="text" name="name"><br>
    Rating: <input type="range" name="rating" min="0" max="5"><br>
    File: <input type="file" name="photo"><br>
    <input type="submit" value="Submit">
</form>
```
4. Refresh your [http://localhost:8080/foodtracker](http://localhost:8080/foodtracker) to view the form.

This code creates a multipart from with three fields. A "name" text box, a rating slider and a file submission button. When you click submit, this will POST a multipart form to "/foodtracker" with the data from the form.


### Using Bodyparser on the POST route of `"/foodtracker"`

1. Open FoodServer  `Sources > Application > Application.swift` file.
2. Connect `BodyParser` Middleware.

inside the `postInit()` function add BodyParser to your route:
```swift
router.post("/foodtracker", middleware: BodyParser())
```
3. Add a Kitura 1 style POST route for "/foodtracker".

Add the following code beneath your BodyParser route:
```swift
router.post("/foodtracker") { request, response, next in
    next()
}
```
4. Parse the `Request` body with BodyParser.

Add the following code inside your “/foodtracker" post route above `next()`:
```swift
guard let parsedBody = request.body else {
    next()
    return
}
```
5. Split the ParsedBody into a MultiPart array.

Add the following line after the guard statement:
```swift
let parts = parsedBody.asMultiPart
```

### Save the MultiPart array as a meal object

1. Parse the MultiPart array as a meal object.

Insert the following code beneath your `parts` declaration:
```swift
guard let name = parts?[0].body.asText,
    let stringRating = parts?[1].body.asText,
    let rating = Int(stringRating),
    case .raw(let photo)? = parts?[2].body,
    parts?[2].type == "image/jpeg",
    let newMeal = Meal(name: name, photo: photo, rating: rating)
else {
    next()
    return
}
```
2. Save the meal and the photo.

Insert the following code after the second else block:
```swift
self.mealStore[newMeal.name] = newMeal
let path = "\(self.rootPath)/\(newMeal.name).jpg"
self.fileManager.createFile(atPath: path, contents: newMeal.photo)
```
For simplicity we are only accepting jpg files from the webpage.

3. Redirect the user to the GET "/foodtracker" route.

Add the following line below the Route declaration:
```swift
try response.redirect("/foodtracker")
```
This will reload the page and prevent meals being submitted multiple times.

4. Your completed `foodtracker` POST route should now look as follows:
```swift
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
        parts?[2].type == "image/jpeg",
        let newMeal = Meal(name: name, photo: photo, rating: rating)
    else {
        next()
        return
    }
    self.mealStore[newMeal.name] = newMeal
    let path = "\(self.rootPath)/\(newMeal.name).jpg"
    self.fileManager.createFile(atPath: path, contents: newMeal.photo)
    next()
}
```

Restart your server to add your new changes. Then add a new meal from at [http://localhost:8080/foodtracker](http://localhost:8080/foodtracker). You should see a webpage update with your new meal and a list of the meal names, rating and as well as a picture of the meal.

## Adding HTML and CSS

You now have everything needed to make a fully functioning Foodtracker Website hosted on a Kitura Server. Now we just have to make it look better with some more HTML and CSS. As an example, We have taken the CSS template from [Food Blog Template](https://www.w3schools.com/w3css/tryw3css_templates_food_blog.htm) and connected the server using Stencil to produce `Example.stencil`.

### Move Example.Stencil to views folder
1. Open your teminal window.
2. Change directory to your FoodTrackerBackend
```
cd ~/FoodTrackerBackend/
```
3. Move `Example.Stencil` to your Views folder.
```
mv Example.stencil FoodServer/Views/
```

### Change the target of `Response.render` to display `Example.Stencil`

1. Open your `Sources > Application > Application.swift` file.

2. Replace `FoodTemplate.stencil` with `Example.stencil` in the `response.render` call:
```swift
try response.render("Example.stencil", context: allMeals).end()
```
Now view your webpage at [http://localhost:8080/foodtracker](http://localhost:8080/foodtracker). You will see the added css styling to create your FoodTracker Website.



