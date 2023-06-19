## solidity tl;dr

<br>

#### *a smart contract is a collection of code (functions) and data (state) on the ethereum blockchain.*

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

* each transaction is charged with some gas that has to be paid for by the originator (`tx.origin`).
* if the gas is used up at any point, an out-of-gas exception is triggered, ending execution and reverting all modifications made to the state in the current call frame.
* since each block has a maximum amount of gas, it also limits the amount of work needed to validate a block.
* the gas price is set by the originator of the transaction, who has to pay `gas_price * gas` upfront to the EVM executor. any gas left is refunded to the transaction originator. exceptions that revert changes do not refund gas.
  

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
* the feature called **logs** is used by solidity in order to implement events. emitting events cause the arguments to be stored in the transaction's log (which are associated with the address of the contract).
* contracts cannot access log data after it has been created, but they can be efficiently accessed from outside the blockchain (e.g., through bloom filters).
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

#### fixed-size byte arrays

* the data type `byte` represents a sequence of bytes.
* there are two types: fixed-sized byte arrays and dynamically-sized byte arrays.
* `bytes1`, `bytes2`, `bytes3`, ..., `bytes32` hold a sequence of bytes from one to up to `32`.
* the type `byte[]` is an array of bytes that due to padding rules, wastes `31 bytes` of space for each element, therefore it's better to use `bytes()`.
* example:

```
bytes1 a = 0xb5; //  [10110101]
bytes1 b = 0x56; //  [01010110]
```


<br>

#### state variables

* variables that can be accessed by all functions of the contract and values are permanently stored in the contract storage.
* **state visibility specifiers** define how the methods will be accessed:
	- `public`: part of the contract interface and can be accessed internally or via messages (i.e., can be accessed from other contracts).
	- `external`: like public functions, but cannot be called within the contract. an external function `func` cannot be called internally: `func()` does not work but `this.func()` does.
	- `internal`: can only be accessed internally from within the current contracts (or contracts deriving from it).
	- `private`: can only be accessed from the contract they are defined in and not in derived contracts.
	- `pure`: neither reads nor writes any variables in storage. It can only operate on arguments and return data, without reference to any stored data. pure functions are intended to encourage declarative-style programming without side effects or state.
	- `payable`: can accept incoming payments. Functions not declared as payable will reject incoming payments. There are two exceptions, due to design decisions in the EVM: coinbase payments and `SELFDESTRUCT` inheritance will be paid even if the fallback function is not declared as payable.

<br>

#### immutability

* state variables can be declared as constant or immutable, so they cannot be modified after the contract has been constructed.
	* for **constant variables**, the value is fixed at compile-time; for **immutable variables**, the value can still be assigned at construction time (in the constructor or point of declaration).
	* for **constant variables**, the expression assigned is copied to all the places, and re-evaluated each time (local optimizations are possible). for **immutable variables**, the expression is evaluated once at constriction time and their value is copied to all the places in the code they are accessed, on a reserved `32 bytes`, becoming usually more expensive than constant.

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

- `view` functions can read the contract state but not modify it: enforced at runtime via `STATICALL` opcode.
- `pure` functions can neither read a contract nor modify it.
- only `view` can be enforced at the EVM level, not `pure`.

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

* constructor code is only run when the contract is created; it cannot be called afterwards.
* a global variable can be the assigned to the contractor creator by attributing `msg.sender` to it.
* when a contract is created, the function with **constructor** is executed once and then the final code of the contract is stored on the blockchain (all public and external functions, but not the constructor code or internal functions called by it).

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
* bitpack loading: storing multiple variables in a single `32-bytes` slot by ordering the byte size.
* fixed-length arrays: takes a predetermined amount of slots.
* dynamic-length arrays: new elements assign slots after deployment (handled by the evm with keccak256 hashing).
* mappings: dynamic type with key hashes. for example, `mapping(address => int)` maps unsigned integers.
* however, it is neither possible to obtain a list of all keys of a mapping, nor a list of all values.
* it's costly to read, initialise, and modify storage.
* a contract cannot read or write to any storage apart from its own.


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

* errors are used together with the `revert statement`, which unconditionally aborts and reverts all changes.
* examples of error handling in solidity are:
	- `assert()`: causes a panic error and reverts if the condition is not met.
	- `require()`: reverts if the condition is not met.
	- `revert()`: abort execution and revert state changes.

* errors can also provide information about a failed operations.
* they are returned to the caller of the function:

```
error InsufficientBalance(uint requested, uint available);
```


