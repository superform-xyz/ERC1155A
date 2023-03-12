# ERC-1155s - Opinionated ERC-1155 Extension

You need foundry/forge to run repository.

`make install` && `make build` && `make test`

# Features

- `setApprovalForOne()` - approve only specific ERC-1155 id
- `_safeTransferFrom()` - notice underscore, separate function for single-approved transfers

Standard implementation of ERC1155 is kept. `setApprovalForAll()` can be used and does not collide with single id approvals. That is because we expect caller to know what _transfer function_ he needs to call. 

# Rationale

ERC1155 `setApprovalForAll` function gives full spending permissions over all currently exisiting and future Ids. Addition of single Id approve, allows this token standard to improve composability through more open access control (*to funds). If external contract is an expected spender of a ERC1155 Id, there is no reason it should have access to all the user owned Ids. 

# Security concerns

Approval race condition? It is possible to double-approve two separate address for same amount and id, something not possible in ERC20 or ERC721.

# SharesSplitter (idea)

Move wrap() and unwrap() functions to ERC1155s? Saving transfer call and locking amount of id internally. 