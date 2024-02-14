// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
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
    struct UserTrustPenalty {
        uint256 percentage;
        uint256 timestamp;
    }
    struct UserTrustScore {
        uint256 score;
        uint256 lastUpdate;
    }
    struct UserTrustNetwork {
        bytes32 rootHash;
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
    mapping(address => UserTrustScore) public trust;
    mapping(address => UserTrustPenalty) public penalties;
    mapping(address => UserTrustNetwork) public trustNetwork;
    // events
    event UserAdded(address indexed _user);
    event UserJoined(
        address indexed _user,
        address indexed _inviter,
        uint256 _score
    );
    event TrustUpdated(address indexed _user, uint256 _score);
    event PenaltyAdded(
        address indexed _user,
        uint256 _percentage,
        uint256 _prevScore
    );
    event NetworkUpdated(address indexed _user, bytes32 _newRootHash);

    // modifiers
    modifier onlyMember() {
        require(trust[msg.sender].score > 0, "NOT_MEMBER");
        _;
    }

    /**
     * @dev Constructor
     * @param _verifierContractAddress The address of the ZK verifier contract
     */
    constructor(address _verifierContractAddress) Ownable(msg.sender) {
        verifierContractAddress = _verifierContractAddress;
        _grantRole(MANAGER_ROLE, msg.sender);
        _setRoleAdmin(AUTHORIZED_3RD_PARTY_ROLE, MANAGER_ROLE);
    }

    /**
     * @dev Sets the verifier contract address
     * @param _member The address of the new member
     */
    function addMember(address _member) external onlyRole(MANAGER_ROLE) {
        trust[_member].score = 50;
        trust[_member].lastUpdate = block.timestamp;

        emit UserAdded(_member);
    }

    /**
     * Join method is called by the user when it wants to join the network.
     * The user must provide a valid invitation and a valid ZK proof.
     * @param _inviter Inviter address
     * @param _proof ZK proof
     * @param _publicInputs ZK public inputs
     */
    function join(
        address _inviter,
        bytes32 _newRootHash,
        bytes32 _previousInviterRootHash,
        bytes32 _newInviterRootHash,
        // params for ZK
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external {
        address inviter = _inviter;

        require(_isInvitationValid(inviter), "NOT_ALLOWED_INVITE");
        require(
            trustNetwork[inviter].rootHash == _previousInviterRootHash,
            "INVALID_INVITER_ROOT_HASH"
        );
        require(
            UltraVerifier(verifierContractAddress).verify(
                _proof,
                _publicInputs
            ),
            "INVALID_PROOF"
        );

        // when invited, the score will be 4/5 of the inviter's score.
        trust[msg.sender].score = (trust[inviter].score / 5) * 4;
        trust[msg.sender].lastUpdate = block.timestamp;
        invites[inviter]++;

        // inviter trust core will be updated, decreasing by 1/3 of the difference of score between the inviter and the invited.
        trust[inviter].score -=
            (trust[inviter].score - trust[msg.sender].score) /
            3;

        _updateTrustNetwork(msg.sender, _newRootHash);
        _updateTrustNetwork(_inviter, _newInviterRootHash);

        emit UserJoined(msg.sender, inviter, trust[msg.sender].score);
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
    ) external onlyMember {
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
            penalties[msg.sender] = UserTrustPenalty(0, 0);
        }

        trust[msg.sender].score = uint256(_publicInputs[0]) + _incrementScore;
        trust[msg.sender].lastUpdate = block.timestamp;

        emit TrustUpdated(msg.sender, trust[msg.sender].score);
    }

    /**
     * @dev Adds a penalty to the given user
     * @param _user The user to add the penalty
     * @param _percentage The percentage of the penalty
     */
    function addPenalty(
        address _user,
        uint256 _percentage
    ) external onlyRole(AUTHORIZED_3RD_PARTY_ROLE) {
        require(penalties[_user].timestamp == 0, "PENALTY_ALREADY_EXISTS");

        UserTrustPenalty memory _penalty = UserTrustPenalty(
            _percentage,
            block.timestamp
        );

        (uint256 _prevScore, ) = _getUserTrustScoreWithPenalty(_user);
        trust[_user].score = _prevScore;
        penalties[_user] = _penalty;

        emit PenaltyAdded(_user, _percentage, trust[_user].score);
    }

    /**
     * @dev Returns the trust score and last penalty of a list of users
     * @param _users The users to get the trust score and last penalty
     * @return The trust score and last penalty timestamp of the given users
     */
    function getTrustScore(
        address[] memory _users
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory usersScore = new uint[](_users.length);
        uint256[] memory usersLastPenalty = new uint[](_users.length);
        for (uint i = 0; i < _users.length; i++) {
            (
                usersScore[i],
                usersLastPenalty[i]
            ) = _getUserTrustScoreWithPenalty(_users[i]);
        }

        return (usersScore, usersLastPenalty);
    }

    /**
     * @dev Updates the root hash of the trust network of the given user
     * @param _newRootHash The user new network root hash
     */
    function updateTrustNetwork(bytes32 _newRootHash) external onlyMember {
        // more than 3 months ago
        require(
            block.timestamp > trustNetwork[msg.sender].lastUpdate + 7776000,
            "TOO_SOON"
        );

        _updateTrustNetwork(msg.sender, _newRootHash);
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
                // TODO: we need to include last penalty updated on the hash
                // so we can validate it on the circuit. Otherwise, the user
                // can change the network root hash even if a penalty was added
                // to one of their connections during the last month.
            );
        }
        return keccak256(res);
    }

    /**
     * @dev Private method to update the trust network of the given user
     * @param _user The user to update the trust network
     * @param _newRootHash The new root hash of the trust network
     */
    function _updateTrustNetwork(address _user, bytes32 _newRootHash) internal {
        trustNetwork[_user].rootHash = _newRootHash;
        trustNetwork[_user].lastUpdate = block.timestamp;

        emit NetworkUpdated(_user, _newRootHash);
    }

    /**
     * @dev Returns the trust score of the given user with the penalty
     * @param _user The user to get the trust score
     * @return The trust score of the given user with the penalty
     */
    function _getUserTrustScoreWithPenalty(
        address _user
    ) internal view returns (uint256, uint256) {
        if (penalties[_user].percentage == 0) {
            return (trust[_user].score, 0);
        }
        return (
            (trust[_user].score * (100 - penalties[_user].percentage)) / 100,
            penalties[_user].timestamp
        );
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
