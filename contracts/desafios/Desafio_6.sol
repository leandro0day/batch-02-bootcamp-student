// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IMiPrimerTKN {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

contract AirdropOne is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant totalAirdropMax = 10_000_000 * 10 ** 18;
    uint256 public constant quemaTokensParticipar = 10 * 10 ** 18;

    uint256 public airdropGivenSoFar;

    address public miPrimerTokenAdd;

    mapping(address => bool) public whiteList;
    mapping(address => bool) public haSolicitado;

    constructor(address _tokenAddress) {
        miPrimerTokenAdd = _tokenAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    function participateInAirdrop() public whenNotPaused {
        require(whiteList[msg.sender], "No esta en lista blanca");
        require(!haSolicitado[msg.sender], "Ya ha participado");

        uint256 tokensToReceive = _getRadomNumberBelow1000();
        require(
            airdropGivenSoFar + tokensToReceive <= totalAirdropMax,
            "Se excede el total de tokens a repartir"
        );

        airdropGivenSoFar += tokensToReceive;
        haSolicitado[msg.sender] = true;

        IMiPrimerTKN miPrimerToken = IMiPrimerTKN(miPrimerTokenAdd);
        miPrimerToken.mint(msg.sender, tokensToReceive);
    }

    function quemarMisTokensParaParticipar() public whenNotPaused {
        require(haSolicitado[msg.sender], "Usted aun no ha participado");
        IMiPrimerTKN miPrimerToken = IMiPrimerTKN(miPrimerTokenAdd);
        uint256 userBalance = miPrimerToken.balanceOf(msg.sender);
        require(userBalance >= quemaTokensParticipar, "No tiene suficientes tokens para quemar");

        miPrimerToken.burn(msg.sender, quemaTokensParticipar);
        haSolicitado[msg.sender] = false;
    }

    function addToWhiteList(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        whiteList[_account] = true;
    }

    function removeFromWhitelist(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        whiteList[_account] = false;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _getRadomNumberBelow1000() internal view returns (uint256) {
        uint256 random = (uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 1000) + 1;
        return random * 10 ** 18;
    }

    function setTokenAddress(address _tokenAddress) external {
        miPrimerTokenAdd = _tokenAddress;
    }
}
