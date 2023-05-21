/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC1155s} from "../ERC1155s.sol";
import {Strings} from "../utils/Strings.sol";

/// @notice For test purpouses we open mint()/burn() functions of ERC1155s
contract MockERC1155s is ERC1155s {

    ///////////////////////////////////////////////////////////////////////////

    constructor(string memory uri_) ERC1155s(uri_) {}

    /// @dev See ../ERC1155s.sol
    function uri(
        uint256 superFormId
    ) public pure override returns (string memory) {
        return
            string(abi.encodePacked(_baseURI(), Strings.toString(superFormId)));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.superform.xyz/superposition/";
    }

    ///////////////////////////////////////////////////////////////////////////
    ///                            MOCK SECTION                             ///
    ///////////////////////////////////////////////////////////////////////////

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        _mint(to, id, amount, data);
    }

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        _batchMint(to, ids, amounts, data);
    }

    function burn(address from, uint256 id, uint256 amount) public virtual {
        _burn(from, id, amount);
    }

    function batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual {
        _batchBurn(from, ids, amounts);
    }
}
