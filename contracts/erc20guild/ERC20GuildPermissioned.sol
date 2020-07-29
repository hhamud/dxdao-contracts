// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./ERC20Guild.sol";

/// @title ERC20Guild
/// @author github:AugustoL
/// @notice This smart contract has not be audited.
/// @dev Extends an ERC20 funcionality into a Guild.
/// An ERC20Guild can make decisions by creating proposals
/// and vote on the token balance as voting power.
contract ERC20GuildPermissioned is ERC20Guild {
    using SafeMath for uint256;
    
    mapping(address => mapping(bytes4 => bool)) public callPermissions;

    event SetAllowance(address indexed to, bytes4 functionSignature, bool allowance); 
    
    modifier isAllowed(address[] memory to, bytes[] memory data) {
      for (uint i = 0; i < to.length; i ++) {
        bytes memory _data = data[i];
        bytes4 functionSignature;
        assembly {
          functionSignature := mload(add(_data, 4))
        }
        require(callPermissions[to[i]][functionSignature], 'ERC20GuildPermissioned: Not allowed call');
      }
      _;
    }
    
    /// @dev Initilizer
    /// @param _token The address of the token to be used, it is immutable and ca
    /// @param _minimumProposalTime The minimun time for a proposal to be under votation
    /// @param _tokensForExecution The token votes needed for a proposal to be executed
    /// @param _tokensForCreation The minimum balance of tokens needed to create a proposal
    function initialize(
      address _token,
      uint256 _minimumProposalTime,
      uint256 _tokensForExecution,
      uint256 _tokensForCreation
    ) public {
      super.initialize(_token, _minimumProposalTime, _tokensForExecution, _tokensForCreation);
      callPermissions[address(this)][bytes4(keccak256("setConfig(uint256,uint256,uint256)"))] = true;
      callPermissions[address(this)][bytes4(keccak256("setAllowance(address[],bytes4[],bool[])"))] = true;
    }
    
    /// @dev Set the allowance of a call to be executed by the ERC20Guild
    /// @param to The address to be called
    /// @param functionSignature The signature of the function
    /// @param allowance If the function is allowed to be called or not
    function setAllowance(
        address[] memory to,
        bytes4[] memory functionSignature,
        bool[] memory allowance
    ) public isInitialized {
        require(
            msg.sender == address(this), 
            "ERC20Guild: Only callable by ERC20guild itself"
        );
        require(
            (to.length == functionSignature.length) && (to.length == allowance.length),
            "ERC20Guild: Wrong length of to, functionSignature or allowance arrays"
        );
        for (uint i = 0; i < to.length; i ++) {
          callPermissions[to[i]][functionSignature[i]] = allowance[i];
          emit SetAllowance(to[i], functionSignature[i], allowance[i]);
        }
    }
    
    /// @dev Execute a proposal that has already passed the votation time and has enough votes
    /// @param proposalId The id of the proposal to be executed
    function executeProposal(bytes32 proposalId) public isInitialized 
      isAllowed(proposals[proposalId].to, proposals[proposalId].data)
    {
        super.executeProposal(proposalId);
    }

    /* Testing function */ 
    function allowTestReturn(bytes memory data) public view returns (bytes4) {
      bytes4 functionSignature = bytes4(0);
      assembly {
        functionSignature := mload(add(data, 4))
      }
      return functionSignature;
    }
}
