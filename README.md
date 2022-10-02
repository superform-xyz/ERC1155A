# ERC-1155s - Opinionated ERC-1155 Extension

You need foundry/forge to run repository.

`make install` && `make build` && `make test`

# Features

- `setApprovalForOne()` - approve only specific ERC-1155 id
- `_safeTransferFrom()` - notice underscore, separate function for single-approved transfers

Standard implementation of ERC1155 is kept. `setApprovalForAll()` can be used and does not collide with single id approvals. That is because we expect caller to know what _transfer function_ he needs to call. 