// Demonstrates delayed execution with effect handlers

eff Suspend {
    def suspend(): Unit
}

def computation(): Unit \ {Suspend, IO} = {
    println("Step 1: Before suspend");
    Suspend.suspend();
    println("Step 3: After suspend")
}

pub def delay(): Unit \ IO = {
    println("Starting...");
    run {
        computation()
    } with handler Suspend {
        def suspend(_, resume) = {
            println("Step 2: Handler got control - doing other work");
            println("Step 2b: Now resuming the computation");
            resume()
        }
    };
    println("Done.")
}
