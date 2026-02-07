// Individual item effects
eff BuyMilk {
    def buyMilk(): Unit
}

eff BuyBread {
    def buyBread(): Unit
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

// Composite effects
eff GroceryList {
    def buyGroceries(): Unit
}

eff HardwareList {
    def buyHardware(): Unit
}

// Handler modules - each provides a handler
mod BuyMilk {
    pub def provide(f: Unit -> a \ ef): a \ (ef - BuyMilk) + IO =
        run { f() } with handler BuyMilk {
            def buyMilk(_, resume) = { println("Buying milk"); resume() }
        }
}

mod BuyBread {
    pub def provide(f: Unit -> a \ ef): a \ (ef - BuyBread) + IO =
        run { f() } with handler BuyBread {
            def buyBread(_, resume) = { println("Buying bread"); resume() }
        }
}

mod BuyEggs {
    pub def provide(f: Unit -> a \ ef): a \ (ef - BuyEggs) + IO =
        run { f() } with handler BuyEggs {
            def buyEggs(_, resume) = { println("Buying eggs"); resume() }
        }
}

mod BuyScrews {
    pub def provide(f: Unit -> a \ ef): a \ (ef - BuyScrews) + IO =
        run { f() } with handler BuyScrews {
            def buyScrews(_, resume) = { println("Buying screws"); resume() }
        }
}

mod BuyPaint {
    pub def provide(f: Unit -> a \ ef): a \ (ef - BuyPaint) + IO =
        run { f() } with handler BuyPaint {
            def buyPaint(_, resume) = { println("Buying paint"); resume() }
        }
}

mod GetGas {
    pub def provide(f: Unit -> a \ ef): a \ (ef - GetGas) + IO =
        run { f() } with handler GetGas {
            def getGas(_, resume) = { println("Getting gas"); resume() }
        }
}

mod GroceryList {
    pub def provide(f: Unit -> a \ ef): a \ (ef - GroceryList) + {BuyEggs, BuyMilk, BuyBread} =
        run { f() } with handler GroceryList {
            def buyGroceries(_, resume) = {
                BuyEggs.buyEggs();
                BuyMilk.buyMilk();
                BuyBread.buyBread();
                resume()
            }
        }
}

mod HardwareList {
    pub def provide(f: Unit -> a \ ef): a \ (ef - HardwareList) + {BuyScrews, BuyPaint} =
        run { f() } with handler HardwareList {
            def buyHardware(_, resume) = {
                BuyScrews.buyScrews();
                BuyPaint.buyPaint();
                resume()
            }
        }
}

// Split work across two people
def personOne(): String \ GroceryList = {
    GroceryList.buyGroceries();
    "Person One tasks completed"
}

def personTwo(): String \ {HardwareList, GetGas} = {
    HardwareList.buyHardware();
    GetGas.getGas();
    "Person Two tasks completed"
}

// This weekend's errands
def thisWeekend(): Unit \ {IO, GroceryList, HardwareList, GetGas} = {
    println(personOne());
    println(personTwo())
}

def main(): Unit \ IO =
    run {
        thisWeekend()
    } with GroceryList.provide
      with HardwareList.provide
      with BuyEggs.provide
      with BuyMilk.provide
      with BuyBread.provide
      with BuyScrews.provide
      with BuyPaint.provide
      with GetGas.provide
