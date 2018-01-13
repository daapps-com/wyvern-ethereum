/* 

  Proxy contract to hold access to assets on behalf of a user (e.g. ERC20 approve) and execute calls under particular conditions.

*/

pragma solidity 0.4.18;

import "../common/TokenRecipient.sol";
import "./Registry.sol";

/**
 * @title AuthenticatedProxy
 * @author Project Wyvern Developers
 */
contract AuthenticatedProxy is TokenRecipient {

    address public user;

    Registry public registry;

    bool revoked = false;

    enum HowToCall { Call, DelegateCall, StaticCall, Create }

    event ProxiedCall(address indexed dest, HowToCall howToCall, bytes calldata, address indexed created, bool success);

    /**
     * Create an AuthenticatedProxy
     *
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of Registry contract which will manage this proxy
     */
    function AuthenticatedProxy(address addrUser, Registry addrRegistry) public {
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke Registry access)
     *
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke)
        public
    {
        require(msg.sender == user);
        revoked = revoke;
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param calldata Calldata to send
     */
    function proxy(address dest, HowToCall howToCall, bytes calldata) public returns (bool result) {
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)));
        address created;
        if (howToCall == HowToCall.Call) {
            result = dest.call(calldata);
        } else if (howToCall == HowToCall.DelegateCall) {
            result = dest.delegatecall(calldata);
        } else if (howToCall == HowToCall.StaticCall) {
            // Check this.
            uint len = calldata.length;
            assembly {
                result := staticcall(gas, dest, calldata, len, calldata, 0)
            }
        } else if (howToCall == HowToCall.Create) {
            assembly {
                created := create(0, add(calldata, 0x20), mload(calldata))
            }
            result = created == address(0);
        } else {
            revert();
        }
        ProxiedCall(dest, howToCall, calldata, created, result);
        return result;
    }

}
