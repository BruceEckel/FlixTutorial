// Demonstrates default handlers

// Define an effect
eff Greet {
    def sayHello(name: String): Unit
}

// Companion module with @DefaultHandler
mod Greet {
    @DefaultHandler
    pub def runWithIO(f: Unit -> a \ ef): a \ (ef - Greet) + IO =
        run { f() } with handler Greet {
            def sayHello(name, resume) = {
                println("Hello, ${name}!");
                resume()
            }
        }
}

// Because Greet has a default handler, main can use it directly
// without an explicit run-with block!
def main(): Unit \ Greet =
    Greet.sayHello("World")
