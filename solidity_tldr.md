## solidity tl;dr

<br>

#### ✨ *a smart contract is a collection of code (functions) and data (state) on the ethereum blockchain.*

<br>


----

### the evm

<br>

* the evm is a stack machine (not a register machine), so that all computations are performed on the stack data area.
* the stack has a maximum size of `1024` elements and contains words of `256` bits.
* access to the stack is limited to the top end (topmost 16 elements to the top of the stack)


<br>

----

### gas

<br>

* gas is a unit of computation. each transaction is charged with some gas that has to be paid for by the originator (`tx.origin`).
* gas spent is the total amount of gas used in a transaction. if the gas is used up at any point, an out-of-gas exception is triggered, ending execution and reverting all modifications made to the state in the current call frame.
* since each block has a maximum amount of gas, it also limits the amount of work needed to validate a block.
* gas price is how much ether you are willing to pay for gas. it's set by the originator of the transaction, who has to pay `gas_price * gas` upfront to the EVM executor. any gas left is refunded to the transaction originator. exceptions that revert changes do not refund gas.
* there are two upper bounds for the amount of gas you can spend:
	- gas limit: max amount of gas you are willing to use for your transaction, set by you.
 	- block gas limit: max amount of gas allowed in a block, set by the network.   

<br>


---

### accounts

<br>

* until [account abstraction](https://github.com/go-outside-labs/mev-toolkit/tree/main/MEV_by_chains/MEV_on_Ethereum/account_abstraction) becomes a thing, there are two types of accounts in ethereum: **external accounts** (controlled by a pub-priv key pair and with empty code and storage) and **contract accounts** (controlled by code stored with the account and containing bytecode).
* these accounts are identified by:
	* an address of **160-bit length** (rightmost 20 bytes of the **keccak hash** of the RLP encoding of the structure with the sender and the nonce)
 	* a **balance**: in wei, where `1 ether` = `10**18 wei`
  	* a **nonce**: number of transactions made by the account
  	* a **bytecode**: merkle root hash of the entire state tree
  	* **stored data**: a key-value mapping 256-bit words to 256-bit words (i.e., keccak hash of the root node of the storage trie)

<br>

<img width="500" src="https://user-images.githubusercontent.com/1130416/219830838-01ce01c8-e818-403e-8a7a-2dbcff68a7bc.png">

<br>


##### what is considered modifying state

- writing to state variables
- emitting events
- creating other contracts
- sending ether via calls
- using selfdestruct
- using low-level calls
- calling any function not marked `view` or `pure`
- using inline assembly that contains certain opcodes

<br>

----

### transactions

<br>

* as a blockchain is a globally shared transactional database, a transaction is a message that is sent from one account to another.
* anyone can create a transaction to change something in this database.
* a transaction is always cryptographically signed by the sender (creator).
* it can include binary data (payload) and ether.
* if the target account contains code, that code is executed and the payload is provided as input data.
* if the target account is not set (e.g., the transaction does not have a recipient or the recipient is set to `null`), the transaction creates a new contract. the adddres of that contract is not the zero address, but an address derived from the sender and its nonce.
* the output data of this execution is stored as the code contract, i.e., to create a contract, you don't send the actual code of the contract, but instead a code that returns the code when executed.

<br>

----

### contract creation (`CREATE`)

<br>

* the **creation of a contract** is a transaction where the **receiver address is empty** and its **data field contains compiled bytecode** (or calling `CREATE` opcode).
* the data sent is executed as bytecode, initializing the state variables in storage and determining the body of the contract being created.
* **contract memory** is a byte array, where data can be stored in `32 bytes (256 bit)` or `1 byte (8 bit)` chunks, reading in `32 bytes` chunks (through `MSTORE`, `MLOAD`, `MSTORE8`).

<br>

<img width="400" src="https://user-images.githubusercontent.com/1130416/219829883-c94c0a80-1101-462e-99fa-afbf7feb2b57.png">


<br>

----

### message calls (`CALL`)

<br>

* contracts can call other contracts or send ether to non-contract accounts by through **message calls** (`CALL` opcode).
* they are similar to transactions, having a source, a target, data payload, ether, gas, and return data.
* every transaction is actually a top-level message call which can create further messages calls.
* a contract can decide how much of its remaining gas should be sent with the inner message call and how much it wants to retain.
* every call has a **sender**, a **recipient**, a **payload** (data), a **value** (in wei), and some **gas**.
* message calls are limited to a depth of `1024`, which means that for more complex operations, loops should be preferred over recursive calls.

<br>

----

### delegate call (`DELEGATECALL`)

<br>

* a variant is `DELEGATECALL`, where target code is executed within the context (address) of the calling contract, i.e., `msg.sender` and `msg.value` do not change.
* the contract can dynamically load code (storage) from a different address at runtime, while current address and balance still refer to the calling contract.
* when a contract is being created, the code is still empty. therefore, you should not call back into the contract under construction until the constuctor has finished executing.


<br>

------

### predefined global variables and opcodes

<br>

* when a contract is executed in the EVM, it has access to a small set of global objects: `block`, `msg`, and `tx` objects.
* in addition, solidity exposes a [number of EVM opcodes](https://ethereum.org/en/developers/docs/evm/opcodes/) as predefined functions.
* all instructions operate on the basic data type, `256-bit` words or on slices of memory (and other byte arrays).
* the usual arithmetic, bit, logical, and comparison operations are present, and conditional and unconditional jumps are possible.


<br>

##### msg

* `msg` is a special global variable that contains properties that allow access to the blockchain:
	* `msg object`: the transaction that triggered the execution of the contract.
	* `msg.sender`: sender address of the transaction (i.e., always the address where the current function call come from).
	* `msg.value`: ether sent with this call (in wei).
	* `msg.data`: data payload of this call into our contract.
	* `msg.sig`: first four bytes of the data payload, which is the function selector.

<br>

##### tx

* `tx.gasprice`: gas price in the calling transaction.
* `tx.origin`: address of the originating EOA for this transaction. WARNING: unsafe!

<br>

##### block

* `block.coinbase`: address of the recipient of the current block's fees and block reward.
* `block.gaslimit`: maximum amount of gas that can be spent across all transactions included in the current block.
* `block.number`: current block number (blockchain height).
* `block.timestamp`: timestamp placed in the current block by the miner (number of seconds since the Unix epoch
* `block.chainid`


<br>

##### address

* a state variable can be declared as the type `address`, a 160-bit value that does not allow arithmetic operations.
* here are its atrributes:
	* `address.balance`: balance of the address, in wei. 
	* `address.transfer(__amount__)`: transfers the amount (in wei) to this address, throwing an exception on any error.
	* `address.send(__amount__)`: similar to transfer, only instead of throwing an exception, it returns false on error. WARNING: always check the return value of send.
	* `address.call(__payload__)`: low-level `CALL` function—can construct an arbitrary message call with a data payload. Returns false on error. WARNING: unsafe.
	* `address.delegatecall(__payload__)`: low-level `DELEGATECALL` function, like `callcode(...)` but with the full msg context seen by the current contract. Returns false on error. WARNING: advanced use only!


<br>

##### built-in functions

* `addmod`, `mulmod`: for modulo addition and multiplication. for example, `addmod(x,y,k)` calculates `(x + y) % k`.
* `keccak256`, `sha256`, `sha3`, `ripemd160`: calculate hashes with various standard hash algorithms.
* `ecrecover`: recovers the address used to sign a message from the signature.
* `selfdestruct(__recipient_address__)`: deletes the current contract, sending any remaining ether in the account to the recipient address (it's the only way to remove code from the blockchain, which can be via delegatecall or callcode). the `SELFDESTRUCT` opcode is going deprecated/under changes.
* `this`: address of the currently executing contract account.
* [list of precompiled contracts](https://www.evm.codes/precompiled?fork=arrowGlacier)


<br>

---

### solidity vs. other languages

<br>

* from python, we get: 
	- modifiers
	- multiple inheritances

* from js we get:
	- function-level scoping
	- the `var` keyword

* from c/c++ we get:
	- scoping: variables are visible from the point right after their declaration until the end of the smallest {}-block that contains the declaration.
	- the good ol' value types (passed by value, so they are always copied to the stack) and reference types (references to the same underlying variable).
	- however, a variable that is declared will have an initial default value whose byte-representation is all zeros.
	- int and uint integers, with `uint8` to `uint256` in step of `8`.

* from being statically-typed:
	- the type of each variable (local and state) needs to be specified at compile-time (as opposed to runtime).

<br>

* you start files with the `SPDX License Identifier (`// SPDX-License-Identifier: MIT`)`.
* SPDX stands for software package data exchange.
* the compiler will include this in the bytecode metadata and make it machine readable.

<br>

---

### pragmas

<br>


* **pragmas** directives are used to enable certain compiler features and checks. 
* version Pragma indicates the specific solidity compiler version.
* it does not change the version of the compiler, though. you will get an error if it does not match the compiler.
* the best-practices for layout in a contract are:

```
	1. state variables
	2. events
	3. modifiers
	4. constructors
	5. functions
```

<br>

----

### natspec comments

<br>

* **natspec comments**, also known as the "ethereum natural language specification format".
* written as triple slashes (`///`) or double asterisk block.
`(/**...*/)`, directly above function declarations or statements to generate documentation in `JSON` format for developers and end-users.
* these are some tags:
	* `@title`: describe the contract/interface
	* `@author`
	* `@notice`: explain to an end user what it does
	* `@dev`: explain to a dev 
	* `@param`: document params
	* `@return`: any returned variable
	* `@inheritdoc`: copies missing tags from the base function (must be followed by contract name)
	* `@custom`: anything application-defined



<br>

----

### events

<br>

* **events** are an abstraction on top of EVM's logging, allowing clients to react to specific contract changes.
* emitting events cause the arguments to be stored in the transaction's log (which are associated with the address of the contract).
* contracts cannot access log data after it has been created, but they can be efficiently accessed from outside the blockchain (e.g., through bloom filters).
* some use cases for events are: listening for events adn updating user interface or a cheap form of storage.
* events are especially useful for light clients and DApp services, which can "watch" for specific events and report them to the user interface, or make a change in the state of the application to reflect an event in an underlying contract.
* events are created with `event` and emitted with `emit`. for example, an example can be created with:

```
event Sent(address from, address to, uint amount);
```

and then, be emitted with:

```
emit Sent(msg.sender, receiver, amount)
```


<br>

---

### type of variables

<br>

* there are 3 types of variables in solidity:
	* local: declared inside a function and not stored on the blockchain.
 	* state: declared outside a function and stored on the blockchain (`public`).
  	* global: provides information about the blockchain (e.g., `block.timestamp` or `msg.sender`). 

* in terms of the location of the data, variables are declared as either:
	* storage: variable is a state variable (store on blockchain).
 	* memory: variable is in memory and it exists while a function is being called.
  	* calldata: special data location that contains function arguments
 
<br>

```
contract DataLocations {
    uint[] public arr;
    mapping(uint => address) map;
    struct MyStruct {
        uint foo;
    }
    mapping(uint => MyStruct) myStructs;

    function f() public {
        // call _f with state variables
        _f(arr, map, myStructs[1]);

        // get a struct from a mapping
        MyStruct storage myStruct = myStructs[1];
        // create a struct in memory
        MyStruct memory myMemStruct = MyStruct(0);
    }

    function _f(
        uint[] storage _arr,
        mapping(uint => address) storage _map,
        MyStruct storage _myStruct
    ) internal {
        // do something with storage variables
    }

    // You can return memory variables
    function g(uint[] memory _arr) public returns (uint[] memory) {
        // do something with memory array
    }

    function h(uint[] calldata _arr) external {
        // do something with calldata array
    }
}
```

<br>

####  uint 

* `uint` stands for unsigned integer, meaning non negative integers
* different sizes are available:
	* `uint8` ranges from `0 to 2 ** 8 - 1`
  	* `uint16` ranges from `0 to 2 ** 16 - 1`
	* `uint256` ranges from `0 to 2 ** 256 - 1`


<br>

#### address types

* `address` holds a `20 byte` value (the size of an ethereum address).
* they can be payable, i.e., with additional members transfer and send. address payable is an address you can send ether to (while plain address not).
* explicit conversion from address to address payable can be done with `payable()`.
* explicit conversion from or to address is allowed for `uint160`, integer literals, `byte20`, and contract types.
* the members of address type are: `.balance`, `.code`, `.codehash`, `.transfer`, `.send`, `.call`, `.delegatecall`, `.staticcall`.

<br>

#### arrays and byte arrays

* they can be two types: **fixed-sized arrays** and **dynamically-sized arrays**.

```
contract Array {
    // Several ways to initialize an array
    uint[] public arr;
    uint[] public arr2 = [1, 2, 3];
    // Fixed sized array, all elements initialize to 0
    uint[10] public myFixedSizeArr;

    function get(uint i) public view returns (uint) {
        return arr[i];
    }

    // Solidity can return the entire array.
    // But this function should be avoided for
    // arrays that can grow indefinitely in length.
    function getArr() public view returns (uint[] memory) {
        return arr;
    }

    function push(uint i) public {
        // Append to array
        // This will increase the array length by 1.
        arr.push(i);
    }

    function pop() public {
        // Remove last element from array
        // This will decrease the array length by 1
        arr.pop();
    }

    function getLength() public view returns (uint) {
        return arr.length;
    }

    function remove(uint index) public {
        // Delete does not change the array length.
        // It resets the value at index to it's default value,
        // in this case 0
        delete arr[index];
    }

    function examples() external {
        // create array in memory, only fixed size can be created
        uint[] memory a = new uint[](5);
    }
}
```

* the data type `byte` represents a sequence of bytes.
* `bytes1`, `bytes2`, `bytes3`, ... `bytes32` hold a sequence of bytes from one to up to `32`.
* the type `byte[]` is an array of bytes that due to padding rules, wastes `31 bytes` of space for each element, therefore it's better to use `bytes()`.

```
bytes1 a = 0xb5; //  [10110101]
bytes1 b = 0x56; //  [01010110]
```


<br>

#### state variables

* variables that can be accessed by all functions of the contract and values are permanently stored in the contract storage.

```
contract SimpleStorage {
    // State variable
    uint public num;

    // You need to send a transaction to write to a state variable
    function set(uint _num) public {
        num = _num;
    }

    // You can read from a state variable without sending a transaction
    function get() public view returns (uint) {
        return num;
    }
}
```

<br>

* **state visibility specifiers** define how the methods will be accessed:
	- `public`: any contract and account can call.
	- `external`: only other contracts and accounts can call. an external function `func` cannot be called internally: `func()` does not work but `this.func()` does.
	- `internal`: can only be accessed internally from within the current contracts (or contracts deriving from it with `internal` function).
	- `private`: can only be accessed from the contract where the fucncion is defined (not in derived contracts).
	- `pure`: neither reads nor writes any variables in storage. It can only operate on arguments and return data, without reference to any stored data. pure functions are intended to encourage declarative-style programming without side effects or state.
	- `payable`: can accept incoming payments. Functions not declared as payable will reject incoming payments. There are two exceptions, due to design decisions in the EVM: coinbase payments and `SELFDESTRUCT` inheritance will be paid even if the fallback function is not declared as payable.
* state variables can be declared as `public`, `private`, or `internal`, but not `external`.

<br>

```
contract Base {
    // Private function can only be called
    // - inside this contract
    // Contracts that inherit this contract cannot call this function.
    function privateFunc() private pure returns (string memory) {
        return "private function called";
    }

    function testPrivateFunc() public pure returns (string memory) {
        return privateFunc();
    }

    // Internal function can be called
    // - inside this contract
    // - inside contracts that inherit this contract
    function internalFunc() internal pure returns (string memory) {
        return "internal function called";
    }

    function testInternalFunc() public pure virtual returns (string memory) {
        return internalFunc();
    }

    // Public functions can be called
    // - inside this contract
    // - inside contracts that inherit this contract
    // - by other contracts and accounts
    function publicFunc() public pure returns (string memory) {
        return "public function called";
    }

    // External functions can only be called
    // - by other contracts and accounts
    function externalFunc() external pure returns (string memory) {
        return "external function called";
    }

    // This function will not compile since we're trying to call
    // an external function here.
    // function testExternalFunc() public pure returns (string memory) {
    //     return externalFunc();
    // }

    // State variables
    string private privateVar = "my private variable";
    string internal internalVar = "my internal variable";
    string public publicVar = "my public variable";
    // State variables cannot be external so this code won't compile.
    // string external externalVar = "my external variable";
}

contract Child is Base {
    // Inherited contracts do not have access to private functions
    // and state variables.
    // function testPrivateFunc() public pure returns (string memory) {
    //     return privateFunc();
    // }

    // Internal function call be called inside child contracts.
    function testInternalFunc() public pure override returns (string memory) {
        return internalFunc();
    }
}
```

<br>

#### enum

<br>

* enumerables are usefyl to model choice and keep track of a state.
* they can be declared outside of a contract.

<br>

```
contract Enum {
    enum Status {
        Pending,
        Shipped,
        Accepted,
        Rejected,
        Canceled
    }

    // Default value is the first element listed in
    // definition of the type, in this case "Pending"
    Status public status;

    function get() public view returns (Status) {
        return status;
    }

    // Update status by passing uint into input
    function set(Status _status) public {
        status = _status;
    }

    // You can update to a specific enum like this
    function cancel() public {
        status = Status.Canceled;
    }

    // delete resets the enum to its first value, 0
    function reset() public {
        delete status;
    }
}
```

<br>



#### structs

<br>

* you can define your own type by creating a `struct`, and they are usful for grouping together related data.
* structs can be declared outside of a contract and imported in another contract.

```
contract Todos {
    struct Todo {
        string text;
        bool completed;
    }

    // An array of 'Todo' structs
    Todo[] public todos;

    function create(string calldata _text) public {
        // 3 ways to initialize a struct:

        // 1. calling it like a function
        todos.push(Todo(_text, false));

        // 2. key value mapping
        todos.push(Todo({text: _text, completed: false}));

        // 3. initialize an empty struct and then update it
        Todo memory todo;
        todo.text = _text;
        // todo.completed initialized to false

        todos.push(todo);
    }

    // Solidity automatically created a getter for 'todos' so
    // you don't actually need this function.
    function get(uint _index) public view returns (string memory text, bool completed) {
        Todo storage todo = todos[_index];
        return (todo.text, todo.completed);
    }

    // update text
    function updateText(uint _index, string calldata _text) public {
        Todo storage todo = todos[_index];
        todo.text = _text;
    }

    // update completed
    function toggleCompleted(uint _index) public {
        Todo storage todo = todos[_index];
        todo.completed = !todo.completed;
    }
}
```

<br>

#### immutability

* state variables can be declared as constant or immutable, so they cannot be modified after the contract has been constructed.
	* for **constant variables**, the value is fixed at compile-time.
 	* for **immutable variables**, the value can still be assigned at construction time (in the constructor or point of declaration).
	* for **constant variables**, the expression assigned is copied to all the places, and re-evaluated each time (local optimizations are possible).
 	* for **immutable variables**, the expression is evaluated once at constriction time and their value is copied to all the places in the code they are accessed, on a reserved `32 bytes`, becoming usually more expensive than constant.
* example:

```
contract Immutable {

    address public immutable MY_ADDRESS;
    uint public immutable MY_UINT;

    constructor(uint _someUint) {
        MY_ADDRESS = msg.sender;
        MY_UINT = _someUint;
    }

}
```

<br>

---

### functions

<br>

#### functions modifiers

* used to change the behavior of functions in a declarative way, so that the function's control flow continues after the "_" in the preceding modifier. 
* the underscore followed by a semicolon is a placeholder that is replaced by the code of the function that is being modified. the modifier is "wrapped around" the modified function, placing its code in the location identified by the underscore character.
* to apply a modifier, you add its name to the function declaration.
* more than one modifier can be applied to a function; they are applied in the sequence they are declared, as a space-separated list.

```
function destroy() public onlyOwner {
```


<br>

#### function mutability specifiers

* getter functions can be declared `view` or `pure:
	* `view` functions declares that no state will be changed.
		* they can read the contract state but not modify it.
	 	* they are enforced at runtime via `STATICALL` opcode.
	* `pure` functions declares that no state variable can be changed or read.
		* they can neither read a contract nor modify it.
* only `view` can be enforced at the EVM level, not `pure`.

<br>

#### overloading

* a contract can have multiple functions of the same name but with different parameter types.
* they are matched by the arguments supplied in the function call.


<br>

---

### data structures

<br>

- `structs` are custom-defined types that can group several variables of same/different types together to create a custom data structure.
- `enums` are used to create custom types with a finite set of constants values. they cannot have more than 256 members.

<br>

#### constructors

* a constructor is an optional function that only run when the contract is created (it cannot be called afterwards).
* a global variable can be the assigned to the contractor creator by attributing `msg.sender` to it.
* when a contract is created, the function with **constructor** is executed once and then the final code of the contract is stored on the blockchain (all public and external functions, but not the constructor code or internal functions called by it).

<br>

```
// Base contract X
contract X {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }
}

// Base contract Y
contract Y {
    string public text;

    constructor(string memory _text) {
        text = _text;
    }
}

// There are 2 ways to initialize parent contract with parameters.

// Pass the parameters here in the inheritance list.
contract B is X("Input to X"), Y("Input to Y") {

}

contract C is X, Y {
    // Pass the parameters here in the constructor,
    // similar to function modifiers.
    constructor(string memory _name, string memory _text) X(_name) Y(_text) {}
}

// Parent constructors are always called in the order of inheritance
// regardless of the order of parent contracts listed in the
// constructor of the child contract.

// Order of constructors called:
// 1. X
// 2. Y
// 3. D
contract D is X, Y {
    constructor() X("X was called") Y("Y was called") {}
}

// Order of constructors called:
// 1. X
// 2. Y
// 3. E
contract E is X, Y {
    constructor() Y("Y was called") X("X was called") {}
}
```

<br>

#### receive function

* a contract can have ONE **receive** function (`receive() external payable {...}`, without the function keyword, and no arguments and no return).
* the `external` and `payable` are the function on where ether is transfered via `send()` or `transfer()`.
* receive is executed on a call to the contract with empty calldata.
* receive might only rely on 2300 gas being available.
* a contract without receive can still receive ether as a recipient of a coinbase transaction (miner block reward) or as a destination of `selfdestruct` (a contract cannot react to this ether transfer).

<br>

#### falback function

 in the same idea, a contract can have ONE *fallback* function, which must have external visibility.
* fallback is executed on a call to the contract if none of the other functions match the given function signature or no data was supplied and there is not received Ether function.

<br>

#### transfer

* the transfer function fails if the balance of the contract is not enough or if the transfer is rejected by the receiving account.

<br>

#### send

* low-level counterpart of transfer. if the execution fails, then send returns false.
* the return value must be checked by the caller.

<br>

----

### data management

<br>

* the evm manages different kinds of data depending on their context.

<br>

#### stack

* the evm operates on a virtual stack, which has a maximum size of `1024`.
* stack items have a size of `256 bits` (the evm is a `256-bit` word machine, which facilitates keccak256 hash scheme and elliptic-curve).
* the opcodes to modify the stack are:
	* `POP` (remove from stack),
	* `PUSH n` (places the `n` bytes item into the stack),
 	* `DUP n` (duplicates the `n`th stack item),
  	* `SWAP n` (exchanges the first and the `n`th stack item).


<br>

#### calldata

* a called contract receive a freshly cleared instance of memory and has access to the call payload, provided in a separated area called the **calldata**.
* after it finishes execution, it can return data which will be stored at a location in the caller's memory preallocated by the caller.
* opcodes include: `CALLDATASIZE` (get size of tx data), `CALLDATALOAD` (loads 32 byte of tx data onto the stack), `CALLDATACOPY` (copies the number of bytes of the tx data to memory).
* there are also the inline assembly versions: `calldatasize`, `calldataload`, calldatacopy`.
* they can be called through:

```
assembly {
(...)
}
```

<br>

#### storage

* persistent read-write word-addressable space for contracts, addressed by words.
* storage a key-value mapping of `2**256 `slots of 32 bytes each.
* gas to save data into storage is one of the highest operations.
* the evm opcodes are: `SLOAD` (loads a word from storage to stack), `SSTORE` (saves a word to storage).
* it's costly to read, initialise, and modify storage.
* a contract cannot read or write to any storage apart from its own.

<br>

#### type of storages

* bitpack loading: storing multiple variables in a single `32-bytes` slot by ordering the byte size.
* fixed-length arrays: takes a predetermined amount of slots.
* dynamic-length arrays: new elements assign slots after deployment (handled by the evm with keccak256 hashing).
* mappings: dynamic type with key hashes.
	* for example, `mapping(address => int)` maps unsigned integers.
 	* the key type can be any built-in value type, bytes, string, or any contract.
  	* value type can be any type including another mapping or an array.
  	* mapping are not iterable: it's not possible to obtain a list of all keys of a mapping, nor a list of all values.
  	* maps cannot be used for functions input or output.


<br>

```
contract Mapping {
    // Mapping from address to uint
    mapping(address => uint) public myMap;

    function get(address _addr) public view returns (uint) {
        // Mapping always returns a value.
        // If the value was never set, it will return the default value.
        return myMap[_addr];
    }

    function set(address _addr, uint _i) public {
        // Update the value at this address
        myMap[_addr] = _i;
    }

    function remove(address _addr) public {
        // Reset the value to the default value.
        delete myMap[_addr];
    }
}
```

<br>


#### memory

* the second data area of which a contract obtains a cleared instance for each message call.
* memory is linear and can be addressed at the byte level.
* reads are limited to a width of `256 bit`s, while writes can be either `8 bits` or `256 bits` wide.
* memory is expanded by a word (`256-bit`), when accessing (either reading or writing) a previously untouched memory.
* at the time of expansion, the cost in gas must be paid - memory is more costly the large it grows, scaling quadratically.
* volatile read-write byte-addressable space (store data during execution) initialized as zero.
* the evm opcodes are `MLOAD` (loads a word into the stack), `MSTORE` (saves a word to memory), `MSTORE8` (saves a byte to memory).
* gas costs for memory loads (`MLOADs`) are significantly cheaper in gas than `SLOADs`.

<br>

----

### calling another contract

<br>

#### call / delegatecall/ staticall

* used to interface with contracts that do not adhere to ABI, or to give more direct control over encoding.
* they all take a single bytes memory parameter and return the success condition (as a bool) and the return data (byte memory).
* with `DELEGATECALL`, only the code of the given address is used but all other aspects are taken from the current contract. the purpose is to use logic code that is stored in the callee contract but operates on the state of the caller contract.
* with `STATCALL`, the execution will revert if the called function modifies the state in any way.

<br>


#### creating a new instance

* the safest way to call another contract is if you create that other contract yourself. 
* to do this, you can simply instantiate it, using the keyword `new`, as in other object-oriented languages.
* this keyword will create the contract on the blockchain and return an object that you can use to reference it. 

```
contract Token is Mortal {
	Faucet _faucet;

    constructor() {
        _faucet = new Faucet();
    }
}
```

<br>

#### addressing an existing instance

* another way you can call a contract is by casting the address of an existing instance of the contract. 
* with this method, you apply a known interface to an existing instance.
* this is much riskier than the previous mechanism, because we don’t know for sure whether that address actually is a faucet object.

```
import "Faucet.sol";

contract Token is Mortal {

    Faucet _faucet;

    constructor(address _f) {
        _faucet = Faucet(_f);
        _faucet.withdraw(0.1 ether);
    }
}

```


<br>

----

### randomness

<br>

* you cannot rely on `block.timestamp` or `blockhash` as a source of randomness.

<br>

---

### ABI encoding and decoding functions

<br>

- `abi.decode`
- `abi.encode`
- `abi.encodePacked`
- `abi.encodeWithSelector`
- `abi.encodeWithSignature`

<br>

----

### error handling

<br>

* an error will undo all changes made to the state during a transaction and they are returned to the caller of the function, example:

```
error InsufficientBalance(uint requested, uint available);
```
 
* errors are used together with the `revert statement`, which unconditionally aborts and reverts all changes.
* errors can also provide information about a failed operations.
* you can throw an error by calling:
	- `assert()`: used to check for code that should never be false. causes a panic error and reverts if the condition is not met.
	- `require()`: used to validate inputs and conditions before execution. reverts if the condition is not met.
	- `revert()`: similar to rquire. abort execution and revert state changes.

<br>

```
contract Error {
    function testRequire(uint _i) public pure {
        // Require should be used to validate conditions such as:
        // - inputs
        // - conditions before execution
        // - return values from calls to other functions
        require(_i > 10, "Input must be greater than 10");
    }

    function testRevert(uint _i) public pure {
        // Revert is useful when the condition to check is complex.
        // This code does the exact same thing as the example above
        if (_i <= 10) {
            revert("Input must be greater than 10");
        }
    }

    uint public num;

    function testAssert() public view {
        // Assert should only be used to test for internal errors,
        // and to check invariants.

        // Here we assert that num is always equal to 0
        // since it is impossible to update the value of num
        assert(num == 0);
    }
```


<br>

----

### if / else

<br>

```
contract IfElse {

    function foo(uint x) public pure returns (uint) {
        if (x < 10) {
            return 0;
        } else if (x < 20) {
            return 1;
        } else {
            return 2;
        }
    }

    function ternary(uint _x) public pure returns (uint) {
        // shorthand way to write if / else statement
        // the "?" operator is called the ternary operator
        return _x < 10 ? 1 : 2;
    }
}
````

<br>

----

### for and while loops

<br>

```
contract Loop {
    function loop() public {
        // FOR LOOP
        for (uint i = 0; i < 10; i++) {
            if (i == 3) {
                // Silly example to show how to skip to next iteration
                continue;
            }
            if (i == 5) {
                // Exit loop
                break;
            }
        }

        // WHILE LOOP 
        uint j;
        while (j < 10) {
            j++;
        }
    }
}
```

<br>

---

### function modifiers

<br>

* modifiers are code that can be run before and/or after a function call.
* underscore is a special character only used inside function modifier and it tells solidity to execute the rest of the code.

<br>

#### restrict access

* check that the caller is the owner of the contract.


```
// Modifier to check that the caller is the owner of the contract.
modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
}
```

<br>

#### validate inputs

* check that the address passed is not in the zero address.

```
// Modifiers can take inputs.
// This modifier checks that the address passed in is not the zero address.
modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
}

function changeOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
}
```

<br>

#### guard against reentrancy attack

* prevents a function from being called while it's still executing.

```
// Modifiers can be called before and / or after a function.
// This modifier prevents a function from being called while it is still executing.
modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

function decrement(uint i) public noReentrancy {
        x -= i;

        if (i > 1) {
            decrement(i - 1);
        }
    }
```

<br>

----

### inheritance

<br>

* solidity supports multiple inheritance, and their order is important (i.e., list the parent contracts in the order from most base-like to most derived).
* contracts can inherit other contract by using the `is` keyword.
* function that is going to be overridden by a child contract must be declared as `virtual`.
* function that is going to override a parent function must use the keyword `override`.

<br>

```
/* Graph of inheritance
    A
   / \
  B   C
 / \ /
F  D,E

*/

contract A {
    function foo() public pure virtual returns (string memory) {
        return "A";
    }
}

// Contracts inherit other contracts by using the keyword 'is'.
contract B is A {
    // Override A.foo()
    function foo() public pure virtual override returns (string memory) {
        return "B";
    }
}

contract C is A {
    // Override A.foo()
    function foo() public pure virtual override returns (string memory) {
        return "C";
    }
}

// Contracts can inherit from multiple parent contracts.
// When a function is called that is defined multiple times in
// different contracts, parent contracts are searched from
// right to left, and in depth-first manner.

contract D is B, C {
    // D.foo() returns "C"
    // since C is the right most parent contract with function foo()
    function foo() public pure override(B, C) returns (string memory) {
        return super.foo();
    }
}

contract E is C, B {
    // E.foo() returns "B"
    // since B is the right most parent contract with function foo()
    function foo() public pure override(C, B) returns (string memory) {
        return super.foo();
    }
}

// Inheritance must be ordered from “most base-like” to “most derived”.
// Swapping the order of A and B will throw a compilation error.
contract F is A, B {
    function foo() public pure override(A, B) returns (string memory) {
        return super.foo();
    }
}
```

<br>


#### shadowing inherited state variables


* unlike functions, state variables cannot be overriden by re-declaring in the child contract.
* this is how inherited state variables can be overriden:

<br>

```
contract A {
    string public name = "Contract A";

    function getName() public view returns (string memory) {
        return name;
    }
}

// Shadowing is disallowed in Solidity 0.6
// This will not compile
// contract B is A {
//     string public name = "Contract B";
// }

contract C is A {
    // This is the correct way to override inherited state variables.
    constructor() {
        name = "Contract C";
    }

    // C.getName returns "Contract C"
}
```

<br>

#### calling parent contracts

* parent contracts can be called directly, or by using the word `super`.
* if using the keyword `super`, all of the intermediate parent contracts are called.

<br>

----





