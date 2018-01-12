/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts. 
  
  Abstracted away from the Exchange so that other contracts (and future versions of the Exchange) can utilize the same Registry contract.

*/

pragma solidity 0.4.18;

import "./AuthenticatedProxy.sol";

contract Registry {

    /* Authenticated proxies, by authenticated contract, by user. */
    mapping(address => mapping(address => AuthenticatedProxy)) public proxies;

    function proxyFor(address auth, address user)
        public
        view
        returns (AuthenticatedProxy proxy)
    {
        return proxies[auth][user];
    }

    function registerProxy(address auth)
        public
        returns (AuthenticatedProxy proxy)
    {
        require(proxies[auth][msg.sender] == address(0));
        proxy = new AuthenticatedProxy(msg.sender, auth, this);
        proxies[auth][msg.sender] = proxy;
        return proxy;
    }

    function changeProxyAuth(address oldAuth, address newAuth)
        public
    {
        require(proxies[oldAuth][msg.sender] != address(0));
        require(proxies[newAuth][msg.sender] == address(0));
        AuthenticatedProxy proxy = proxies[oldAuth][msg.sender];
        proxies[newAuth][msg.sender] = proxy;
        delete proxies[oldAuth][msg.sender];
        proxy.changeAuth(newAuth); 
    }

}
