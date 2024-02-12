// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title UltraVerifier
 * @dev The UltraVerifier contract is an interface for the ZK verifier contract.
 */
interface UltraVerifier {
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external view returns (bool);
}

/**
 * @title TrustNetwork
 * @dev The TrustNetwork contract is a contract that manages the trust score of the users.
 * @notice The trust score is a value between 0 and 100. It utilizes a ZK proof to update the trust score.
 */
contract TrustNetwork is Ownable, AccessControl {
    struct TrustPenalty {
        uint256 percentage;
        uint256 timestamp;
    }
    struct TrustScore {
        uint256 score;
        uint256 lastUpdate;
    }
    // state variables
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant AUTHORIZED_3RD_PARTY_ROLE =
        keccak256("AUTHORIZED_3RD_PARTY_ROLE");
    //
    uint256 public MAX_SCORE = 100;
    uint256 public MAX_INVITES = 10;
    address public verifierContractAddress;
    //
    mapping(address => uint256) public invites;
    mapping(address => TrustScore) public trust;
    mapping(address => TrustPenalty) public penalties;

    constructor(address _verifierContractAddress) Ownable(msg.sender) {
        verifierContractAddress = _verifierContractAddress;
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    // TODO: add method to add new members, called by manager
    function addMember(address _member) external onlyRole(MANAGER_ROLE) {
        trust[_member].score = 50;
        trust[_member].lastUpdate = block.timestamp;

        // TODO: emit event
    }

    /**
     * Join method is called by the user when it wants to join the network.
     * The user must provide a valid invitation and a valid ZK proof.
     * @param _inviter Inviter address
     * @param _proof ZK proof
     * @param _publicInputs ZK public inputs
     */
    //  * @param _sigValue Signature value of the inviter
    //  * @param _signature Signature of the inviter
    function join(
        address _inviter,
        // params for singature
        // bytes memory _sigValue,
        // bytes memory _signature,
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
        address inviter = _inviter;

        require(_isInvitationValid(inviter), "NOT_ALLOWED_INVITE");
        // when invited, the score will be 4/5 of the inviter's score.
        trust[msg.sender].score = (trust[inviter].score / 5) * 4;
        trust[msg.sender].lastUpdate = block.timestamp;
        invites[inviter]++;

        // TODO: emit event
    }

    /**
     * computeNewTrust called by the user to compute the new trust score of the user.
     * The user must provide a valid ZK proof.
     * @param _incrementScore Increment score
     * @param _proof ZK proof
     * @param _publicInputs ZK public inputs
     */
    function computeNewTrust(
        uint256 _incrementScore,
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

        // if there was any penalty, clean it
        // the penalty was previously considered when generating the proof
        if (penalties[msg.sender].timestamp > trust[msg.sender].lastUpdate) {
            penalties[msg.sender] = TrustPenalty(0, 0);
        }

        trust[msg.sender].score = uint256(_publicInputs[0]) + _incrementScore;
        trust[msg.sender].lastUpdate = block.timestamp;

        // TODO: emit event
    }

    // TODO: add method to reduce trust score
    function addPenalty(
        address _user,
        uint256 _percentage
    ) external onlyRole(AUTHORIZED_3RD_PARTY_ROLE) {
        require(penalties[_user].timestamp == 0, "PENALTY_ALREADY_EXISTS");

        TrustPenalty memory _penalty = TrustPenalty(
            _percentage,
            block.timestamp
        );

        uint256 _prevScore = _getUserTrustScoreWithPenalty(_user);
        trust[_user].score = _prevScore;
        penalties[_user] = _penalty;
        // TODO: emit event
    }

    /**
     * @dev Returns the trust score of the given user
     * @param _users The users to get the trust score
     * @return The trust score of the given users
     */
    function getTrustScore(
        address[] memory _users
    ) external view returns (uint256[] memory) {
        uint256[] memory res = new uint[](_users.length);
        for (uint i = 0; i < _users.length; i++) {
            res[i] = _getUserTrustScoreWithPenalty(_users[i]);
        }

        return res;
    }

    /*
     * @dev Returns the hash of the given addresses and scores
     * @param _addresses The addresses to hash
     * @param _scores The scores to hash
     * @return The hash of the given addresses and scores
     */
    function getHash(
        address[] memory _addresses
    ) public view returns (bytes32) {
        bytes memory res;
        for (uint i = 0; i < _addresses.length; i++) {
            res = abi.encodePacked(
                res,
                Strings.toHexString(_addresses[i]),
                Strings.toString(trust[_addresses[i]].score)
            );
        }
        return keccak256(res);
    }

    function _getUserTrustScoreWithPenalty(
        address _user
    ) internal view returns (uint256) {
        if (penalties[_user].percentage == 0) {
            return trust[_user].score;
        }
        return (trust[_user].score * (100 - penalties[_user].percentage)) / 100;
    }

    /**
     * According to predefined rules, check if the invitation is still valid.
     * @param _inviter Inviter address
     */
    function _isInvitationValid(address _inviter) internal view returns (bool) {
        uint256 _invites = invites[_inviter];
        uint256 _score = trust[_inviter].score;

        // An inviter should only be able to invite if, above 50% max score and as not reached
        // the limite of invites. If both conditions are met, then, above 90% the max score can invite freely
        // above 75% max score can invite only 1/3 of the max invites and above 50% max score, only 1/6.

        if (
            _invites < MAX_INVITES &&
            _score > (MAX_SCORE / 2) &&
            (_score > ((MAX_SCORE * 90) / 100) ||
                (_score > ((MAX_SCORE * 75) / 100) &&
                    _invites < (MAX_INVITES / 3)) ||
                _invites < (MAX_INVITES / 6))
        ) {
            return true;
        }
        return false;
    }
}
