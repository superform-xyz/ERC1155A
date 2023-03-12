# ERC-1155s - SuperForm's ERC-1155 Extension

SuperForm implementation of ERC-1155 with extended approval logic. Allows token owners to execute single id approvals in place of mass approving all of the ERC-1155 ids to the spender.

You need foundry/forge to run repository.

`forge install`

`forge test`

Two set of tests are run. `ERC-1155s` specific and general `ERC-1155` tests forked from solmate's implementation of the standard. SuperForm's `ERC-1155s` has exactly the same interface as standard `ERC-1155` and expected behavior of functions follow EIP documentation. 

# Rationale

ERC1155 `setApprovalForAll` function gives full spending permissions over all currently exisiting and future Ids. Addition of single Id approve, allows this token standard to improve composability through more better allowance control of funds. If external contract is an expected to spend only a single ERC1155 id there is no reason it should have access to all the user owned ids. 

# Implementation Details

Main change is how `ERC-1155s` implements `safeTransferFrom()` function. Standard ERC-115 implementations are checking only if caller `isApprovedForAll` or an owner of token ids. We propose `setApprovalForOne()` function allowing approvals for specific id in any amount. Therefore, id owner is no longer required to mass approve all of his token ids. The side effect of it is requirement of additional validation logic inside of `safeTransferFrom()` function.

With gas effiency in mind and preservation of expected ERC-1155 behavior, ERC-1155s still prioritizes `isApprovedForAll` over `setApprovalForOne()`. Only `safeTransferFrom()` function works with single allowances, `safeBatchTransferFrom()` function requires owner to grant `setApprovalForAll()` to the operator. Decision is dictated by a significant gas costs overhead when required to decrease (or reset, in case of an overflow) allowances for each id in array. Moreover, if owner has `setApprovalForAll()` set to `true`, ERC-1155s contract will not modify existing single allowances during `safeTransferFrom()` and `safeBatchTransferFrom()` - assuming that owner has full trust in *operator* for granting mass approve. Therefore, ERC-1155s requires owners to manage their allowances individually and be mindfull of enabling `setApprovalForAll()` for external contracts.

### Gas Overhead

Additional approval logic validation makes transfer operations more expensive. Here's how it looks by comparison to solmate ERC1155 standard implementation:

ERC-1155S

```
| safeBatchTransferFrom                            | 79432           | 79432 | 79432  | 79432 | 1       |
| safeTransferFrom                                 | 27614           | 31069 | 31801  | 34517 | 5       |
| setApprovalForAll                                | 24574           | 24574 | 24574  | 24574 | 3       |
| setApprovalForOne                                | 24920           | 24920 | 24920  | 24920 | 4       |
```

ERC-1155

```
| safeBatchTransferFrom                                     | 1247            | 896149 | 124953 | 8597031 | 15      |
| safeTransferFrom                                          | 1072            | 34106  | 27191  | 183333  | 18      |
| setApprovalForAll                                         | 4581            | 23615  | 24481  | 24481   | 23      |
```

# Future Work

TODO: https://eips.ethereum.org/EIPS/eip-1761 (suggested by 1155) - scope-based approvals

TODO: Add SuperForm's PositionSplitter to this set of contracts