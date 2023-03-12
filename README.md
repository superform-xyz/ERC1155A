# ERC-1155s - SuperForm's ERC-1155 Extension

SuperForm implementation of ERC-1155 with extended approval logic. Allows token owners to execute single id approvals in place of mass approving all of the ERC-1155 ids to the spender.

You need foundry/forge to run repository.

`forge install`

`forge test`

Two set of tests are run. `ERC-1155s` specific and general `ERC-1155` tests forked from solmate's implementation of the standard. SuperForm's `ERC-1155s` has exactly the same interface as standard `ERC-1155` and expected behavior of functions follow EIP documentation. 

# Rationale

ERC1155 `setApprovalForAll` function gives full spending permissions over all currently exisiting and future Ids. Addition of single Id approve, allows this token standard to improve composability through more open access control (*to funds). If external contract is an expected spender of a ERC1155 Id, there is no reason it should have access to all the user owned Ids. 

# Implementation Details

Main change is how `ERC-1155s` implements `safeTransferFrom()` function. Standard ERC-115 implementations are checking only if caller `isApprovedForAll` or the owner of tokens being transfered. We propose `setApprovalForOne()` function to allow granting approval for specific ERC-1155 id in arbitrary amount. Therefore, owner is no longer required to mass approve all of his token ids. The side effect of it is requirement of additional validation logic inside of `safeTransferFrom()` function.

### Gas Overhead

Additional approval logic validation makes transfer operations more expensive. Here's how it looks by comparison to solmate ERC1155 standard implementation:

ERC-1155S

```
| safeBatchTransferFrom                            | 105081          | 105081 | 105081 | 105081 | 1       |
| safeTransferFrom                                 | 27543           | 32887  | 33789  | 36428  | 4       |
| setApprovalForAll                                | 24574           | 24574  | 24574  | 24574  | 3       |
| setApprovalForOne                                | 24920           | 24920  | 24920  | 24920  | 3       |
```

ERC-1155

```
| safeBatchTransferFrom                                     | 1247            | 896149 | 124953 | 8597031 | 15      |
| safeTransferFrom                                          | 1072            | 34106  | 27191  | 183333  | 18      |
| setApprovalForAll                                         | 4581            | 23615  | 24481  | 24481   | 23      |
```