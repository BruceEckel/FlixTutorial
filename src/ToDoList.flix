// Individual grocery items
def buyMilk(): Unit \ IO = println("Buying milk")
def buyBread(): Unit \ IO = println("Buying bread")
def buyEggs(): Unit \ IO = println("Buying eggs")

// Individual hardware items
def buyScrews(): Unit \ IO = println("Buying screws")
def buyPaint(): Unit \ IO = println("Buying paint")

// Standalone errands
def getGas(): Unit \ IO = println("Getting gas")

// Composite tasks
def buyGroceries(): Unit \ IO = {
    buyEggs();
    buyMilk();
    buyBread()
}

def buyHardware(): Unit \ IO = {
    buyScrews();
    buyPaint()
}

// Split work across two people
def personOne(): String \ IO = {
    buyGroceries();
    "Person One tasks completed"
}

def personTwo(): String \ IO = {
    buyHardware();
    getGas();
    "Person Two tasks completed"
}

// This weekend's errands
def thisWeekend(): Unit \ IO = {
    println(personOne());
    println(personTwo())
}

def main(): Unit \ IO = thisWeekend()
