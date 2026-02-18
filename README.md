# Storage of Structs, Mappings, and Arrays in Solidity

In Solidity, complex data types such as structs, mappings, and arrays live in different places depending on how they are declared and used.

Solidity mainly uses three data locations:

- `storage` → permanent blockchain state
- `memory` → temporary runtime memory
- `calldata` → read-only function input data

## Structs

### Where structs are stored

| Declaration | Location |
| --- | --- |
| State variable struct | `storage` |
| Inside function with `memory` | `memory` |
| Function parameter (`external`) | `calldata` |

### Example

```solidity
struct User {
    string name;
    uint age;
}

User public user; // stored in STORAGE
```

### How structs behave when executed

#### Storage struct (persistent)

```solidity
User storage u = user;
u.age = 30;
```

- ✅ Changes affect blockchain state
- ✅ Gas expensive
- ✅ Permanent

#### Memory struct (temporary)

```solidity
User memory temp = user;
temp.age = 30;
```

- ❌ Original struct unchanged
- ✅ Cheaper
- ❌ Destroyed after function finishes

### Summary

- `storage` → real data on blockchain
- `memory` → temporary copy
- `calldata` → read-only input

## Arrays

Arrays can exist in `storage`, `memory`, or `calldata`.

### Where arrays are stored

| Type | Location |
| --- | --- |
| State array | `storage` |
| Function-local array | `memory` |
| External function input | `calldata` |

### Example

```solidity
uint[] public numbers; // STORAGE
```

### How arrays behave

#### Storage array

```solidity
uint[] storage nums = numbers;
nums.push(10);
```

- ✅ Modifies blockchain
- ✅ Persistent

#### Memory array

```solidity
uint[] memory nums = new uint[](3);
nums[0] = 5;
```

- ❌ Temporary
- ❌ Cannot `push`/`pop`
- ❌ Deleted after function

### Key rules

- Storage arrays are dynamic and persistent
- Memory arrays must have fixed size when created
- Calldata arrays are read-only

## Mappings

Mappings are special.

### Where mappings are stored

Mappings **always** live in `storage`.

```solidity
mapping(address => uint) balances;
```

### How mappings behave

- Key-value lookup
- No length
- Cannot loop directly
- Every key exists by default
- Missing keys return default value (`0`, `false`, etc.)

```solidity
balances[msg.sender] += 100;
```

- ✅ Writes directly to blockchain
- ✅ Permanent

### Why you do not specify `memory` or `storage` for mappings

Simple answer:

- 👉 Solidity forbids mappings outside `storage`

Technical reason:

Mappings:

- Have infinite possible keys
- Are implemented as hash tables
- Require persistent state

Memory is:

- Linear
- Temporary
- Cannot support key hashing

So this is illegal:

```solidity
mapping(address => uint) memory temp; // ❌
```

Solidity enforces this:

- Mappings can only exist in `storage`

That is why you never write this for declarations:

```solidity
mapping(address => uint) balances; // storage is automatic
```

## Quick Comparison

| Type | Can be in Memory? | Can be in Storage? | Persistent? |
| --- | --- | --- | --- |
| Struct | ✅ | ✅ | `storage` only |
| Array | ✅ | ✅ | `storage` only |
| Mapping | ❌ | ✅ | Always |

## Final Summary

### Structs

- Can be `storage`, `memory`, `calldata`
- Storage version modifies blockchain

### Arrays

- Can be `storage`, `memory`, `calldata`
- Storage arrays are dynamic
- Memory arrays are fixed-size

### Mappings

- Only `storage`
- No size
- No iteration
- Default values for missing keys
- No need to specify location in state declarations
