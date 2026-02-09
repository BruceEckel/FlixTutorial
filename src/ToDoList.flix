eff BuyMilk {
    def buyMilk(): Unit
}

eff BuyEggs {
    def buyEggs(): Unit
}

eff BuyScrews {
    def buyScrews(): Unit
}

eff BuyPaint {
    def buyPaint(): Unit
}

eff GetGas {
    def getGas(): Unit
}

eff GroceryStore {
    def buyGroceries(): Unit
}

eff HardwareStore {
    def buyHardware(): Unit
}

// Handlers
def provideMilk(f: Unit -> a \ ef): a \ (ef - BuyMilk) + IO =
    run { f() } with handler BuyMilk {
        def buyMilk(_, resume) = { println("Buying milk"); resume() }
    }

def provideEggs(f: Unit -> a \ ef): a \ (ef - BuyEggs) + IO =
    run { f() } with handler BuyEggs {
        def buyEggs(_, resume) = { println("Buying eggs"); resume() }
    }

def provideScrews(f: Unit -> a \ ef): a \ (ef - BuyScrews) + IO =
    run { f() } with handler BuyScrews {
        def buyScrews(_, resume) = { println("Buying screws"); resume() }
    }

def providePaint(f: Unit -> a \ ef): a \ (ef - BuyPaint) + IO =
    run { f() } with handler BuyPaint {
        def buyPaint(_, resume) = { println("Buying paint"); resume() }
    }

def provideGas(f: Unit -> a \ ef): a \ (ef - GetGas) + IO =
    run { f() } with handler GetGas {
        def getGas(_, resume) = { println("Getting gas"); resume() }
    }

def groceryStore(f: Unit -> a \ ef): a \ (ef - GroceryStore) + {BuyEggs, BuyMilk} =
    run { f() } with handler GroceryStore {
        def buyGroceries(_, resume) = {
            BuyEggs.buyEggs();
            BuyMilk.buyMilk();
            resume()
        }
    }

def hardwareStore(f: Unit -> a \ ef): a \ (ef - HardwareStore) + {BuyScrews, BuyPaint} =
    run { f() } with handler HardwareStore {
        def buyHardware(_, resume) = {
            BuyScrews.buyScrews();
            BuyPaint.buyPaint();
            resume()
        }
    }

// Split work across two people
def personOne(): String \ GroceryStore = {
    GroceryStore.buyGroceries();
    "Person One tasks completed"
}

def personTwo(): String \ {HardwareStore, GetGas} = {
    HardwareStore.buyHardware();
    GetGas.getGas();
    "Person Two tasks completed"
}

// The master errand list:
def thisWeekend(): Unit \ {IO, GroceryStore, HardwareStore, GetGas} = {
    println(personOne());
    println(personTwo())
}

def todo(): Unit \ IO =
    run {
        thisWeekend()
    } with groceryStore
    with hardwareStore
    with provideEggs
    with provideMilk
    with provideScrews
    with providePaint
    with provideGas
