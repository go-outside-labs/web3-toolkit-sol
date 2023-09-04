## gas optimization

<br>

- gas is the cost for on-chain computation and storage. examples: 
     - addition costs `3` gas, `keccak-256` costs `30 gas + 6 gas` for each `256 bits` of data being hashed.
     - sending a transaction costs `21,000 gas` (intrinsic gas).
     - creating a contract costs `32000 gas`.
- each **calldata** byte costs gas (gas per byte equal to `0`, and `16 gas` for the others), the larger the size of the transaction data, the higher the gas fees. 
- each opcode has a [specific fixed cost to be paid upon execution](https://www.evm.codes/?fork=arrowGlacier).
- calculate gas for your code online at [remix](https://remix.ethereum.org/).


<br>

----


### general tricks to save gas

<br>

* replace `memory` with `calldata`
* load state variable to memory
* replace for loop `i++` with `++i`
* caching array elements
* short circuits
* brute force hashes of function names to find those that start `0000`, so this can save around `50 gas`.
* if you don’t need a variable anymore, you should delete it using the delete keyword provided by solidity or by setting it to its default value.
* avoid calls to other contracts.

<br>


<img width="300" src="https://user-images.githubusercontent.com/1130416/214452718-b051caed-49e4-45fb-b955-976d20e97cbd.png">



<br>

```
// gas golf
contract GasGolf {
    // start - 50908 gas
    // use calldata - 49163 gas
    // load state variables to memory - 48952 gas
    // short circuit - 48634 gas
    // loop increments - 48244 gas
    // cache array length - 48209 gas
    // load array elements to memory - 48047 gas
    // uncheck i overflow/underflow - 47309 gas

    uint public total;

    // start - not gas optimized
    // function sumIfEvenAndLessThan99(uint[] memory nums) external {
    //     for (uint i = 0; i < nums.length; i += 1) {
    //         bool isEven = nums[i] % 2 == 0;
    //         bool isLessThan99 = nums[i] < 99;
    //         if (isEven && isLessThan99) {
    //             total += nums[i];
    //         }
    //     }
    // }

    // gas optimized
    // [1, 2, 3, 4, 5, 100]
    function sumIfEvenAndLessThan99(uint[] calldata nums) external {
        uint _total = total;
        uint len = nums.length;

        for (uint i = 0; i < len; ) {
            uint num = nums[i];
            if (num % 2 == 0 && num < 99) {
                _total += num;
            }
            unchecked {
                ++i;
            }
        }

        total = _total;
    }
}
```


<br>

---

### pack variables

<br>

* this code is an example of poor code and will consume 3 storage slot:

```
uint8 numberOne;
uint256 bigNumber;
uint8 numberTwo;
```

<br>

* a much more efficient way to do this in solidity will be:

```
uint8 numberOne;
uint8 numberTwo;
uint256 bigNumber;
```

<br>

---


### constant vs. immutable variables

<br>

* constant values can sometimes be cheaper than immutable values:
       - for a constant variable, the expression assigned to it is copied to all the places where it is accessed and also re-evaluated each time, allowing local optimizations.
       - immutable variables are evaluated once at construction time and their value is copied to all the places in the code where they are accessed. For these values, 32 bytes are reserved, even if they would fit in fewer bytes. 

<br>

---

### mappings are cheaper than arrays

<br>

- avoid dynamically sized arrays
- an array is not stored sequentially in memory but as a mapping.
- you can pack Arrays but not Mappings.
- it’s cheaper to use arrays if you are using smaller elements like `uint8` which can be packed together.
- you can’t get the length of a mapping or parse through all its elements, so depending on your use case, you might be forced to use an Array even though it might cost you more gas.

<br>

---

### use bytes32 rather than string/bytes

<br>

- if you can fit your data in 32 bytes, then you should use `bytes32` datatype rather than bytes or strings as it is much cheaper in solidity.
- any fixed size variable in solidity is cheaper than variable size.

<br>

---

### modifiers

<br>

- for all the public functions, the input parameters are copied to memory automatically, and it costs gas.
- if your function is only called externally, then you should explicitly mark it as external.
- external function’s parameters are not copied into memory but are read from `calldata` directly.
- internal and private are both cheaper than public and external when called from inside the contract in some cases.

<br>

---

### no need to initialize variables with default values

<br>

- if a variable is not set/initialized, it is assumed to have the default value (0, false, 0x0 etc depending on the data type). If you explicitly initialize it with its default value, you are just wasting gas.

```
uint256 hello = 0; //bad, expensive
uint256 world; //good, cheap
```

<br>

---

### make use of single line swaps 

<br>


- this is space-efficient:

```
(hello, world) = (world, hello)
```

<br>

---

### negative gas costs

<br>

- deleting a contract (SELFDESTRUCT) is worth a refund of 24,000 gas.
- changing a storage address from a nonzero value to zero (SSTORE[x] = 0) is worth a refund of 15,000 gas.

<br>

---

### [i ++](https://twitter.com/high_byte/status/1647080662094995457?s=20)

<br>

* instead of i++ you should write the ++ above the i.

```
while (true)
    uint256 i = 0;
     ++
    i
 ;
```

<br>

----


### unchecked math

<br>

* overflow and underflow of numbers in solidity 0.8 throw an error. this can be disabled with `unchecked`.
* disabling overflow / underflow check saves gas.

<br>

```
contract UncheckedMath {
    function add(uint x, uint y) external pure returns (uint) {
        // 22291 gas
        // return x + y;

        // 22103 gas
        unchecked {
            return x + y;
        }
    }

    function sub(uint x, uint y) external pure returns (uint) {
        // 22329 gas
        // return x - y;

        // 22147 gas
        unchecked {
            return x - y;
        }
    }

    function sumOfCubes(uint x, uint y) external pure returns (uint) {
        // Wrap complex math logic inside unchecked
        unchecked {
            uint x3 = x * x * x;
            uint y3 = y * y * y;

            return x3 + y3;
        }
    }
}

```



<br>

---

### resources 

<br>

* **[truffle contract size](https://github.com/IoBuilders/truffle-contract-size)**
* **[foundry book on gas](https://book.getfoundry.sh/forge/gas-reports)**
* **[solidity gas optimizations](https://mirror.xyz/haruxe.eth/DW5verFv8KsYOBC0SxqWORYry17kPdeS94JqOVkgxAA)**
* **[hardhat on gas optimization](https://medium.com/@thelasthash/%EF%B8%8F-gas-optimization-with-hardhat-1e553eaea311)**
* **[resources for gas optimization](https://github.com/kadenzipfel/gas-optimizations)**
* **[awesome solidity gas optimization](https://github.com/iskdrews/awesome-solidity-gas-optimization)**
* **[mev-toolkit resources](https://github.com/go-outside-labs/mev-toolkit/tree/main/MEV_searchers/code_resources/gas_optimization)**
* **[how gas optimization can streamline smart contracts](https://medium.com/@ayomilk1/maximizing-efficiency-how-gas-optimization-can-streamline-your-smart-contracts-4bafcc6bf321)**
* **[math, solidity & gas optimizations | part 1/3](https://officercia.mirror.xyz/vtVVxbV35ETiBGxm-IpcFPcsK2_ZkL7vgiiGUkeSsP0)**

