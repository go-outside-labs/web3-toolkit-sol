## calldata

<br>

* calldata is the encoded parameter(s) sent on functions by smart contracts to the evm (for example, through `abi.econde()`,`abi.econcdeWithSelector() for a particular interfaced function, or `abi.encodePacked()` for efficient dynamic variables). 

* **function signature**: `selector()` generates the 4-bytes representing the method in the interface: this is how the evm knows which function is being interacted. function signatures are defined as the first four bytes of the Keccak hash of the canonical representation of the function signature.

* each piece of calldata is 32 bytes long (64 chars), where 20 hex == 32-bytes

* types:
   - static variables: the encoded representation of `uint`, `address`, `bool`, `bytes`, `tuples`
   - dynamics variables: non-fixed-size types: `bytes`, `string`, dynamic and fixed arrays `<T>[]`

* opcodes are `1 byte` in length, leading to `256` different possible opcodes. the EVM only uses `140` opcodes.

<br>

----

### decompilers

<br>

* **[dedaub](https://library.dedaub.com/)**
* **[ethervm.io](https://ethervm.io/decompile)**
* **[panoramix](https://github.com/eveem-org/panoramix)**
* **[froundry's cast with --debug](https://book.getfoundry.sh/cast/index.html)**


<br>


---

### resources

<br>

* **[mev memoirs in the arena part 1, by noxx](https://noxx.substack.com/p/mev-memoirs-into-the-arena-chapter?s=r)**
* **[mev memoirs in the arena part 2, by noxx](https://noxx.substack.com/p/mev-memoirs-into-the-arena-chapter-3e9)**
* **[ethereum tx enconding and legacy encoding](https://hoangtrinhj.com/articles/ethereum-transaction-encoding)**
