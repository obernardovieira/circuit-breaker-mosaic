// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract UltraVerifierMock {
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) public view returns (bool) {
        return true;
    }
}
