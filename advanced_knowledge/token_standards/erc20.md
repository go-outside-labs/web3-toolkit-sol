## ERC20 

<br>

* defines a common interface for contracts implementing this token, such that any compatible token can be accessed and used in the same way.
* a transaction sending ether to an address changes the state of an address. a transaction transferring a token to an address only changes the state of the token contract, not the state of the recipient address.
* one of the main reasons for the success of EIP-20 tokens is in the interplay between `approve` and `transferFrom`, which allows for tokens to not 
only be transferred between externally owned accounts (EOA).
   - but to be used in other contracts under application specific conditions by abstracting away `msg.sender` as the mechanism for token access control.
*  a limiting factor lies from the fact that the EIP-20 `approve` function is defined in terms of `msg.sender`. 
    - this means that user’s initial action involving EIP-20 tokens must be performed by an EOA. 
    - if the user needs to interact with a smart contract, then they need to make 2 transactions (`approve` and the smart contract internal call `transferFrom`), with gas costs.

<br>


---

### ERC20-compliant token contract

<br>

* `totalSupply`: Returns the total units of this token that currently exist. ERC20 tokens can have a fixed or a variable supply.
* `balanceOf`: Given an address, returns the token balance of that address.
* `transfer`: Given an address and amount, transfers that amount of tokens to that address, from the balance of the address that executed the transfer.
* `transferFrom`: Given a sender, recipient, and amount, transfers tokens from one account to another. Used in combination with approve.
* `approve`: given a recipient address and amount, authorizes that address to execute several transfers up to that amount, from the account that issued the approval.
* `allowance`: given an owner address and a spender address, returns the remaining amount that the spender is approved to withdraw from the owner.
* `Transfer`: event triggered upon a successful transfer (call to transfer or transferFrom) (even for zero-value transfers).
* `Approval`: event logged upon a successful call to approve.

<br>

---

### ERC20 optional functions

<br>

* in addition to the required functions listed in the previous section, the following optional functions are also defined by the standard:
     - `name`: returns the human-readable name (e.g., "US Dollars") of the token.
     - `symbol`: returns a human-readable symbol (e.g., "USD") for the token.
     - `decimals`: returns the number of decimals used to divide token amounts. For example, if decimals is 2, then the token amount is divided by 100 to get its user representation.

<br>

---

### the ERC20 interface

<br>

```
contract ERC20 {
   function totalSupply() constant returns (uint theTotalSupply);
   function balanceOf(address _owner) constant returns (uint balance);
   function transfer(address _to, uint _value) returns (bool success);
   function transferFrom(address _from, address _to, uint _value) returns
      (bool success);
   function approve(address _spender, uint _value) returns (bool success);
   function allowance(address _owner, address _spender) constant returns
      (uint remaining);
   event Transfer(address indexed _from, address indexed _to, uint _value);
   event Approval(address indexed _owner, address indexed _spender, uint _value);
}
```

