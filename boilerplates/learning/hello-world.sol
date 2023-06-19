pragma solidity ^0.8.10;

// Defines a contract named `GmWorld`.
// A contract is a collection of functions and data (its state).
// Once deployed, a contract resides at a specific address on the Ethereum blockchain.
contract GmWorld {

    // Declares a state variable `happiness` of type `string`.
    // State variables are variables whose values are permanently stored in contract storage.
    // The keyword `public` makes variables accessible from outside a contract
    // and creates a function that other contracts or clients can call to access the value.
    string public happiness;

    // Similar to many class-based object-oriented languages, a constructor is
    // a special function that is only executed upon contract creation.
    // Constructors are used to initialize the contract's data.
    constructor(string memory warmGun) public {
        // Accepts a string argument `warmGun` and sets the value
        // into the contract's `happiness` storage variable).
        happiness = warmGun;
    }

    // A public function that accepts a string argument
    // and updates the `happiness` storage variable.
    function update(string memory bobaTea) public {
        happiness = bobaTea;
    }
}
