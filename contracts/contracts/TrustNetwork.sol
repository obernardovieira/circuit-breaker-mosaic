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
    struct ScorePenalty {
        uint256 percentage;
        uint256 timestamp;
    }
    uint256 public MAX_SCORE = 100;
    uint256 public MAX_INVITES = 10;
    address public verifierContractAddress;
    mapping(address => uint256) public trustScore;
    mapping(address => uint256) public invites;
    mapping(address => ScorePenalty) public penalties;

    constructor(address _verifierContractAddress) Ownable(msg.sender) {
        verifierContractAddress = _verifierContractAddress;
    }

    function join(
        // params for singature
        bytes memory _sigValue,
        bytes memory _signature,
        // params for ZK
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external {
        require(
            UltraVerifier(verifierContractAddress).verify(
                _proof,
                _publicInputs
            ),
            "INVALID_PROOF"
        );

        // TODO: get signer using _sigValue and _signature (should be EIP712)
        address inviter = msg.sender;

        require(_isInvitationValid(inviter), "NOT_ALLOWED_INVITE");
        // when invited, the score will be 4/5 of the inviter's score.
        trustScore[msg.sender] = trustScore[inviter] / 5 * 4;
        invites[inviter] ++;

        // TODO: emit event
    }

    // TODO: add method to reduce trust score
    function addPenalty(address _user, uint256 _percentage) external {
        ScorePenalty memory _penalty = ScorePenalty(_percentage, block.timestamp);

        // if there was any previous penalty, then update score and update penalty after
        ScorePenalty memory _prevPenalty = penalties[_user];
        if (_prevPenalty.timestamp != 0) {
            uint256 _prevScore = _getTrustScore(_user);
            trustScore[_user] = _prevScore;
        }

        penalties[_user] = _penalty;
        // TODO: emit event
    }

    // TODO: add method to get trust score (ideally receives array and returns array)
    function getTrustScore(address[] memory _users) internal view returns(uint256[] memory) {
        uint256[] memory res = new uint[](_users.length);
        for (uint i = 0; i < _users.length; i++) {
            res[i] = _getTrustScore(_users[i]);
        }

        return res;
    }

    /*
     * @dev Returns the hash of the given addresses and scores
     * @param _addresses The addresses to hash
     * @param _scores The scores to hash
     * @return The hash of the given addresses and scores
     */
    function getHash(address[] memory _addresses) public view returns (bytes32) {
        bytes memory res;
        for (uint i = 0; i < _addresses.length; i++) {
            res = abi.encodePacked(
                res,
                Strings.toHexString(_addresses[i]),
                Strings.toString(trustScore[_addresses[i]])
            );
        }
        return keccak256(res);
    }

    // TODO: complete
    function _getTrustScore(address _user) internal view returns(uint256) {
        return trustScore[_user];
    }

    /**
     * According to predefined rules, check if the invitation is still valid.
     * @param _inviter Inviter address
     */
    function _isInvitationValid(address _inviter) internal view returns(bool) {
        uint256 _invites = invites[_inviter];
        uint256 _score = trustScore[_inviter];

        // An inviter should only be able to invite if, above 50% max score and as not reached
        // the limite of invites. If both conditions are met, then, above 90% the max score can invite freely
        // above 75% max score can invite only 1/3 of the max invites and above 50% max score, only 1/6.

        if (
            _invites < MAX_INVITES &&
            _score > (MAX_SCORE / 2) &&
            (
                _score > (MAX_SCORE * 90 / 100) ||
                (_score > (MAX_SCORE * 75 / 100) && _invites < (MAX_INVITES / 3)) ||
                _invites < (MAX_INVITES / 6)
            )
        ) {
            return true;
        }
        return false;
    }
}
