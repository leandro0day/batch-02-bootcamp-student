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
 $ npx hardhat test test/DesafioTesting_7.js
*/

interface IMiPrimerTKN {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

}

contract AirdropTwo is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct Participant {
        address participantAddress;
        uint256 participations;
        uint256 limiteParticipaciones;
        uint256 lastTimeParticipated;
    }

    mapping (address => Participant) public participantes;

    // instanciamos el token en el contrato
    IMiPrimerTKN miPrimerToken;
    
    constructor(address _tokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        miPrimerToken = IMiPrimerTKN(_tokenAddress);
    }

    function participateInAirdrop() public {
        _participateInAirdrop(address(0));
    }

    function participateInAirdrop(address _elQueRefirio) public {   
        _participateInAirdrop(_elQueRefirio);
    }

    function _participateInAirdrop(address _elQueRefirio) private{
        // Verificar si ya ha participado antes o no
        if(participantes[msg.sender].participantAddress == address(0)){
            Participant memory newParticipant = Participant({participantAddress: msg.sender, participations: 1, limiteParticipaciones: 10, lastTimeParticipated: block.timestamp});
            participantes[msg.sender] = newParticipant;
        } else {
            Participant memory participant = participantes[msg.sender];
            // Verificar si ya participo ese mismo dia
            require(participant.lastTimeParticipated + 1 days < block.timestamp, "Ya participaste en el ultimo dia");
            // Verificar si no ha alcnazado el limite de participaciones
            require(participant.participations < participant.limiteParticipaciones, "Llegaste limite de participaciones");

            participantes[msg.sender].participations++;
            participantes[msg.sender].lastTimeParticipated = block.timestamp;

        }

        uint256 semiRandomTokens = _getRadomNumber10005000();
        uint256 balanceTokensAirdrop = miPrimerToken.balanceOf(address(this));

        // Verificar que el contrato tiene suficientes tokens
        require(balanceTokensAirdrop >= semiRandomTokens, "El contrato Airdrop no tiene tokens suficientes");
        // Verificar que no se exceda el millon de tokens
        require(balanceTokensAirdrop + semiRandomTokens <= 10 ** 6 * 10 ** 18);
        
        miPrimerToken.transfer(msg.sender, semiRandomTokens);
        
         //Verificar que no puede autoreferirse
        require(_elQueRefirio != msg.sender, "No puede autoreferirse");

        if(_elQueRefirio != address(0)){
           _operateReferred(_elQueRefirio);
    }
        

}
    

    ///////////////////////////////////////////////////////////////
    ////                     HELPER FUNCTIONS                  ////
    ///////////////////////////////////////////////////////////////

    function _getRadomNumber10005000() internal view returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
                4000) +
            1000 +
            1;
    }

    function setTokenAddress(address _tokenAddress) external {
        miPrimerToken = IMiPrimerTKN(_tokenAddress);
    }

    function transferTokensFromSmartContract()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        
        miPrimerToken.transfer(
            msg.sender,
            miPrimerToken.balanceOf(address(this))
        );
    }

    function _operateReferred(address _elQueRefirio) internal{
        Participant storage referredParticipant = participantes[_elQueRefirio];

        if(referredParticipant.participantAddress != address(0)){
            referredParticipant.limiteParticipaciones += 3;
            referredParticipant.lastTimeParticipated = block.timestamp;
        } else{
            Participant memory newParticipant = Participant({participantAddress: _elQueRefirio, participations: 0, limiteParticipaciones: 13, lastTimeParticipated: block.timestamp});
            participantes[_elQueRefirio] = newParticipant;
        }
    }
}