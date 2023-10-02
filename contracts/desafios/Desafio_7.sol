// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
REPETIBLE CON LÍMITE, PREMIO POR REFERIDO

* El usuario puede participar en el airdrop una vez por día hasta un límite de 10 veces
* Si un usuario participa del airdrop a raíz de haber sido referido, el que refirió gana 3 días adicionales para poder participar
* El contrato Airdrop mantiene los tokens para repartir (no llama al `mint` )
* El contrato Airdrop tiene que verificar que el `totalSupply`  del token no sobrepase el millón
* El método `participateInAirdrop` le permite participar por un número random de tokens de 1000 - 5000 tokens
*/

interface IMiPrimerTKN {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract AirdropTwo is Pausable, AccessControl {
    IMiPrimerTKN miPrimerToken;

    // Mapeo para llevar un registro de las participaciones de cada usuario
    mapping(address => uint256) public participaciones;
    mapping(address => uint256) public ultimaVezParticipado;

    // Límite de participaciones por día y total
    uint256 public limiteDiario = 1;
    uint256 public limiteTotal = 10;

    // Días adicionales para el referente
    uint256 public diasAdicionalesPorReferido = 3;

    // Evento para registrar las participaciones
    event Participacion(address indexed participante, uint256 tokens);

    constructor(address _tokenAddress) {
        miPrimerToken = IMiPrimerTKN(_tokenAddress);
    }

    function participateInAirdrop() public whenNotPaused {
        address participante = msg.sender;

        // Verificar límite diario
        require(participaciones[participante] < limiteDiario, "Ya participaste en el ultimo dia");

        // Verificar límite total
        require(participaciones[participante] < limiteTotal, "Llegaste al limite de participaciones");

        // Verificar que el contrato tenga suficientes tokens
        uint256 balanceContrato = miPrimerToken.balanceOf(address(this));
        require(balanceContrato >= 1000, "El contrato Airdrop no tiene tokens suficientes");

        // Calcular tokens aleatorios
        uint256 tokensGanados = _getRadomNumber10005000();

        // Transferir tokens al participante
        miPrimerToken.transfer(participante, tokensGanados);

        // Registrar participación
        participaciones[participante]++;
        ultimaVezParticipado[participante] = block.timestamp;

        emit Participacion(participante, tokensGanados);
    }

    function participateInAirdrop(address _elQueRefirio) public whenNotPaused {
        address participante = msg.sender;
        address referente = _elQueRefirio;

        // Verificar que no pueda referirse a sí mismo
        require(participante != referente, "No puedes autoreferirte");

        // Verificar límite diario
        require(participaciones[participante] < limiteDiario, "Ya participaste en el ultimo dia");

        // Verificar límite total
        require(participaciones[participante] < limiteTotal, "Llegaste al limite de participaciones");

        // Verificar que el contrato tenga suficientes tokens
        uint256 balanceContrato = miPrimerToken.balanceOf(address(this));
        require(balanceContrato >= 1000, "El contrato Airdrop no tiene tokens suficientes");

        // Calcular tokens aleatorios
        uint256 tokensGanados = _getRadomNumber10005000();

        // Transferir tokens al participante
        miPrimerToken.transfer(participante, tokensGanados);

        // Registrar participación
        participaciones[participante]++;
        ultimaVezParticipado[participante] = block.timestamp;

        // Si el referente existe, aumentar su límite de participación
        if (participaciones[referente] > 0) {
            limiteTotal += diasAdicionalesPorReferido;
        }

        emit Participacion(participante, tokensGanados);
    }

     function setTokenAddress(address _tokenAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        miPrimerToken = IMiPrimerTKN(_tokenAddress);
    }

    function _getRadomNumber10005000() internal view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 4000) + 1000;
    }
}

