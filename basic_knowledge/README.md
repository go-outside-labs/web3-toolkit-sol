## 👾 solidity (unstructured) tl;dr 

<br>

#### ✨ the notes below are a rough overview of solidity from when i started learning it - if you have no idea about the language, it might be a resource to skim - however, you should also check the references on the first page of this repo.

#### ✨ a smart contract is a collection of code (functions) and data (state) on the ethereum blockchain... 

<br>


----

### the evm

<br>

* the evm is a **stack machine** (not a register machine), so that all computations are performed on the stack data area.
* the stack has a maximum size of `1024` elements and contains words of `256-bits1.
* access to the stack is limited to the top end (topmost 16 elements to the top of the stack)


<br>

---

### gas

<br>

* gas is a **unit of computation**: each transaction is charged with some gas that has to be paid for by the originator.
* **gas spent** is the total amount of gas used in a transaction.
	* if the gas is used up at any point, an out-of-gas exception is triggered, ending execution and reverting all modifications made to the state in the current call frame.
* since **each block has a maximum amount of gas**, it also limits the amount of work needed to validate a block.
* **gas price** is how much ether you are willing to pay for gas.
	* it's set by the originator of the transaction, who has to pay `gas_price * gas` upfront to the EVM executor.
 	* any gas left is refunded to the transaction originator.
  	* exceptions that revert changes do not refund gas.
* there are **two upper bounds** for the amount of gas you can spend:
	- **gas limit**: max amount of gas you are willing to use for your transaction, set by you.
 	- **block gas limit**: max amount of gas allowed in a block, set by the network.   

<br>

---

### accounts

<br>

* until (**[account abstraction](https://github.com/go-outside-labs/mev-toolkit/tree/main/MEV_by_chains/MEV_on_Ethereum/account_abstraction)** becomes a thing, there are two types of accounts in ethereum: **external accounts** (controlled by a pub-priv key pair and with empty code and storage) and **contract accounts** (controlled by code stored with the account and containing bytecode).
* these accounts are identified by:
	* an address of **160-bit length** (rightmost 20 bytes of the **keccak hash** of the RLP encoding of the structure with the sender and the nonce).
 	* a **balance**: in wei, where `1 ether` = `10**18 wei`.
  	* a **nonce**: number of transactions made by the account.
  	* a **bytecode**: merkle root hash of the entire state tree.
  	* **stored data**: a key-value mapping 256-bit words to 256-bit words (*i.e.*, `keccak` hash of the root node of the storage trie).

<br>

---

### transactions

<br>

* as a blockchain is a **globally shared transactional database**, a transaction is a message that is sent from one account to another.
* anyone can create a transaction to change something in this database.
* a transaction is **always cryptographically signed by the sender (creator)**.
* a transaction can include **binary data (payload)** and **ether**.
* if the **target account contains code**, that **code is executed and the payload is provided as input data**.
* if the **target account is not set** (*e.g.*, the transaction does not have a recipient or the recipient is set to `null`), the **transaction creates a new contract**.
	* the address of a new contract is not the zero address, but an **address derived from the sender and its nonce**.
* the output data of the contract execution is stored as the code contract, *i.e.*, to create a contract, **you don't send the actual code of the contract, but instead a code that returns the code when executed**.

<br>

------

### solidity vs. other languages

<br>

* **from python, we get:** 
	- modifiers
	- multiple inheritances

* **from js we get:**
	- function-level scoping
	- the `var` keyword

* **from c/c++ we get:**
	- scoping: variables are visible from the point right after their declaration until the end of the smallest {}-block that contains the declaration.
	- the good ol' value types (passed by value, so they are always copied to the stack) and reference types (references to the same underlying variable).
	- however, a variable that is declared will have an initial default value whose byte-representation is all zeros.
	- int and uint integers, with `uint8` to `uint256` in the step of `8`.

* **from being statically-typed:**
	- the type of each variable (local and state) needs to be specified at compile-time (as opposed to runtime).

* SPDX stands for software package data exchange. the compiler will include this in the bytecode metadata and make it machine readable.

<br>

---

### best practices for layout in a contract

<br>

1. state variables
2. events
3. modifiers
4. constructors
5. functions

<br>


---

### variable scopes

<br>

* `local`, declared and used inside functions and not stored on blockchain.
* `state`, declared in the contract scope, stored on blockchain.
* `global`, accessed by all (*e.g.,* `msg.sender`, `block.timestamp`)

<br>


---

### variables location

<br>

* variables are declared as either:
	* **storage**: variable is a state variable (stored on the blockchain).
 		* solidity storage is an array of length `2^256`.
     		* each slot in the array can store 32 bytes.
       		* order of declaration and the type of state variables define which slots it will use, unless you use assembly, then you can write to any slot. 
	* **memory**: byte-array memory (RAM), used to store data during execution (such as passing arguments to internal functions). opcodes are `MSTORE`, `MLOAD`, or `MSTORE8`.
	* **calldata**: a read-only byte-addressable space for the data parameter of a transaction or call. unlike the stack, this data is accessed by specifying the exact byte offset and the number of bytes to read. 
 * the required gas for disk storage is the most expensive, while storing data to stack is the cheapest.
 
<br>

-----


### predefined global variables and opcodes

<br>

* when a contract is executed in the EVM, it has access to a small set of global objects: `block`, `msg`, and `tx` objects.
* in addition, solidity exposes a **[number of EVM opcodes](https://ethereum.org/en/developers/docs/evm/opcodes/)** as predefined functions.
* as we mentioned above, in the evm, all instructions operate on the basic data type, `256-bit` words or on slices of memory (and other byte arrays).
* the usual arithmetic, bit, logical, and comparison operations are present, and conditional and unconditional jumps are possible.
* **[list of precompiled contracts](https://www.evm.codes/precompiled?fork=arrowGlacier).**


<br>

-----

### `msg`

<br>

* `msg` is a special global variable that contains properties that allow access to the blockchain.
* `msg object`: the transaction that triggered the execution of the contract.
* `msg.sender`: sender address of the transaction (*i.e.*, always the address where the current function call come from).
* `msg.value`: ether sent with this call (in wei).
* `msg.data`: data payload of this call into our contract.
* `msg.sig`: first four bytes of the data payload, which is the function selector.

<br>

-----

### `tx`

<br>

* `tx.gasprice`: gas price in the calling transaction.
* `tx.origin`: address of the originating EOA for this transaction. WARNING: unsafe!

<br>

-----

### `block`

<br>

* `block.coinbase`:
	* address of the recipient of the current block's fees and block reward.
 	* it's `payable`. 
* `block.gaslimit`: maximum amount of gas that can be spent across all transactions included in the current block.
* `block.number`: current block number (blockchain height).
* `block.timestamp`:
	* timestamp placed in the current block by the miner (number of seconds since the Unix epoch).
* `block.chainid`


<br>

-----

### `address`

<br>

* a state variable can be declared as the type `address`, a `160-bit` value that does not allow arithmetic operations.
* `address` holds a `20 byte` value (the size of an ethereum address).
* `address payable` is an address you can send ether to (while plain address is not), and comes with additional members `transfer` and `send`.
* explicit conversion from address to address payable can be done with `payable()`.
* explicit conversion from or to address is allowed for `uint160`, integer literals, `byte20`, and contract types.
* members of address type are: 
	* `address.balance`: balance of the address, in wei. 
	* `address.transfer(__amount__)`: transfers the amount (in wei) to this address, throwing an exception on any error.
	* `address.send(__amount__)`: similar to transfer, only instead of throwing an exception, it returns false on error.
		* WARNING: always check the return value of send.
	* `address.call(__payload__)`: low-level `CALL` function—can construct an arbitrary message call with a data payload. Returns false on error.
		* WARNING: unsafe.
	* `address.delegatecall(__payload__)`: low-level `DELEGATECALL` function, like `callcode(...)` but with the full msg context seen by the current contract. Returns false on error.
		* WARNING: advanced use only!
  	* `address.code`
  	* `address.codehash`
  	* `address.staticcall`

<br>

---

### built-in functions

* `this`:
	* address of the currently executing contract account.
* `addmod`, `mulmod`:
	* for modulo addition and multiplication. for example, `addmod(x,y,k)` calculates `(x + y) % k`.
* `keccak256`, `sha256`, `sha3`, `ripemd160`:
	* calculate hashes with various standard hash algorithms.
* some `keccak256` use cases are:
	* to create a deterministic unique ID from a input, for commit-reveal schemes, for compact cryptographic signature (by signing the hash instead of a larger input).
* `ecrecover`:
	* recovers the address used to sign a message from the signature:
	* `erecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address)` and can be used to verify a signature:
		* this will return an `address` of who signed the signature.
	  	* `r` is the first 32 bytes of signature
	  	* `s` is the second 32 bytes of the signature
	  	* `v` is the final ` byte of the signature
  	* the `hash` is the hash of the message the user has signed, with this format:
```
hashToBeSuppliedToEcrecover = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n",len(_message), keccak256(_message)));
```
* `selfdestruct(__recipient_address__)`:
	* deletes the current contract, sending any remaining ether in the account to the recipient address (it's the only way to remove code from the blockchain, which can be via delegatecall or callcode).
 	* the `SELFDESTRUCT` opcode is going deprecated/under changes.


<br>

---

### pragmas

<br>

* **pragmas** directives are used to enable certain compiler features and checks. 
* `version Pragma` indicates the specific solidity compiler version.
* it does not change the version of the compiler, though (get an error if it does not match the compiler).

<br>

---

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

---

### events

<br>

* **events** are an abstraction on top of EVM's logging, allowing clients to react to specific contract changes.
* emitting events cause the arguments to be **stored in the transaction's log** (which are associated with the address of the contract).
* contracts cannot access log data after it has been created, but they can be efficiently accessed from outside the blockchain (*e.g.*, through bloom filters).
* some use cases for events are:
	* listening for events and updating user interface
 	* a cheap form of storage.
* events are especially useful for light clients and DApp services, which can "watch" for specific events and report them to the user interface, or make a change in the state of the application to reflect an event in an underlying contract.
* events are created with `event` and emitted with `emit`.
* for example, an example can be created with:

```
event Sent(address from, address to, uint amount);
```

and then, be emitted with:

```
emit Sent(msg.sender, receiver, amount)
```


<br>

---

###  uint 

<br>

* `uint` stands for unsigned integer, meaning non-negative integers.
* different sizes are available:
	* `uint8` ranges from `0 to 2 ** 8 - 1`
  	* `uint16` ranges from `0 to 2 ** 16 - 1`
	* `uint256` ranges from `0 to 2 ** 256 - 1`


<br>

---

### arrays and byte arrays

<br>

* they can be two types: **fixed-sized arrays** and **dynamically-sized arrays**.
* the data type `byte` represents a sequence of bytes.
* `bytes1`, `bytes2`, `bytes3`, ... `bytes32` hold a sequence of bytes from one to up to `32`.
* the type `byte[]` is an array of bytes that due to padding rules, wastes `31 bytes` of space for each element, therefore it's better to use `bytes()`.

<br>

```
bytes1 a = 0xb5; //  [10110101]
bytes1 b = 0x56; //  [01010110]
```

<br>


---

### state variables

<br>

* variables that can be accessed by all functions of the contract and values are **permanently stored in the contract storage.**
* state variables can be declared as `public`, `private`, or `internal`, but not `external`.

<br>

---

### what is considered modifying state

<br>

- writing to state variables.
- emitting events.
- creating other contracts.
- sending ether via calls.
- using selfdestruct.
- using low-level calls.
- calling any function not marked `view` or `pure`.
- using inline assembly that contains certain opcodes.


<br>

---

### enum

<br>

* enumerables are useful to model choice and keep track of a state.
* they are used to create custom types with a finite set of constants values.
* they cannot have more than 256 members.
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

    function cancel() public {
        status = Status.Canceled;
    }
```

<br>

---


### structs

<br>

* `structs` are custom-defined types that can group several variables of same/different types together to create a custom data structure.
* they are a type `byte` also just a template (they need to be declared somewhere else such as a mapping or somtehing to instantiate the actual variable).
* you can define your own type by creating a `struct`, and they are useful for grouping together related data.
* structs can be declared outside of a contract and imported into another contract.

<br>

```
contract Todos {
    struct Todo {
        string text;
        bool completed;
    }

    Todo[] public todos;

    function create(string calldata _text) public {
        todos.push(todo);
    }
}
```

<br>

---

### immutability

<br>

* state variables can be declared as constant or immutable, so they cannot be modified after the contract has been constructed.
	* for **constant variables**, the value is fixed at compile-time.
 	* for **immutable variables**, the value can still be assigned at construction time (in the constructor or point of declaration).
	* for **constant variables**, the expression assigned is copied to all the places, and re-evaluated each time (local optimizations are possible).
 	* for **immutable variables**, the expression is evaluated once at constriction time and their value is copied to all the places in the code they are accessed, on a reserved `32 bytes`, becoming usually more expensive than constant.
* example:

<br>

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

### functions modifiers

<br>

* used to change the behavior of functions in a declarative way, so that the function's control flow continues after the "_" in the preceding modifier. 
* the underscore followed by a semicolon is a placeholder that is replaced by the code of the function that is being modified. the modifier is "wrapped around" the modified function, placing its code in the location identified by the underscore character.
* to apply a modifier, you add its name to the function declaration.
* more than one modifier can be applied to a function; they are applied in the sequence they are declared, as a space-separated list.

```
function destroy() public onlyOwner {
```


<br>

---


### state visibility specifiers

<br>

* define how the methods will be accessed.
* `public`:
	* any contract and account can call.
* `external`:
	* only other contracts and accounts can call.
	* an external function `func` cannot be called internally: `func()` does not work but `this.func()` does.
* `internal`:
	* can only be accessed internally from within the current contracts (or contracts deriving from it with `internal` function).
* `private`:
	* can only be accessed from the contract where the function is defined (not in derived contracts).
* `payable`:
	* can accept incoming ether payments.
 	* functions not declared as payable will reject incoming payments.
  	* there are two exceptions, due to design decisions in the EVM: coinbase payments and `SELFDESTRUCT` inheritance will be paid even if the fallback function is not declared as payable.

<br>

----

### function mutability specifiers

<br>

* getter functions can be declared `view` or `pure:
	* `view` functions declares that no state will be changed.
		* they can read the contract state but not modify it.
	 	* they are enforced at runtime via `STATICALL` opcode.
	* `pure` functions declares that no state variable can be changed or read.
		* they can neither read a contract nor modify it.
  		* pure functions are intended to encourage declarative-style programming without side effects or state. 
* only `view` can be enforced at the EVM level, not `pure`.

<br>

---

### function selectors

<br>

* when a function is called, the function selector (represented by the first 4 bytes of `calldata`) specifies which functions to call.
* for instance, in the example below, `call` is used to execute `transfer` on a contract at the address `addr` and the first 4 bytes returned from `abi.encondeWithSignature()` is the function selector:

```
addr.call(abi.encodeWithSignature("transfer(address,uint256)", 0xSomeAddress, 123))
```

* you can save gas by precomputing and inline the function selector:

```
contract FunctionSelector {
    /*
    "transfer(address,uint256)"
    0xa9059cbb
    "transferFrom(address,address,uint256)"
    0x23b872dd
    */
    function getSelector(string calldata _func) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(_func)));
    }
}
```


<br>

---

### overloading

<br>

* a contract can have multiple functions of the same name but with different parameter types.
* they are matched by the arguments supplied in the function call.


<br>

---

### constructors

<br>

* a constructor is an optional function that only run when the contract is created (it cannot be called afterwards).
* a global variable can be the assigned to the contractor creator by attributing `msg.sender` to it.
* when a contract is created, the function with **constructor** is executed once and then the final code of the contract is stored on the blockchain (all public and external functions, but not the constructor code or internal functions called by it).

<br>

----

### error handling

<br>

* there are two kinds of errors that EVM can throw. `Error` and `Panic`.
* an error will undo all changes made to the state during a transaction and they are returned to the caller of the function, example:

```
error InsufficientBalance(uint requested, uint available);
```
 
* errors are used together with the `revert statement`, which unconditionally aborts and reverts all changes.
* errors can also provide information about a failed operations.
* you can throw an error by calling:
	- `assert()`: used to check for code that should never be false. causes a panic error and reverts if the condition is not met.
	- `require()`: used to validate inputs and conditions before execution. reverts if the condition is not met.
	- `revert()`: similar to require. abort execution and revert state changes.
* `try / catch` can only catch errors from external functions and contract creation.

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

----

### restricted access

<br>

* check that the caller is the owner of the contract.


```
// Modifier to check that the caller is the owner of the contract.
modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
}
```

<br>

---

### validating inputs

<br>

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

---

### guarding against reentrancy attack

<br>

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

---

### shadowing inherited state variables

<br>

* unlike functions, state variables cannot be overridden by re-declaring in the child contract.
* this is how inherited state variables can be overridden:

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

---

### calling parent contracts

<br>

* parent contracts can be called directly, or by using the word `super`.
* if using the keyword `super`, all of the intermediate parent contracts are called.

<br>


---

### interfaces

<br>

* interfaces are a way to interact with other contracts.
* they cannot have any functions implemented, declare a constructor, or declare state variables.
* they can inherit from other interfaces.
* all declared functions must be external.

```
contract Counter {
    uint public count;

    function increment() external {
        count += 1;
    }
}

interface ICounter {
    function count() external view returns (uint);

    function increment() external;
}

contract MyContract {
    function incrementCounter(address _counter) external {
        ICounter(_counter).increment();
    }

    function getCount(address _counter) external view returns (uint) {
        return ICounter(_counter).count();
    }
}

// Uniswap example
interface UniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface UniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract UniswapExample {
    address private factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function getTokenReserves() external view returns (uint, uint) {
        address pair = UniswapV2Factory(factory).getPair(dai, weth);
        (uint reserve0, uint reserve1, ) = UniswapV2Pair(pair).getReserves();
        return (reserve0, reserve1);
    }
}
```

<br>

---

### libraries

<br>

* libraries are similar to contracts, but you can't declare any state variable and can't send ether.
* a library is embedded into the contract if all library functions are internal, otherwise the library must be deployed and then linked before the contract is deployed.

<br>

---

### ABI encode and decode

<br>

* `abi.encode` encodes data into bytes.

<br>

```
interface IERC20 {
    function transfer(address, uint) external;
}

contract Token {
    function transfer(address, uint) external {}
}

contract AbiEncode {
    function test(address _contract, bytes calldata data) external {
        (bool ok, ) = _contract.call(data);
        require(ok, "call failed");
    }

    function encodeWithSignature(
        address to,
        uint amount
    ) external pure returns (bytes memory) {
        // Typo is not checked - "transfer(address, uint)"
        return abi.encodeWithSignature("transfer(address,uint256)", to, amount);
    }

    function encodeWithSelector(
        address to,
        uint amount
    ) external pure returns (bytes memory) {
        // Type is not checked - (IERC20.transfer.selector, true, amount)
        return abi.encodeWithSelector(IERC20.transfer.selector, to, amount);
    }

    function encodeCall(address to, uint amount) external pure returns (bytes memory) {
        // Typo and type errors will not compile
        return abi.encodeCall(IERC20.transfer, (to, amount));
    }
}
```

<br>

* `abi.decode` decodes bytes back into data.

<br>

```
contract AbiDecode {
    struct MyStruct {
        string name;
        uint[2] nums;
    }

    function encode(
        uint x,
        address addr,
        uint[] calldata arr,
        MyStruct calldata myStruct
    ) external pure returns (bytes memory) {
        return abi.encode(x, addr, arr, myStruct);
    }

    function decode(
        bytes calldata data
    )
        external
        pure
        returns (uint x, address addr, uint[] memory arr, MyStruct memory myStruct)
    {
        // (uint x, address addr, uint[] memory arr, MyStruct myStruct) = ...
        (x, addr, arr, myStruct) = abi.decode(data, (uint, address, uint[], MyStruct));
    }
}
```


<br>

-----

### sending and receiving ether

<br>

* you can send ether to other contracts by:
	* `transfer` (2300 gas, throws error)
 	* `send` (2300 gas, returns bool)
  	* `call` (forwards all gas or ser gas, returns bool), should be used with re-entrancy guard (i.e., by making all state changes before calling other contracts, and by using re-entrancy guard modifier)
 
* a contract receiving ether must have at least of the functions below:
	* `receive() external payable`, called if `msg.data` is empty, otherwise `fallback()` is called
 	* `fallback() external payable`
<br>

```
contract ReceiveEther {
    /*
    Which function is called, fallback() or receive()?

           send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback()
    */

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract SendEther {
    function sendViaTransfer(address payable _to) public payable {
        // This function is no longer recommended for sending Ether.
        _to.transfer(msg.value);
    }

    function sendViaSend(address payable _to) public payable {
        // Send returns a boolean value indicating success or failure.
        // This function is not recommended for sending Ether.
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send Ether");
    }

    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}
```

<br>

---

### receive function

<br>

* a contract can have ONE **receive** function (`receive() external payable {...}`, without the function keyword, and no arguments and no return).
* the `external` and `payable` are the functions on where ether is transfered via `send()` or `transfer()`.
* receive is executed on a call to the contract with empty calldata.
* receive might only rely on 2300 gas being available.
* a contract without receive can still receive ether as a recipient of a coinbase transaction (miner block reward) or as a destination of `selfdestruct` (a contract cannot react to this ether transfer).

<br>

---


### falback function

<br>

* `fallback` is a special function that is executed on a call to the contract when:
	* a function that does not exist is called (no function match the function signature).
 	* ether is sent directly to a contract but `receive()` does not exist or `msg.data` is not empty.
* a contract can have only one `fallback` function, which must have `external` visibility.
* `fallback` has 2300 gas limit when called by `transfer` or `send`.
* `fallback` can take `bytes` for input or output.


<br>

```
// TestFallbackInputOutput -> FallbackInputOutput -> Counter
contract FallbackInputOutput {
    address immutable target;

    constructor(address _target) {
        target = _target;
    }

    fallback(bytes calldata data) external payable returns (bytes memory) {
        (bool ok, bytes memory res) = target.call{value: msg.value}(data);
        require(ok, "call failed");
        return res;
    }
}

contract Counter {
    uint public count;

    function get() external view returns (uint) {
        return count;
    }

    function inc() external returns (uint) {
        count += 1;
        return count;
    }
}

contract TestFallbackInputOutput {
    event Log(bytes res);

    function test(address _fallback, bytes calldata data) external {
        (bool ok, bytes memory res) = _fallback.call(data);
        require(ok, "call failed");
        emit Log(res);
    }

    function getTestData() external pure returns (bytes memory, bytes memory) {
        return (abi.encodeCall(Counter.get, ()), abi.encodeCall(Counter.inc, ()));
    }
}
```


<br>

---

### transfer() function

<br>

* the transfer function fails if the balance of the contract is not enough or if the transfer is rejected by the receiving account.

<br>

---

### send() function

<br>

* low-level counterpart of transfer. if the execution fails, then send returns false.
* the return value must be checked by the caller.

<br>

----

### data management

<br>

* the evm manages different kinds of data depending on their context.

<br>

----

### stack

<br>

* the evm operates on a virtual stack, which has a maximum size of `1024`.
* stack items have a size of `256 bits` (the evm is a `256-bit` word machine, which facilitates keccak256 hash scheme and elliptic-curve).
* the opcodes to modify the stack are:
	* `POP` (remove from stack),
	* `PUSH n` (places the `n` bytes item into the stack),
 	* `DUP n` (duplicates the `n`th stack item),
  	* `SWAP n` (exchanges the first and the `n`th stack item).


<br>


---

### calldata

<br>

* a called contract receive a freshly cleared instance of memory and has access to the call payload, provided in a separate area called the **calldata**.
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

---

### storage

<br>

* persistent read-write word-addressable space for contracts, addressed by words.
* storage a key-value mapping of `2**256 `slots of `32-bytes` each.
* gas to save data into storage is one of the highest operations.
* the evm opcodes are: `SLOAD` (loads a word from storage to stack), `SSTORE` (saves a word to storage).
* it's costly to read, initialise, and modify storage.
* a contract cannot read or write to any storage apart from its own.

<br>

---

### type of storages

<br>

* bitpack loading: storing multiple variables in a single `32-bytes` slot by ordering the byte size.
* fixed-length arrays: takes a predetermined amount of slots.
* dynamic-length arrays: new elements assign slots after deployment (handled by the evm with keccak256 hashing).
* mappings: dynamic type with key hashes.
	* for example, `mapping(address => int)` maps unsigned integers.
 	* can only be defined in storage (*i.e.,* state variables). memory does not allow mappings even if they are inside a `struct`. 
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

---

### memory

<br>

* the second data area of which a contract obtains a cleared instance for each message call.
* memory is linear and can be addressed at the byte level.
* reads are limited to a width of `256 bit`s, while writes can be either `8 bits` or `256 bits` wide.
* memory is expanded by a word (`256-bit`), when accessing (either reading or writing) a previously untouched memory.
* at the time of expansion, the cost of gas must be paid - memory is more costly the large it grows, scaling quadratically.
* volatile read-write byte-addressable space (store data during execution) initialized as zero.
* the evm opcodes are `MLOAD` (loads a word into the stack), `MSTORE` (saves a word to memory), `MSTORE8` (saves a byte to memory).
* gas costs for memory loads (`MLOADs`) are significantly cheaper in gas than `SLOADs`.

<br>




----


### contract creation (`CREATE2`)

<br>

* the **creation of a contract** is a transaction where the **receiver address is empty** and its **data field contains compiled bytecode** or calling `CREATE2` opcode.
* the `new` keyword supports `CREATE2` feature by specifying `salt` options.
* the data sent is executed as bytecode, initializing the state variables in storage and determining the body of the contract being created.
* **contract memory** is a byte array, where data can be stored in `32 bytes (256 bit)` or `1 byte (8 bit)` chunks, reading in `32 bytes` chunks (through `MSTORE`, `MLOAD`, `MSTORE8`).

<br>

---

### message calls (`CALL`)

<br>

* `call` is a low-level function to **interact with other contracts**.
* contracts can call other contracts or send ether to non-contract accounts by through **message calls** (`CALL` opcode).
* every call has a **sender**, a **recipient**, a **payload** (data), a **value** (in wei), and some **gas**.
* it's the **recommended method** to use when **just sending ether via calling the `fallback` function**.
* but it's **not the recommended way** to call **existing functions**:
	* reverts are not bubbled up.
 	* type checks are bypassed.
  	* function existence checks are omitted.  
* a contract can decide how much of its remaining gas should be sent with the inner message call and how much it wants to retain.
* message calls are limited to a depth of `1024`, which means that for more complex operations, loops should be preferred over recursive calls.
* this is the recommended way of calling a contract:

```
contract Callee {
    uint public x;
    uint public value;

    function setX(uint _x) public returns (uint) {
        x = _x;
        return x;
    }

    function setXandSendEther(uint _x) public payable returns (uint, uint) {
        x = _x;
        value = msg.value;

        return (x, value);
    }
}

contract Caller {
    function setX(Callee _callee, uint _x) public {
        uint x = _callee.setX(_x);
    }

    function setXFromAddress(address _addr, uint _x) public {
        Callee callee = Callee(_addr);
        callee.setX(_x);
    }

    function setXandSendEther(Callee _callee, uint _x) public payable {
        (uint x, uint value) = _callee.setXandSendEther{value: msg.value}(_x);
    }
}
```

<br>

----

### delegate call (`DELEGATECALL`)

<br>

* `DELEGATECALL` preserves context (storage, caller, etc...) of the origing contract, where target code is executed within this context (`address`). therefore, `msg.sender` and `msg.value` do not change.

```
when contract A executes delegatecall to contract B:
B's code is executed with contract A's storage, msg.sender and msg.value
```

* **storage layout must be the same** for the contract calling delegatecall and the contract getting called.

* the contract can **dynamically load code (storage) from a different address at runtime**, while the **current address and balance still refer to the calling contract**.

* when a contract is being created, the code is still empty. the contract is under construction until the constuctor has finished executing.

<br>

```
// 1. Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract A {
    uint public num;
    address public sender;
    uint public value;

    function setVars(address _contract, uint _num) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}
```


<br>

---

### call / delegatecall/ statcall

<br>

* used to interface with contracts that do not adhere to ABI, or to give more direct control over encoding.
* they all take a single bytes memory parameter and return the success condition (as a bool) and the return data (byte memory).
* with `DELEGATECALL`, only the code of the given address is used but all other aspects are taken from the current contract. the purpose is to use logic code that is stored in the callee contract but operates on the state of the caller contract.
* with `STATCALL`, the execution will revert if the called function modifies the state in any way.

<br>

---

### creating a new instance

<br>

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

---

### addressing an existing instance

<br>

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
* here is a snippet of an attack:

```/*
GuessTheRandomNumber is a game where you win 1 Ether if you can guess the
pseudo random number generated from block hash and timestamp.

At first glance, it seems impossible to guess the correct number.
But let's see how easy it is win.

1. Alice deploys GuessTheRandomNumber with 1 Ether
2. Eve deploys Attack
3. Eve calls Attack.attack() and wins 1 Ether

What happened?
Attack computed the correct answer by simply copying the code that computes the random number.
*/

contract GuessTheRandomNumber {
    constructor() payable {}

    function guess(uint _guess) public {
        uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );

        if (_guess == answer) {
            (bool sent, ) = msg.sender.call{value: 1 ether}("");
            require(sent, "Failed to send Ether");
        }
    }
}

contract Attack {
    receive() external payable {}

    function attack(GuessTheRandomNumber guessTheRandomNumber) public {
        uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );

        guessTheRandomNumber.guess(answer);
    }

    // Helper function to check balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
```

<br>

---


### ABI encoding and decoding functions

<br>

- `abi.decode`:
	- `(uint a, uint[2] memory b, bytes memory c) = abi.decode(data, (uint, uint[2], bytes))` decodes the abi encoded data. 
- `abi.encode`:
	- `abi.encode(...)` returns `(bytes memory)` encodes stuff using padding and hence no collisions when dynamic data is involved.
- `abi.encodePacked`:
	- `abi.encodePacked(...)` returns `(bytes memory) does packed encoding.
 	- NOT be used when >2 dynamic arguments are involved due to hash collision. for instance, A, AB and AA, B give the same encoding due to no padding.
- `abi.encodeWithSelector`:
	- `abi.encodeWithSelector(bytes4 selector, ...)` returns `(bytes memory)` same as `abi.encode` but prepends the selector.
 	- this is useful when doing raw txns, selector is used to specify function signature. 
- `abi.encodeCall`:
	- `abi.encodeCall(functionPointer, ...)` returns `(byte memory)`, the same as above but a function pointer is passed.
- `abi.encodeWithSignature`

<br>


----

### signatures

<br>

* messages can be signed off chain and then verified on chain using a smart contract.
* messages are signed with the following steps:
  	1. create a message to sign
  	2. hash the messahe
  	3. sign the hash (off chain, keep private key secret)
 * messages can be signed with the following steps:
   	1. recreate hash from the original message
   	2. recover signed from signature and hash
   	3. compare recovered signed to claimed signer



<br>

```
contract VerifySignature {
    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    function getMessageHash(
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }

    /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(
        address _signer,
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
```

<br>

---

### global units

<br>

* `ether`, `wei`, `gwei` are global keywods:

```
assert(1 wei == 1);
assert(1 gwei == 1e9);
assert(1 ether == 1e18);
```

* `gasleft()` returns gas left in the current call.
* properties like `tx.*` and `block.*` might not be accurate when executed off-chain (not in an actual block).


<br>

---

### final consideration and tricks

<br>

* you can compare two dynamic length `bytes` or `string` by using `keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2))`.
* string does not have length property to access it's length. to make it usable in code that relies on length, cast it to `byte`s with `bytes(string)`.



