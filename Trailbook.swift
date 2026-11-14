import Foundation

struct Challenge {
    enum Kind: String { case predict = "Read the signal", patch = "Patch the code", assemble = "Build a line" }
    let kind: Kind
    let prompt: String
    let code: String
    let options: [String]
    let answer: [Int]
    var fragments: [String]?
    let explanation: String

    init(_ kind: Kind, _ prompt: String, _ code: String, _ options: [String], _ answer: [Int], _ explanation: String) {
        self.kind = kind
        self.prompt = prompt
        self.code = code
        self.options = options
        self.answer = answer
        self.explanation = explanation
    }
}

struct Mission: Identifiable {
    let id: String
    let title: String
    let skill: String
    let briefing: String
    let example: String
    let dispatch: String
    let challenges: [Challenge]
}

struct Route: Identifiable {
    let id: Int
    let name: String
    let skill: String
    let patch: String
    let symbol: String
    let missions: [Mission]
}

/// One worked example supplies the context for a prediction, repair and reconstruction.
private struct Drill {
    let title: String
    let skill: String
    let note: String
    let workedExample: String
    let setup: String
    let expression: String
    let output: String
    let otherOutputs: [String]
    let patch: String
    let otherPatches: [String]
    let parts: [String]
    let decoy: String

    init(_ title: String, _ skill: String, _ note: String, _ workedExample: String, _ setup: String, _ expression: String,
         _ output: String, _ otherOutputs: [String], _ patch: String, _ otherPatches: [String],
         _ parts: [String], _ decoy: String) {
        self.title = title
        self.skill = skill
        self.note = note
        self.workedExample = workedExample
        self.setup = setup
        self.expression = expression
        self.output = output
        self.otherOutputs = otherOutputs
        self.patch = patch
        self.otherPatches = otherPatches
        self.parts = parts
        self.decoy = decoy
    }

    func mission(number: Int, dispatch: String) -> Mission {
        let program = setup + "\nprint(" + expression + ")"
        let range = expression.range(of: patch, options: .backwards)!
        let incomplete = expression.replacingCharacters(in: range, with: "___")
        let tokens = parts.map { $0.trimmingCharacters(in: .whitespaces) }
        let bank = permute(tokens + [decoy], seed: number + 1)
        let outputs = permute([output] + otherOutputs, seed: number)
        let patches = permute([patch] + otherPatches, seed: number + 2)
        var assembly = Challenge(.assemble, "Rebuild the expression for this output.", setup + "\n# Target: " + output,
                                 bank, tokens.map { bank.firstIndex(of: $0)! }, "The complete expression is " + expression + ".")
        assembly.fragments = bank.map { token in
            tokens.firstIndex(of: token).map { parts[$0] } ?? decoy
        }
        return Mission(id: "level-\(number)", title: title, skill: skill, briefing: note, example: workedExample,
                       dispatch: dispatch, challenges: [
            Challenge(.predict, "What does this program print?", program, outputs,
                      [outputs.firstIndex(of: output)!], note + " The output here is " + output + "."),
            Challenge(.patch, "Fill the gap to print \(output).", setup + "\nprint(" + incomplete + ")",
                      patches, [patches.firstIndex(of: patch)!], "Insert " + patch + " to get " + expression + "."),
            assembly
        ])
    }

    private func permute(_ values: [String], seed: Int) -> [String] {
        var result = seed.isMultiple(of: 2) ? values : Array(values.reversed())
        let offset = seed % result.count
        result = Array(result.dropFirst(offset)) + result.prefix(offset)
        return result
    }
}

enum Trailbook {
    static let routes = [
        Route(id: 1, name: "Pinewood Station", skill: "Output, variables & numbers", patch: "Signal Scout", symbol: "antenna.radiowaves.left.and.right", missions: [
            Mission(id: "signal", title: "First transmission", skill: "Printing text", briefing: "The radio is quiet. Give Pip a voice! In Python, print() sends a value to the output. Put a message in quotes so Python reads it as text.", example: "print(\"Pip online\")", dispatch: "Pip here. Let's get this radio talking.", challenges: [
                Challenge(.predict, "What will the radio say?", "print(\"Hello, trail!\")", ["print", "Hello, trail!", "\"Hello, trail!\""], [1], "The quotes mark the start and end of the text. Only the words and punctuation inside appear."),
                Challenge(.patch, "Fill the gap to send a message.", "___(\"All clear\")", ["send", "echo", "print"], [2], "Python's built-in print() displays whatever you place between its parentheses."),
                Challenge(.assemble, "Build the line that prints Ready.", "# Target output: Ready", [")", "\"Ready\"", "print(", "ready"], [2, 1, 0], "print(\"Ready\") sends the word Ready to the output.")
            ]),
            Mission(id: "callsign", title: "Call sign", skill: "Variables", briefing: "Give the station a call sign. A variable gives a value a name. Use = to store it, then use the name without quotes to read the value back.", example: "station = \"Pine\"\nprint(station)", dispatch: "Our station needs a call sign. Got one?", challenges: [
                Challenge(.predict, "Which call sign goes out?", "call = \"Fern\"\nprint(call)", ["call", "Fern", "Pine"], [1], "call refers to the text Fern. Quotation marks around call would print the name itself."),
                Challenge(.patch, "Read the stored call sign.", "call = \"Moss\"\nprint(___)", ["\"call\"", "name", "call"], [2], "Pass the variable call to print() to read its current value."),
                Challenge(.assemble, "Store Birch in a variable named call.", "# Give the radio a new call sign", ["=", "\"Birch\"", "call", "=="], [2, 0, 1], "call = \"Birch\" assigns the text Birch to the name call.")
            ]),
            Mission(id: "packs", title: "Supply count", skill: "Number operations", briefing: "Check the supply crate before we head out. Python can do math directly on numbers. Use + to add, - to subtract and * to multiply.", example: "packs = 3 * 2\nprint(packs)", dispatch: "Six packs, two paws. Help me count?", challenges: [
                Challenge(.predict, "How many batteries are ready?", "cells = 4 + 3\nprint(cells)", ["43", "7", "4 + 3"], [1], "These are numbers, so + adds four and three to make seven."),
                Challenge(.patch, "Find the total in four pairs.", "total = 4 ___ 2\nprint(total)  # target: 8", ["-", "+", "*"], [2], "Multiplication counts four groups of two."),
                Challenge(.assemble, "Subtract two used cells from stock.", "stock = 9\n# Finish: left = …", ["2", "stock", "-", "+"], [1, 2, 0], "left = stock - 2 stores the seven cells still available.")
            ])
        ]),
        Route(id: 2, name: "Switchback Ridge", skill: "Decisions, loops & lists", patch: "Ridge Navigator", symbol: "mountain.2.fill", missions: [
            Mission(id: "weather", title: "Weather fork", skill: "Conditions", briefing: "At the fork, choose a path with if. An indented line runs when its condition is true. The else branch runs when the condition is false. Use == to compare two values.", example: "wind = \"calm\"\nif wind == \"calm\":\n    print(\"Climb\")\nelse:\n    print(\"Wait\")", dispatch: "Wind on the ridge! Which way do we go?", challenges: [
                Challenge(.predict, "Which instruction does Pip hear?", "wind = \"high\"\nif wind == \"calm\":\n    print(\"Climb\")\nelse:\n    print(\"Wait\")", ["Climb", "Wait", "Climb and Wait"], [1], "high differs from calm, so Python follows the else branch."),
                Challenge(.patch, "Test whether the gate is open.", "gate = \"open\"\nif gate ___ \"open\":\n    print(\"Go\")", ["=", "!=", "=="], [2], "== checks for equality. The test is true when gate holds open."),
                Challenge(.assemble, "Build the condition for low wind.", "# Finish: if …\n    print(\"Cross\")", ["==", ":", "wind", "\"low\""], [2, 0, 3, 1], "if wind == \"low\": starts a branch that runs only in low wind.")
            ]),
            Mission(id: "beacon", title: "Echo beacon", skill: "Loops", briefing: "Repeat a signal with a for loop. range(3) gives you 0, 1 and 2. Python runs the indented lines once for each value, stopping before 3.", example: "for n in range(3):\n    print(n)", dispatch: "One ping might get lost. Send a few!", challenges: [
                Challenge(.predict, "How many pings will you hear?", "for n in range(4):\n    print(\"Ping\")", ["3", "5", "4"], [2], "The values 0, 1, 2 and 3 each trigger one ping."),
                Challenge(.patch, "Send exactly two echoes.", "for n in range(___):\n    print(\"Echo\")", ["2", "1", "3"], [0], "range(2) gives two values, 0 and 1."),
                Challenge(.assemble, "Build the loop header for three calls.", "# Write the line above this one\n    print(\"Call\")", ["in", "range(3):", "for", "n"], [2, 3, 0, 1], "for n in range(3): repeats the indented call three times.")
            ]),
            Mission(id: "cache", title: "Cache coordinates", skill: "Lists & indexing", briefing: "Keep trail stops in an ordered list. Square brackets hold the items. Read one with its index: the first item is at 0, the second at 1, and so on.", example: "stops = [\"Pine\", \"Creek\"]\nprint(stops[0])", dispatch: "The cache is on our list. Find its stop.", challenges: [
                Challenge(.predict, "Which stop is at index 1?", "stops = [\"Pine\", \"Creek\", \"Ridge\"]\nprint(stops[1])", ["Pine", "Creek", "Ridge"], [1], "Index 0 is Pine. The next item, Creek, is at index 1."),
                Challenge(.patch, "Pick the third supply.", "kit = [\"map\", \"rope\", \"radio\"]\nprint(kit[___])", ["3", "1", "2"], [2], "Counting from zero makes the third item's index 2."),
                Challenge(.assemble, "Read the first item from kit.", "# Finish: item = …", ["]", "kit", "[", "0"], [1, 2, 3, 0], "kit[0] retrieves the first item in the list.")
            ])
        ]),
        Route(id: 3, name: "Summit Relay", skill: "Functions, returns & a final relay", patch: "Relay Keeper", symbol: "bolt.horizontal.fill", missions: [
            Mission(id: "routine", title: "Radio routine", skill: "Defining functions", briefing: "A function packages instructions under a name. def defines it, and parentheses after its name call it. The indented body waits until the call.", example: "def hail():\n    print(\"Hello\")\n\nhail()", dispatch: "Let's give our favorite signal a shortcut.", challenges: [
                Challenge(.predict, "Which message appears first?", "def hail():\n    print(\"Hello\")\nprint(\"Ready\")\nhail()", ["Hello", "Ready", "hail"], [1], "Defining hail doesn't run it. Ready appears first, followed by Hello when hail() is called."),
                Challenge(.patch, "Define a function named ping.", "___ ping():\n    print(\"Ping\")", ["for", "return", "def"], [2], "def introduces a function definition."),
                Challenge(.assemble, "Call the function named ping.", "def ping():\n    print(\"Ping\")\n# Call it here", [")", "def", "ping", "("], [2, 3, 0], "ping() runs the function body once.")
            ]),
            Mission(id: "boost", title: "Signal boost", skill: "Parameters & returns", briefing: "A parameter receives the value you send into a function. return sends a result back to the caller, so another line can use it.", example: "def boost(n):\n    return n * 2\n\nprint(boost(3))", dispatch: "The signal is faint. Let's double it.", challenges: [
                Challenge(.predict, "What strength reaches the relay?", "def boost(n):\n    return n * 2\nprint(boost(5))", ["5", "7", "10"], [2], "The parameter n receives 5. The function returns 5 times 2, which print() displays."),
                Challenge(.patch, "Send the result back to the caller.", "def add_one(n):\n    ___ n + 1", ["return", "print", "def"], [0], "return makes n + 1 the result of the function call."),
                Challenge(.assemble, "Call boost with strength 4.", "# Finish: strength = …", ["4", "n", "boost(", ")"], [2, 0, 3], "boost(4) passes 4 into boost and gives its result to strength.")
            ]),
            Mission(id: "summit", title: "Summit broadcast", skill: "Combining your skills", briefing: "Connect every station. A for loop can visit each value in a list. Pass each name to a function. The + operator joins two pieces of text into a single message.", example: "def hail(name):\n    print(\"Hi \" + name)\n\nfor stop in [\"Pine\", \"Ridge\"]:\n    hail(stop)", dispatch: "All stations standing by for your broadcast.", challenges: [
                Challenge(.predict, "What is the last transmission?", "def hail(s):\n    print(\"Hi \" + s)\nfor s in [\"Pine\", \"Ridge\"]:\n    hail(s)", ["Hi Pine", "Hi Ridge", "Hi s"], [1], "The loop visits Pine first and Ridge last. Each name is joined to Hi followed by a space."),
                Challenge(.patch, "Broadcast to each station in order.", "stops = [\"Base\", \"Peak\"]\nfor stop in stops:\n    print(___)", ["stops", "\"stop\"", "stop"], [2], "stop holds the current station. Passing it to print sends one name on each pass."),
                Challenge(.assemble, "Call hail with the current stop.", "def hail(s):\n    print(\"Online: \" + s)\nfor stop in [\"Base\", \"Peak\"]:\n    # Your call goes here", ["stop", "hail(", ")", "stops"], [1, 0, 2], "hail(stop) sends Online: Base and then Online: Peak. The whole trail is connected!")
            ])
        ]),
        station(4, "Granite Works", "Integer math & measurement", "Granite Surveyor", "ruler.fill", "Granite Works calling. I have the supplies. You do the math.", [
            Drill("Whole crates", "Floor division", "The // operator divides and rounds down to a whole number. Use it to count how many full crates you can pack.", "print(11 // 3)", "cells = 17", "cells // 4", "4", ["4.25", "1"], "//", ["/", "%"], ["cells // ", "4"], "/"),
            Drill("Spare batteries", "Remainders", "The % operator gives the remainder after division. It counts the loose cells after the full crates leave.", "print(11 % 3)", "cells = 17", "cells % 4", "1", ["4", "0"], "%", ["//", "*"], ["cells % ", "4"], "//"),
            Drill("Tower squares", "Exponents", "Two asterisks raise a number to a power. A square plot has side times side grid cells.", "print(3 ** 2)", "side = 5", "side ** 2", "25", ["10", "7"], "**", ["+", "*"], ["side ** ", "2"], "+"),
            Drill("Ration priority", "Operator precedence", "Multiplication happens before addition. Count all the meal packs before adding the spare rations.", "print(2 + 3 * 4)", "spare = 3\npacks = 4", "spare + packs * 2", "11", ["14", "9"], "*", ["-", "+"], ["spare + ", "packs", " * 2"], "-"),
            Drill("Equal shares", "Parentheses", "Parentheses change the order of calculation. Add both supply piles before splitting them between teams.", "print((2 + 3) * 4)", "east = 8\nwest = 4", "(east + west) // 2", "6", ["10", "24"], "//", ["+", "*"], ["(east + ", "west", ") // 2"], "+"),
            Drill("Distance marker", "Absolute values", "abs() removes the sign of a number. Use it to measure the distance from a trail marker to zero.", "print(abs(-4))", "marker = -9", "abs(marker)", "9", ["-9", "True"], "abs", ["str", "bool"], ["abs(", "marker", ")"], "str"),
            Drill("Gauge reading", "Rounding", "round(number, digits) rounds a reading to the requested number of decimal places.", "print(round(2.74, 1))", "gauge = 7.36", "round(gauge, 1)", "7.4", ["7.3", "7.36"], "round", ["min", "max"], ["round(gauge, ", "1", ")"], "min")
        ]),
        station(5, "Letterpress Grove", "Working with strings", "Type Setter", "textformat", "Letterpress is open. Let's get these messages ready to print.", [
            Drill("Loud and clear", "Uppercase strings", "Call upper() on a string to get an uppercase copy for the station board.", "print('fern'.upper())", "name = 'Pine'", "name.upper()", "PINE", ["Pine", "pine"], "upper", ["lower", "title"], ["name", ".upper()"], "lower"),
            Drill("Quiet channel", "Lowercase strings", "lower() produces a lowercase copy. Normalize a call sign before comparing it with another.", "print('CAMP'.lower())", "call = 'RiDGe'", "call.lower()", "ridge", ["RIDGE", "Ridge"], "lower", ["upper", "title"], ["call", ".lower()"], "upper"),
            Drill("Trim the tape", "Stripping whitespace", "strip() removes whitespace at both ends. Spaces between words remain part of the message.", "print('  lamp  '.strip())", "line = '  red fox  '", "line.strip()", "red fox", ["redfox", "RED FOX"], "strip", ["upper", "title"], ["line", ".strip()"], "upper"),
            Drill("Swap the signal", "Replacing text", "replace(old, new) copies the message with each occurrence of old changed to new.", "print('old map'.replace('old', 'new'))", "note = 'red-red'", "note.replace('red', 'oak')", "oak-oak", ["oak-red", "red-oak"], "replace", ["split", "count"], ["note.replace('red', ", "'oak'", ")"], "split"),
            Drill("Prefix patrol", "Checking a prefix", "startswith() tests the beginning of a string and returns True or False.", "print('TX-3'.startswith('TX'))", "tag = 'RX-14'", "tag.startswith('RX')", "True", ["False", "RX"], "startswith", ["endswith", "count"], ["tag.startswith(", "'RX'", ")"], "endswith"),
            Drill("Count the calls", "Counting substrings", "count() returns the number of non-overlapping matches. A one-letter search counts every matching letter.", "print('letter'.count('t'))", "word = 'banana'", "word.count('a')", "3", ["1", "6"], "count", ["find", "index"], ["word.count(", "'a'", ")"], "find"),
            Drill("Tail frequency", "Negative indices", "Index -1 reads the last character. Negative positions count backward from the end of the message.", "print('CAMP'[-1])", "code = 'PINE7'", "code[-1]", "7", ["P", "E"], "-1", ["0", "1"], ["code", "[-1]"], "0")
        ]),
        station(6, "Willow Depot", "Lists & trail inventory", "Cache Steward", "shippingbox.fill", "Willow Depot here. Help me sort the sled before it leaves.", [
            Drill("Loaded sled", "List length", "len() counts the items in a list. Each supply name occupies one slot.", "print(len(['hat', 'cup']))", "kit = ['map', 'rope', 'tin']", "len(kit)", "3", ["2", "4"], "len", ["min", "max"], ["len(", "kit", ")"], "min"),
            Drill("Drop supply", "Appending items", "append() adds one item at the end of a list. A negative index can read the newest supply.", "gear = ['cup']\ngear.append('hat')\nprint(gear)", "kit = ['map']\nkit.append('rope')", "kit[-1]", "rope", ["map", "None"], "-1", ["0", "-2"], ["kit", "[-1]"], "0"),
            Drill("Front of queue", "Inserting at an index", "insert(0, item) places an item at the front and shifts older items one position to the right.", "gear = ['cup']\ngear.insert(0, 'hat')\nprint(gear)", "queue = ['Pip', 'Ash']\nqueue.insert(0, 'Bee')", "queue[1]", "Pip", ["Bee", "Ash"], "1", ["0", "2"], ["queue", "[1]"], "0"),
            Drill("Last parcel", "Popping items", "pop() removes and returns the last item by default. Print its result to see which parcel left.", "gear = ['cup', 'hat']\nprint(gear.pop())", "bags = ['oak', 'fern', 'ash']", "bags.pop()", "ash", ["oak", "None"], "pop", ["sort", "reverse"], ["bags", ".pop()"], "sort"),
            Drill("Supply slice", "List slices", "A slice includes its start index and stops before its end index. The result is another list.", "hours = [1, 2, 3, 4]\nprint(hours[0:2])", "stock = [2, 4, 6, 8]", "stock[1:3]", "[4, 6]", ["[2, 4]", "[4, 6, 8]"], "1:3", ["0:2", "2:4"], ["stock", "[1:3]"], "0:2"),
            Drill("Mirror trail", "Reverse slicing", "A step of -1 moves backward. Leaving both bounds empty reverses the whole list.", "print([2, 7, 9][::-1])", "stops = [1, 3, 5]", "stops[::-1]", "[5, 3, 1]", ["[1, 3, 5]", "[1, 5]"], "-1", ["1", "2"], ["stops", "[::-1]"], "1"),
            Drill("Two convoys", "Joining lists", "The + operator joins lists in order and produces a new list.", "print(['a'] + ['b', 'c'])", "east = [1, 2]\nwest = [3]", "east + west", "[1, 2, 3]", ["[3, 1, 2]", "3"], "+", ["==", "!="], ["east + ", "west"], "==")
        ]),
        station(7, "Atlas Hollow", "Dictionaries & lookups", "Atlas Keeper", "book.fill", "Atlas Hollow calling. Which entry should I read back?", [
            Drill("Station lookup", "Dictionary keys", "A dictionary pairs keys with values. Read the value for one station by putting its key in brackets.", "codes = {'base': 2}\nprint(codes['base'])", "freq = {'oak': 4, 'ash': 7}", "freq['ash']", "7", ["4", "ash"], "'ash'", ["'oak'", "'fir'"], ["freq", "['ash']"], "'oak'"),
            Drill("Backup frequency", "Default values", "get(key, fallback) returns the fallback when the key is missing.", "codes = {'base': 2}\nprint(codes.get('hill', 0))", "freq = {'oak': 4}", "freq.get('fir', 9)", "9", ["4", "None"], "get", ["popitem", "keys"], ["freq.get('fir', ", "9", ")"], "popitem"),
            Drill("Revised ledger", "Updating values", "Assigning to an existing key replaces its value. The other entries keep their values.", "codes = {'base': 2}\ncodes['base'] = 5\nprint(codes)", "fuel = {'oak': 2, 'ash': 1}\nfuel['oak'] = 6", "fuel['oak']", "6", ["2", "1"], "'oak'", ["'ash'", "'fir'"], ["fuel", "['oak']"], "'ash'"),
            Drill("Key patrol", "Key membership", "The in operator checks a dictionary's keys. It does not search through the values.", "codes = {'base': 2}\nprint('hill' in codes)", "stock = {'rope': 3}", "'rope' in stock", "True", ["False", "3"], "in", ["not in", "=="], ["'rope' in ", "stock"], "not in"),
            Drill("Station census", "Counting keys", "len() counts distinct keys. Writing a new value for an existing key leaves the key count unchanged.", "codes = {'base': 2}\nprint(len(codes))", "log = {'oak': 1, 'fir': 2}\nlog['oak'] = 7", "len(log)", "2", ["3", "7"], "len", ["max", "min"], ["len(", "log", ")"], "max"),
            Drill("Fuel manifest", "Summing values", "values() provides the stored values. Feed them to sum() to total the fuel across stations.", "codes = {'a': 2, 'b': 5}\nprint(list(codes.values()))", "fuel = {'oak': 4, 'ash': 3}", "sum(fuel.values())", "7", ["2", "4"], "values", ["keys", "items"], ["sum", "(fuel.values())"], "keys"),
            Drill("Nested cache", "Nested dictionaries", "Two bracket lookups can follow a path: find a station first, then read a field inside its record.", "data = {'hill': {'height': 9}}\nprint(data['hill']['height'])", "base = {'oak': {'fuel': 8, 'kits': 2}}", "base['oak']['fuel']", "8", ["2", "oak"], "'fuel'", ["'kits'", "'food'"], ["base[", "'oak'", "]['fuel']"], "'kits'")
        ]),
        station(8, "Compass Crossing", "Boolean logic & decisions", "Compass Scout", "safari.fill", "I'm at the crossing. Your code decides which way we go.", [
            Drill("Open threshold", "Inclusive comparisons", ">= includes the boundary value. Check whether the battery meets the minimum charge.", "print(4 >= 5)", "charge = 5", "charge >= 5", "True", ["False", "5"], ">=", [">", "!="], ["charge", " >= 5"], ">"),
            Drill("Both gates", "Boolean conjunction", "and requires both conditions to be true. A single closed gate blocks this route.", "print(True and True)", "bridge = True\ngate = False", "bridge and gate", "False", ["True", "None"], "and", ["or", "!="], ["bridge and ", "gate"], "or"),
            Drill("Either beacon", "Boolean alternatives", "or is true when at least one signal is available. It still works if the first signal is missing.", "print(False or False)", "east = False\nwest = True", "east or west", "True", ["False", "None"], "or", ["and", "=="], ["east or ", "west"], "and"),
            Drill("Reverse flag", "Negation", "not flips a truth value. A clear trail has no obstruction flag.", "print(not True)", "blocked = False", "not blocked", "True", ["False", "0"], "not", ["+", "-"], ["not ", "blocked"], "+"),
            Drill("Safe interval", "Chained comparisons", "A chained comparison checks both bounds. The lower limit is included and the upper limit is excluded.", "n = 4\nprint(1 <= n < 5)", "temp = 8", "2 <= temp < 8", "False", ["True", "8"], "<", ["<=", "=="], ["2 <= ", "temp", " < 8"], "<="),
            Drill("Quick detour", "Conditional expressions", "A conditional expression chooses the value before if when its condition is true, or the value after else otherwise.", "rain = False\nprint('wait' if rain else 'walk')", "snow = 3", "'wait' if snow > 2 else 'go'", "wait", ["go", "True"], ">", ["<", "=="], ["'wait' if ", "snow", " > 2 else 'go'"], "<"),
            Drill("Empty lookout", "Truth of collections", "Empty lists are false in a condition. A nonempty list is true even when its only item is zero.", "print(bool([]))", "readings = [0]", "bool(readings)", "True", ["False", "0"], "bool", ["len", "sum"], ["bool(", "readings", ")"], "len")
        ]),
        station(9, "Timber Loop", "Iteration & loop control", "Loop Ranger", "repeat", "Timber Loop here. Let's trace each pass before we transmit.", [
            Drill("Stride posts", "Range steps", "range(start, stop, step) advances by the step and excludes the stop. list() reveals the visited posts.", "print(list(range(1, 7, 2)))", "start = 2", "list(range(start, 9, 3))", "[2, 5, 8]", ["[2, 5, 8, 9]", "[2, 4, 6, 8]"], "3", ["2", "1"], ["list(range(", "start", ", 9, 3))"], "2"),
            Drill("Downhill ticks", "Descending ranges", "A negative step counts down. The stopping value is excluded even when counting backward.", "print(list(range(3, 0, -1)))", "top = 4", "list(range(top, 0, -2))", "[4, 2]", ["[4, 2, 0]", "[4, 3, 2, 1]"], "-2", ["2", "-1"], ["list(range(", "top", ", 0, -2))"], "2"),
            Drill("Running tally", "Accumulators", "Start a total at zero and add each reading inside the loop. After the loop it contains their sum.", "total = 0\nfor n in [1, 4]:\n    total += n\nprint(total)", "total = 0\nfor n in [2, 3, 4]:\n    total += n", "total >= 9", "True", ["False", "9"], ">=", [">", "<"], ["total", " >= 9"], ">"),
            Drill("Marked posts", "Enumerating items", "enumerate() pairs each item with its position. The second argument sets the first position number.", "for i, word in enumerate(['a', 'b'], 1):\n    print(i, word)", "pair = list(enumerate(['oak', 'ash'], 1))", "pair[1][0]", "2", ["1", "ash"], "1", ["0", "-2"], ["pair[1][", "0", "]"], "-2"),
            Drill("Paired crews", "Zipping lists", "zip() pairs items by position and stops when the shorter list ends. Count the teams it formed.", "print(list(zip(['a', 'b'], [1, 2])))", "teams = list(zip(['Pip', 'Ash', 'Bee'], [4, 8]))", "len(teams)", "2", ["3", "5"], "len", ["list", "tuple"], ["len(", "teams", ")"], "list"),
            Drill("Early signal", "Breaking a loop", "break exits the nearest loop immediately. Inspect which signal caused the loop to stop.", "for n in [1, 3, 5]:\n    if n == 3:\n        break\n    print(n)", "for signal in [2, 7, 9]:\n    if signal > 5:\n        break", "signal * 2", "14", ["18", "4"], "*", ["+", "-"], ["signal", " * 2"], "+"),
            Drill("Skip the hollow", "Continuing a loop", "continue skips the rest of this iteration. Track only the positive readings that reach append().", "for n in [1, 2, 3]:\n    if n == 2:\n        continue\n    print(n)", "kept = []\nfor n in [0, 2, 0, 5]:\n    if n == 0:\n        continue\n    kept.append(n)", "sum(kept)", "7", ["2", "5"], "sum", ["len", "max"], ["sum(", "kept", ")"], "len")
        ]),
        station(10, "Lantern Workshop", "Comprehensions & sets", "Lantern Maker", "lightbulb.fill", "The lanterns are lit. Ready to pick out a pattern?", [
            Drill("Double lanterns", "List comprehensions", "A list comprehension evaluates its first expression for every item in the input.", "print([x + 1 for x in [1, 3]])", "nums = [2, 4, 6]", "[n * 2 for n in nums]", "[4, 8, 12]", ["[4, 6, 8]", "[2, 4, 6]"], "*", ["+", "-"], ["[n * 2 for n in ", "nums", "]"], "+"),
            Drill("Bright readings", "Filtering a comprehension", "An if clause at the end of a comprehension keeps only items that pass its test.", "print([x for x in [2, 6, 1] if x < 4])", "nums = [1, 4, 5]", "[n for n in nums if n > 3]", "[4, 5]", ["[1]", "[1, 4, 5]"], ">", ["<", "=="], ["[n for n in ", "nums", " if n > 3]"], "<"),
            Drill("Name plates", "Mapping a method", "Call a string method inside a comprehension to transform each trail label.", "print([s.lower() for s in ['A', 'B']])", "tags = ['oak', 'ash']", "[t.upper() for t in tags]", "['OAK', 'ASH']", ["['Oak', 'Ash']", "['oak', 'ash']"], "upper", ["lower", "title"], ["[t.upper() for t in ", "tags", "]"], "lower"),
            Drill("Unique prints", "Deduplicating with sets", "A set keeps one copy of each distinct value. Its length measures how many species left tracks.", "print(sorted(set([4, 4, 7])))", "tracks = ['fox', 'owl', 'fox']", "len(set(tracks))", "2", ["3", "1"], "set", ["list", "tuple"], ["len", "(set(tracks))"], "list"),
            Drill("Shared tracks", "Set intersection", "The & operator keeps values present in both sets. sorted() gives the result a predictable order.", "print(sorted({3, 5} & {5, 7}))", "a = {1, 2, 4}\nb = {2, 3, 4}", "sorted(a & b)", "[2, 4]", ["[1, 2, 3, 4]", "[1]"], "&", ["|", "-"], ["sorted", "(a & b)"], "|"),
            Drill("All clearings", "Set union", "The | operator combines two sets. An item shared between them appears only once.", "print(sorted({3, 5} | {5, 7}))", "a = {1, 2}\nb = {2, 3}", "sorted(a | b)", "[1, 2, 3]", ["[2]", "[1, 2, 2, 3]"], "|", ["&", "-"], ["sorted", "(a | b)"], "&"),
            Drill("Missing markers", "Set difference", "The - operator on sets keeps the values in the first set that are absent from the second.", "print(sorted({3, 5} - {5, 7}))", "plan = {1, 2, 3}\ndone = {1, 3}", "sorted(plan - done)", "[2]", ["[1, 3]", "[1, 2, 3]"], "-", ["|", "&"], ["sorted(", "plan", " - done)"], "|")
        ]),
        station(11, "Parcel Junction", "Function arguments & results", "Parcel Engineer", "puzzlepiece.extension.fill", "Parcel Junction calling. Send the inputs and I'll catch the result.", [
            Drill("Default parcel", "Default arguments", "A parameter with a default value can be left out of a call. The function uses the default unless you supply another value.", "def greet(name='Pip'):\n    return 'Hi ' + name\nprint(greet())", "def pack(n=3):\n    return n * 2", "pack() + 1", "7", ["6", "3"], "pack", ["sum", "len"], ["pack() + ", "1"], "sum"),
            Drill("Named delivery", "Keyword arguments", "Keyword arguments match parameter names. They can arrive in a different order from the definition.", "def mix(a, b):\n    return a - b\nprint(mix(b=1, a=4))", "def cargo(boxes, each):\n    return boxes * each", "cargo(each=5, boxes=3)", "15", ["8", "35"], "each", ["weight", "box"], ["cargo", "(each=5, boxes=3)"], "weight"),
            Drill("Paired bearings", "Tuple unpacking", "A function can return two values as a tuple. Unpack them into names in the same order.", "def bounds():\n    return 2, 7\nlow, high = bounds()\nprint(high)", "def point():\n    return 3, 8\nx, y = point()", "y - x", "5", ["11", "-5"], "-", ["+", "*"], ["y", " - x"], "+"),
            Drill("Private signal", "Local scope", "A name assigned inside a function is local to that call. The outer variable keeps its own value.", "n = 8\ndef read():\n    n = 2\n    return n\nprint(read(), n)", "tone = 4\ndef local():\n    tone = 9\n    return tone", "tone + local()", "13", ["18", "8"], "+", ["-", "*"], ["tone + ", "local", "()"], "-"),
            Drill("Guard station", "Early returns", "return immediately exits a function. A guard can handle an invalid reading before the usual calculation.", "def cap(x):\n    if x > 5:\n        return 5\n    return x\nprint(cap(8))", "def safe(n):\n    if n < 0:\n        return 0\n    return n + 1", "safe(-2) + safe(3)", "4", ["2", "5"], "+", ["*", "-"], ["safe(", "-2", ") + safe(3)"], "*"),
            Drill("Relay chain", "Function composition", "The inner call runs first. Its return value becomes the argument for the outer call.", "def up(x):\n    return x + 1\nprint(up(up(1)))", "def add(n):\n    return n + 1\ndef twice(n):\n    return n * 2", "twice(add(3))", "8", ["7", "6"], "twice", ["add", "abs"], ["twice(add(", "3", "))"], "add"),
            Drill("Many supplies", "Variable-length arguments", "A parameter prefixed with * gathers extra positional arguments into a tuple. The function can process any number of supplies.", "def count(*items):\n    return len(items)\nprint(count('a', 'b'))", "def load(*weights):\n    return sum(weights)", "load(2, 3, 5)", "10", ["5", "3"], "load", ["max", "min"], ["load(2, 3, ", "5", ")"], "max")
        ]),
        station(12, "Paper Mill", "Parsing & formatting text", "Paper Cartographer", "doc.text.fill", "Paper Mill here. This dispatch needs a clean read.", [
            Drill("Split dispatch", "Splitting strings", "split(separator) breaks a message into a list. The separator itself is left out.", "print('red,blue'.split(','))", "msg = 'oak|ash|fir'", "msg.split('|')[1]", "ash", ["oak", "fir"], "split", ["join", "strip"], ["msg.split(", "'|'", ")[1]"], "join"),
            Drill("Tie the labels", "Joining strings", "Call join() on the separator. Python places it between adjacent labels, with no separator at the ends.", "print('/'.join(['oak', 'fir']))", "tags = ['N', 'E', 'S']", "'-'.join(tags)", "N-E-S", ["NES", "N-E-S-"], "join", ["split", "strip"], ["'-'.join(", "tags", ")"], "split"),
            Drill("Numeric dial", "Parsing an integer", "int() converts digits in a string to an integer. Convert before adding to a numeric reading.", "print(int('12') - 1)", "dial = '07'", "int(dial) + 2", "9", ["072", "4"], "int", ["str", "len"], ["int(", "dial", ") + 2"], "str"),
            Drill("Padded code", "Padding digits", "zfill(width) adds leading zeroes until a string reaches the requested width. Longer strings keep their length.", "print('7'.zfill(3))", "serial = '42'", "serial.zfill(5)", "00042", ["42000", "0042"], "zfill", ["center", "ljust"], ["serial.zfill(", "5", ")"], "center"),
            Drill("Signal offset", "Finding a substring", "find() returns the starting index of the first match, or -1 if the text is missing. Indexing starts at zero.", "print('hilltop'.find('top'))", "msg = 'north-east'", "msg.find('east')", "6", ["5", "1"], "find", ["count", "endswith"], ["msg.find(", "'east'", ")"], "count"),
            Drill("Meter card", "Formatted strings", "An f-string substitutes expressions inside braces. The .1f format displays exactly one digit after the decimal point.", "depth = 4.25\nprint(f'{depth:.2f} m')", "temp = 3.75", "f'{temp:.1f} C'", "3.8 C", ["3.75 C", "3 C"], "f", ["r", "b"], ["f'{", "temp", ":.1f} C'"], "r"),
            Drill("Number check", "Digit checks", "isdigit() tests whether every character is a digit. The minus sign is a separate character.", "print('007'.isdigit())", "tag = '-12'", "tag.isdigit()", "False", ["True", "-12"], "isdigit", ["lower", "strip"], ["tag", ".isdigit()"], "lower")
        ]),
        station(13, "Sorting Bluff", "Ordering & search", "Bluff Surveyor", "arrow.up.arrow.down", "I'm on the bluff. Which signal belongs at the front?", [
            Drill("First reading", "Minimum values", "min() returns the smallest reading in a collection. It works even if the readings arrive out of order.", "print(min([3, 9, 2]))", "pings = [8, 3, 6]", "min(pings)", "3", ["8", "6"], "min", ["max", "sum"], ["min(", "pings", ")"], "max"),
            Drill("Highest ridge", "Maximum values", "max() returns the largest value. Compare the peaks before you pick the highest lookout.", "print(max([6, 1, 4]))", "peaks = [7, 11, 8]", "max(peaks)", "11", ["7", "8"], "max", ["min", "len"], ["max(", "peaks", ")"], "min"),
            Drill("Sort the cargo", "Sorted copies", "sorted() creates an ascending list. The original manifest stays in its original order.", "print(sorted([4, 1, 3]))", "cargo = [7, 2, 4]", "sorted(cargo)[0]", "2", ["7", "4"], "sorted", ["list", "tuple"], ["sorted(", "cargo", ")[0]"], "list"),
            Drill("Downward roster", "Reverse sorting", "reverse=True asks sorted() for descending order. Trace the middle two items after sorting.", "print(sorted([1, 4, 3], reverse=True))", "ranks = [2, 8, 5, 4]", "sorted(ranks, reverse=True)[1:3]", "[5, 4]", ["[4, 5]", "[8, 5]"], "True", ["False", "None"], ["sorted(", "ranks", ", reverse=True)[1:3]"], "False"),
            Drill("Short call signs", "Sorting by a key", "key=len compares lengths instead of letters. The shortest call sign comes first.", "print(sorted(['ant', 'ox'], key=len))", "tags = ['aspen', 'fir', 'pine']", "sorted(tags, key=len)[0]", "fir", ["pine", "willow"], "len", ["str", "sum"], ["sorted(", "tags", ", key=len)[0]"], "str"),
            Drill("Find the lantern", "First matching index", "list.index() gives the position of the first matching item. A later match does not replace it.", "print(['pine', 'oak'].index('oak'))", "lights = [4, 7, 2, 7]", "lights.index(7)", "1", ["3", "2"], "index", ["count", "pop"], ["lights.index(", "7", ")"], "count"),
            Drill("Middle post", "Binary search", "In a sorted list, compare the middle item to the target. For a larger target, move the lower bound past the middle index.", "a = [1, 3, 8]\nlo, hi = 0, 2\nmid = (lo + hi) // 2\nprint(a[mid])", "posts = [2, 4, 7, 9, 12]\nlo, hi = 0, len(posts) - 1\nmid = (lo + hi) // 2\nif posts[mid] < 9:\n    lo = mid + 1", "posts[lo]", "9", ["7", "12"], "lo", ["hi", "mid"], ["posts", "[lo]"], "hi")
        ]),
        station(14, "Rope Bridge", "Queues, stacks & nested data", "Bridge Builder", "square.3.layers.3d", "Rope Bridge calling. Keep an eye on the order of the cargo.", [
            Drill("Last on first off", "Stacks", "Use append() to push items onto a stack. pop() removes the most recently pushed item.", "s = ['old']\ns.append('new')\nprint(s.pop())", "stack = ['map']\nstack.append('rope')\nstack.append('tin')", "stack.pop()", "tin", ["map", "rope"], "pop", ["clear", "reverse"], ["stack", ".pop()"], "clear"),
            Drill("First in line", "Queues", "A deque can add at the right and remove at the left. This serves arrivals in their original order.", "from collections import deque\nq = deque(['a', 'b'])\nprint(q.popleft())", "from collections import deque\nline = deque(['Pip', 'Ash'])\nline.append('Bee')", "line.popleft()", "Pip", ["Bee", "Ash"], "popleft", ["pop", "clear"], ["line", ".popleft()"], "pop"),
            Drill("Two handles", "Shared references", "Assigning a list to another name shares the same list. An append through either name changes the shared contents.", "x = [4]\ny = x\ny.append(8)\nprint(x)", "a = [1, 2]\nb = a\nb.append(3)", "len(a)", "3", ["2", "6"], "len", ["min", "sum"], ["len(", "a", ")"], "min"),
            Drill("Spare manifest", "Copying a list", "copy() creates a new outer list. Appending a number to the copy leaves the original list alone.", "x = [4]\ny = x.copy()\ny.append(8)\nprint(x)", "a = [3, 5]\nb = a.copy()\nb.append(7)", "sum(a)", "8", ["15", "5"], "sum", ["max", "len"], ["sum(", "a", ")"], "max"),
            Drill("Grid reference", "Nested lists", "Use the first index to choose a row and the second to choose a column. Both start at zero.", "grid = [[3, 7], [2, 5]]\nprint(grid[0][1])", "grid = [[1, 2], [6, 8]]", "grid[1][0]", "6", ["2", "8"], "1", ["0", "2"], ["grid", "[1][0]"], "0"),
            Drill("Sealed coordinate", "Tuples", "A tuple stores a fixed sequence. Indexing and unpacking read its values without changing the tuple.", "where = (4, 7)\nx, y = where\nprint(y)", "point = (8, 3, 1)", "point[0] - point[1]", "5", ["11", "7"], "-", ["+", "*"], ["point[0]", " - point[1]"], "+"),
            Drill("Path reversal", "Reversed iterators", "reversed() visits a sequence from last to first. join() can make those visited characters into a new call sign.", "print(list(reversed([3, 8])))", "path = 'NES'", "''.join(reversed(path))", "SEN", ["NES", "ENS"], "reversed", ["sorted", "list"], ["''.join(reversed(", "path", "))"], "sorted")
        ]),
        station(15, "Signal Clinic", "Errors, assertions & tests", "Signal Medic", "cross.case.fill", "Signal Clinic here. Let's find out what happens at the edge.", [
            Drill("Bad reading", "Handling ValueError", "int() raises ValueError when text is not a valid integer. An except block can supply a fallback reading.", "try:\n    n = int('rain')\nexcept ValueError:\n    n = 0\nprint(n)", "try:\n    n = int('fog')\nexcept ValueError:\n    n = 6", "n * 2", "12", ["8", "4"], "*", ["+", "-"], ["n", " * 2"], "+"),
            Drill("Dry reservoir", "Division by zero", "ZeroDivisionError signals division by zero. Catch that specific error and record a missing reading.", "try:\n    ratio = 4 / 0\nexcept ZeroDivisionError:\n    ratio = 'missing'\nprint(ratio)", "try:\n    rate = 8 / 0\nexcept ZeroDivisionError:\n    rate = None", "rate is None", "True", ["False", "0"], "is", ["is not", "in"], ["rate", " is None"], "is not"),
            Drill("Missing station", "Handling KeyError", "A missing dictionary key raises KeyError. The handler can use a known station instead.", "try:\n    x = {}['camp']\nexcept KeyError:\n    x = 'unknown'\nprint(x)", "freq = {'oak': 4}\ntry:\n    f = freq['fir']\nexcept KeyError:\n    f = freq['oak']", "f + 1", "5", ["4", "1"], "+", ["*", "-"], ["f", " + 1"], "*"),
            Drill("Beacon invariant", "Assertions", "assert checks a condition. When the condition is true execution continues to the next line.", "signal = 4\nassert signal > 0\nprint(signal)", "pings = [2, 4]\nassert len(pings) == 2", "sum(pings)", "6", ["4", "2"], "sum", ["len", "max"], ["sum(", "pings", ")"], "len"),
            Drill("Boundary probe", "Boundary testing", "Test values just below and exactly at a boundary. These reveal whether the function includes the cutoff.", "def open_gate(n):\n    return n >= 3\nprint(open_gate(2), open_gate(3))", "def admit(age):\n    return age >= 5", "[admit(4), admit(5)]", "[False, True]", ["[True, True]", "[False, False]"], "5", ["3", "2"], ["[admit(", "4", "), admit(5)]"], "3"),
            Drill("Match the result", "Expected versus actual", "A regression test compares a computed result with a known expectation. Equality produces a Boolean result.", "actual = 2 * 4\nexpected = 8\nprint(actual == expected)", "def fee(n):\n    return n * 3 + 2\nexpected = 11", "fee(3) == expected", "True", ["False", "11"], "==", ["!=", "<"], ["fee(3) == ", "expected"], "!="),
            Drill("Every check", "Testing many cases", "all() returns True only if each check is true. A single failing case makes the group fail.", "print(all([True, True, False]))", "checks = [2 + 2 == 4, 3 * 3 == 8]", "all(checks)", "False", ["True", "2"], "all", ["any", "len"], ["all(", "checks", ")"], "any")
        ]),
        station(16, "Aurora Observatory", "Algorithm missions & final relay", "Aurora Operator", "sparkles", "Aurora Observatory is listening. Time to put your skills together.", [
            Drill("Frequency ledger", "Frequency counting", "get(key, 0) supplies the starting count for a new call sign. Add one on every visit to build a frequency table.", "freq = {}\nfor c in 'AAB':\n    freq[c] = freq.get(c, 0) + 1\nprint(freq)", "counts = {}\nfor tag in 'ABACA':\n    counts[tag] = counts.get(tag, 0) + 1", "counts['A']", "3", ["1", "5"], "'A'", ["'B'", "'C'"], ["counts", "['A']"], "'B'"),
            Drill("Even signals", "Modulo filtering", "A number divisible by two has remainder zero. Filter the readings before adding their strengths.", "print([n for n in [3, 6, 7] if n % 2 == 0])", "values = [2, 5, 8, 3]", "sum(n for n in values if n % 2 == 0)", "10", ["18", "8"], "%", ["//", "*"], ["sum(n for n in ", "values", " if n % 2 == 0)"], "//"),
            Drill("Window watch", "Sliding windows", "To move a two-sample window one step, subtract its oldest reading and add the entering reading.", "a = [3, 5, 2]\nfirst = a[0] + a[1]\nprint(first - a[0] + a[2])", "v = [2, 4, 7]\nwindow = v[0] + v[1]", "window - v[0] + v[2]", "11", ["13", "6"], "-", ["+", "*"], ["window", " - v[0] + v[2]"], "+"),
            Drill("Altitude gain", "Adjacent differences", "zip a sequence with its tail to visit neighboring pairs. Only uphill differences add to the total climb.", "heights = [1, 5, 3]\nfor a, b in zip(heights, heights[1:]):\n    print(b - a)", "h = [2, 5, 4, 8]\npairs = zip(h, h[1:])", "sum(b - a for a, b in pairs if b > a)", "7", ["6", "4"], ">", ["<", "=="], ["sum(b - a for a, b in ", "pairs", " if b > a)"], "<"),
            Drill("Relay recursion", "Recursive calls", "A base case stops recursion. For a positive n, add n to the total for the smaller input n - 1.", "def down(n):\n    if n == 0:\n        return 0\n    return 1 + down(n - 1)\nprint(down(2))", "def climb(n):\n    if n == 0:\n        return 0\n    return n + climb(n - 1)", "climb(4)", "10", ["6", "24"], "4", ["3", "5"], ["climb", "(4)"], "3"),
            Drill("Signal checksum", "Checksums", "Add all packet values and keep the remainder modulo ten. This makes a one-digit check value for the transmission.", "print(sum([4, 9, 2]) % 10)", "packet = [12, 7, 9]", "sum(packet) % 10", "8", ["2", "28"], "%", ["//", "+"], ["sum(", "packet", ") % 10"], "//"),
            Drill("The hundredth signal", "Final broadcast", "Combine filtering, a dictionary accumulator and a threshold check. Ignore weak packets, then count the stations with at least two strong packets.", "counts = {'Base': 3, 'Hill': 1}\nready = [s for s in counts if counts[s] >= 2]\nprint(ready)", "packets = [('Pine', 8), ('Ash', 3), ('Pine', 7), ('Ash', 9)]\nhits = {}\nfor name, power in packets:\n    if power >= 7:\n        hits[name] = hits.get(name, 0) + 1", "sum(n >= 2 for n in hits.values())", "1", ["2", "3"], ">=", [">", "<="], ["sum(n >= 2 for n in ", "hits", ".values())"], ">")
        ])
    ]
    static let missions = routes.flatMap(\.missions)
    static func number(of mission: Mission) -> Int { missions.firstIndex { $0.id == mission.id }! + 1 }

    private static func station(_ id: Int, _ name: String, _ skill: String, _ patch: String, _ symbol: String, _ dispatch: String, _ drills: [Drill]) -> Route {
        let firstLevel = 10 + (id - 4) * 7
        return Route(id: id, name: name, skill: skill, patch: patch, symbol: symbol,
                     missions: drills.enumerated().map { offset, drill in drill.mission(number: firstLevel + offset, dispatch: dispatch) })
    }

    static func route(for mission: Mission) -> Route { routes.first { $0.missions.contains { $0.id == mission.id } }! }
}
