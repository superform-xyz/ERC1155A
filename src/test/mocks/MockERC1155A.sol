/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { ERC1155A } from "../../ERC1155A.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

/// @notice For test purpouses we open mint()/burn() functions of ERC1155A
contract MockERC1155A is ERC1155A {
    /// @dev See ../ERC1155A.sol
    function uri(uint256 superFormId) public pure override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), Strings.toString(superFormId)));
    }

    /// @dev This is non-upgradeable value after deployment
    function _baseURI() internal pure override returns (string memory) {
        return "https://api.superform.xyz/superposition/";
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                            MOCK SECTION                             ///
    ///////////////////////////////////////////////////////////////////////////

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public virtual {
        _mint(to, id, amount, data);
    }

    function batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        _batchMint(to, ids, amounts, data);
    }

    function burn(address from, uint256 id, uint256 amount) public virtual {
        _burn(from, id, amount);
    }

    function batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) public virtual {
        _batchBurn(from, ids, amounts);
    }
}
