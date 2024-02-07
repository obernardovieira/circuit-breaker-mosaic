// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface UltraVerifier {
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external view returns (bool);
}

contract TrustNetwork is Ownable {
    address public verifierContractAddress;

    constructor(address _verifierContractAddress) Ownable(msg.sender) {
        verifierContractAddress = _verifierContractAddress;
    }

    function join(
        bytes memory _message,
        bytes memory _signature,
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external {
        // TODO: verify signature
        require(
            UltraVerifier(verifierContractAddress).verify(
                _proof,
                _publicInputs
            ),
            ""
        );

        // TODO: complete
    }

    // TODO: add method to reduce trust score

    // TODO: add method to get trust score (ideally receives array and returns array)

    /*
     * @dev Returns the hash of the given addresses and scores
     * @param _addresses The addresses to hash
     * @param _scores The scores to hash
     * @return The hash of the given addresses and scores
     */
    function getHash(address[] memory _addresses) public view returns (bytes32) {
        // TODO: get scores from storage
        uint256[] memory _scores = new uint256[](_addresses.length);
        //
        require(_addresses.length == _scores.length, "Invalid input length");
        bytes memory res;
        for (uint i = 0; i < _addresses.length; i++) {
            res = abi.encodePacked(
                res,
                Strings.toHexString(_addresses[i]),
                Strings.toString(_scores[i])
            );
        }
        return keccak256(res);
    }
}
