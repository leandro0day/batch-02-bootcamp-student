// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/** CUASI SUBASTA INGLESA
 *
 * Descripción:
 * Tienen la tarea de crear un contrato inteligente que permita crear subastas Inglesas (English auction).
 * Se paga 1 Ether para crear una subasta y se debe especificar su hora de inicio y finalización.
 * Los ofertantes envían sus ofertas a la subasta que ellos deseen durante el tiempo que la subasta esté abierta.
 * Cada subasta tiene un ID único que permite a los ofertantes identificar la subasta a la que desean ofertar.
 * Los ofertantes, para poder proponer su oferta, envían Ether al contrato (llamando al método 'proponerOferta' o enviando directamente).
 * Las ofertas deben ser mayores a la oferta más alta actual para una subasta en particular.
 * Si se realiza una oferta dentro de los 5 minutos finales de la subasta, el tiempo de finalización se extiende en 5 minutos.
 * Una vez que el tiempo de la subasta se cumple, cualquiera puede llamar al método 'finalizarSubasta' para finalizar la subasta.
 * Cuando finaliza la subasta, el ganador recupera su oferta y se lleva el 1 Ether depositado por el creador.
 * Cuando finaliza la subasta se emite un evento con el ganador (address).
 * Las personas que no ganaron la subasta pueden recuperar su oferta después de que finalice la subasta.
 *
 * ¿Qué es una subasta Inglesa?
 * En una subasta inglesa, el precio comienza bajo y los postores aumentan el precio haciendo ofertas.
 * Cuando se cierra la subasta, se emite un evento con el mejor postor.
 *
 * Métodos a implementar:
 *
 * - El método 'creaSubasta(uint256 _startTime, uint256 _endTime)':
 *      * Crea una subasta especificando su hora de inicio y finalización.
 *      * Requiere el pago de 1 Ether para crear la subasta.
 *      * Verifica que el tiempo de finalización sea mayor al tiempo de inicio.
 *      * Emite el evento 'SubastaCreada' con el ID de la subasta y el creador de la subasta (address).
 *
 * - El método 'proponerOferta(bytes32 _auctionId)':
 *      * Permite a los ofertantes proponer una oferta para una subasta.
 *      * Verifica que la subasta esté en curso y que la oferta sea mayor a la oferta más alta actual.
 *      * Emite el evento 'OfertaPropuesta' con el postor y el monto de la oferta.
 *      * Si la oferta se realiza dentro de los últimos 5 minutos de la subasta, se extiende el tiempo de finalización.
 *
 * - El método 'finalizarSubasta(bytes32 _auctionId)':
 *      * Permite a cualquiera finalizar una subasta una vez que haya terminado el tiempo de la subasta.
 *      * Emite el evento 'SubastaFinalizada' con el ganador de la subasta y el monto de la oferta.
 *      * Transfiere 1 Ether al ganador de la subasta.
 *
 * - El método 'recuperarOferta(bytes32 _auctionId)':
 *      * Permite a los usuarios recuperar su oferta (tanto si ganaron como si perdieron la subasta).
 *      * Verifica que la subasta haya finalizado.
 *      * El smart contract le envía el balance de Ether que tiene a favor del ofertante.
 *
 * - El método 'verSubastasActivas() returns(bytes32[])':
 *      * Devuelve la lista de subastas activas en un array.
 *
 * Para correr el test de este contrato:
 * $ npx hardhat test test/EjercicioIntegrador_4.ts
 */
contract Desafio_4 {
    // Eventos para registrar acciones importantes en el contrato.
    event SubastaCreada(bytes32 indexed _auctionId, address indexed _creator);
    event OfertaPropuesta(address indexed _bidder, uint256 _bid);
    event SubastaFinalizada(address indexed _winner, uint256 _bid);

    // Errores personalizados que pueden ser revertidos en caso de condiciones no cumplidas.
    error CantidadIncorrectaEth();
    error TiempoInvalido();
    error SubastaInexistente();
    error FueraDeTiempo();
    error OfertaInvalida();
    error SubastaEnMarcha();

    // Estructura para representar una subasta.
    struct Subasta {
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
    }

    // Lista de subastas activas.
    bytes32[] public subastasActivas;

    // Mapeo de subastas por su ID único.
    mapping(bytes32 => Subasta) public subastas;
    mapping(bytes32 => mapping(address => uint256)) public bids;

    // Método para crear una nueva subasta.
    function creaSubasta(uint256 _startTime, uint256 _endTime) public payable {
        // Verifica que el remitente haya enviado 1 Ether.
        if (msg.value != 1 ether) {
            revert CantidadIncorrectaEth();
        }
        // Verifica que el tiempo de finalización sea mayor que el tiempo de inicio.
        if (_startTime >= _endTime) {
            revert TiempoInvalido();
        }

        // Crea un ID único para la subasta.
        bytes32 _auctionId = _createId(_startTime, _endTime);

        // Crea una nueva subasta y la agrega a la lista de subastas activas.
        subastas[_auctionId] = Subasta({
            startTime: _startTime,
            endTime: _endTime,
            highestBid: 0 ether,
            highestBidder: address(0)
        });
        subastasActivas.push(_auctionId);

        emit SubastaCreada(_auctionId, msg.sender);
    }

    // Método para proponer una oferta en una subasta.
    function proponerOferta(bytes32 _auctionId) public payable {
        Subasta storage subasta = subastas[_auctionId];

        // Verifica que la subasta exista.
        if (subasta.startTime == 0) {
            revert SubastaInexistente();
        }

        // Verifica que la subasta esté en curso.
        if (block.timestamp > subasta.endTime) {
            revert FueraDeTiempo();
        }

        // Verifica que la oferta sea mayor a la oferta más alta actual.
        if (msg.value < subasta.highestBid) {
            revert OfertaInvalida();
        }

        // Almacena la oferta del postor.
        bids[_auctionId][msg.sender] = msg.value;
        // Actualiza la oferta más alta y al postor ganador.
        subasta.highestBid = msg.value;
        subasta.highestBidder = msg.sender;

        // Si la oferta se realiza dentro de los últimos 5 minutos de la subasta, se extiende el tiempo de finalización.
        if (subasta.endTime - block.timestamp < 300) {
            subasta.endTime += 300;
        }

        emit OfertaPropuesta(msg.sender, msg.value);
    }

     bool llamada ;
    // Método para finalizar una subasta.
    function finalizarSubasta(bytes32 _auctionId) public {
        Subasta storage subasta = subastas[_auctionId];
       

        if(llamada){
            revert SubastaInexistente();
        }
        // Verifica que la subasta exista.
        if (subasta.startTime == 0 ) {
            revert SubastaInexistente();
        }

        // Verifica que la subasta haya terminado.
        if (block.timestamp < subasta.endTime) {
            revert SubastaEnMarcha();
        }

        // Transfiere 1 Ether al ganador de la subasta.
        address winner = subasta.highestBidder;
        uint256 bidAmount = subasta.highestBid;
        payable(winner).transfer(1 ether);

        uint256 indexToDelete;

        for (uint256 i = 0; i < subastasActivas.length; i++) {
            if (subastasActivas[i] == _auctionId) {
                indexToDelete = i;
            }
        }

        uint256 lastIndex = subastasActivas.length - 1;
        bytes32 lastElement = subastasActivas[lastIndex];
        subastasActivas[indexToDelete] = lastElement;
        subastasActivas.pop();

        llamada = true;
        emit SubastaFinalizada(winner, bidAmount);
    }

    // Método para recuperar una oferta después de finalizar la subasta.
    function recuperarOferta(bytes32 _auctionId) public {
        Subasta storage subasta = subastas[_auctionId];

        // Verifica que la subasta haya finalizado.
        if (block.timestamp < subasta.endTime) {
            revert SubastaEnMarcha();
        }

        // Transfiere el balance de Ether que tiene a favor del ofertante.
        uint256 refundAmount = bids[_auctionId][msg.sender];
        
        payable(msg.sender).transfer(refundAmount);
    }

    // Método para ver la lista de subastas activas.
    function verSubastasActivas() public view returns (bytes32[] memory) {
        return subastasActivas;
    }

    // Función interna para crear un ID único para una subasta.
    function _createId(
        uint256 _startTime,
        uint256 _endTime
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _startTime,
                    _endTime,
                    msg.sender,
                    block.timestamp
                )
            );
    }
}
