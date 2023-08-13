// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
* Author:               Dimitrios Mamakas 
* Registration number:  f3322209
* Institution:          Athens University of Economics and Business
*/
contract CryptoSOS {
    /*
    * Struct.
    */
    struct Player {
        address _address;
        uint startTime;
    }

    /*
    * Attributes. 
    */
    string[] private boxes;
    address owner;
    Player[] private players;
    Player[] private moves;

    /*
    * Constants.
    */
    uint constant TICKET_PRICE = 1 ether;
    uint constant PRIZE = 1900000000000000000;
    uint constant DURATION = 2 minutes;
    uint constant DURATION_SLOW_GAME = 1 minutes;

    /*
    * Events.
    */ 
    event StartGame(address, address);
    event Move(uint8, uint8, address);
    event Win(address);

    /*
    * Mappings.
    */
    mapping(address => uint) private PlayerWins;
    mapping(address => uint) private PlayerParticipations;

    /*
    * Main constructor. 
    */
    constructor() {
        // Constructor's task is to initialize all 9 boxes with the character '-'. 
        owner = msg.sender;
        boxes = new string[](9);

        for (uint i=0; i<9; i++) {
            boxes[i] = "-";
        }
    }

    /*
    * Places a 'S' unit to a specified box.
    */
    function placeS(uint8 _unit) public {
        uint8 _box = _unit - 1;
        address currentPlayer = msg.sender;

        // Requirements.
        require(players.length == 2, "Players should be exactly 2.");
        require(currentPlayer == players[0]._address || currentPlayer == players[1]._address, "You are not registered to this particular game!"); 
        require(moves[moves.length - 1]._address != currentPlayer, "You can't play again!");
        require(_box >= 0 && _box<=8, "You need to specify a box in the needed range [1, 9].");
        require(compareStrings(boxes[_box], "-"), "Chose another box.");

        // Place a 'S'.
        boxes[_box] = "S";
        moves.push(Player(currentPlayer, block.timestamp)); 
        emit Move(_unit, 1, currentPlayer);
                  
        // Check for winner.
        if (checkForWinner()) {
            // There is a winner to this game!
            handleWiningState(currentPlayer);
        } else if (checkIfAllBoxesAreFilled() && !checkForWinner()) {
            // There is a draw to this game.
            handleDrawState();
        }
    }

    /*
    * Places an 'O' unit to a specified box.
    */
    function placeO(uint8 _unit) public {
        uint8 _box = _unit - 1;
        address currentPlayer = msg.sender;

        // Requirements.
        require(players.length == 2, "Players should be exactly 2.");
        require(currentPlayer == players[0]._address || currentPlayer == players[1]._address, "You are not registered to this particular game!"); 
        require(moves[moves.length - 1]._address != currentPlayer, "You can't play again!");
        require(_box >= 0 && _box<=8, "You need to specify a box in the needed range [1, 9].");
        require(compareStrings(boxes[_box], "-"), "Chose another box.");

        // Place an 'O'.
        boxes[_box] = "O";
        moves.push(Player(currentPlayer, block.timestamp)); 
        emit Move(_unit, 2, currentPlayer);

        // Check for winner.
        if (checkForWinner()) {
            // There is a winner to this game!
            handleWiningState(currentPlayer);
        } else if (checkIfAllBoxesAreFilled() && !checkForWinner()) {
            // There is a draw to this game.
            handleDrawState();
        }
    }

    /*
    * Returns the current game state.
    */
    function getGameState() public view returns(string memory) {
        return string(abi.encodePacked(boxes[0], boxes[1], boxes[2], boxes[3], boxes[4], boxes[5],
            boxes[6], boxes[7], boxes[8]));
    }

    /*
    * Resets the initial game state.
    */
    function resetGameState() private {
        for (uint i=0; i<9; i++) {
            boxes[i] = "-";
        }
    }

    /*
    * Return the current registered players.
    */
    function getPlayers() public view returns (Player[] memory) {
        return players;
    }

    /*
    * Return the current registered moves for this game.
    */
    function getMoves() public view returns (Player[] memory) {
        return moves;
    }

    /*
    * Returns the game type.
    */
    function getGameType() public pure returns(string memory){
        return "CryptoSOS";
    }

    /*
    * Returns the current balance of this smart contract.
    */
    function checkCryptoSOSBalance() public view returns (uint) {
        return address(this).balance;
    }

    /*
    * Starts the game.
    */
    function play() payable external {
        require(players.length < 2, "No more players can play this game.");
        // Require 1 ether to play this game.
        require(msg.value == TICKET_PRICE, "Exactly 1 ether is required to play this game.");

        // Keep the address of the player calling this function.
        address player = msg.sender;

        // Push the sender's address into the array of the players.
        players.push(Player(player, block.timestamp));
        
        if (players.length == 1) {
            emit StartGame(players[0]._address, address(0));
        } else if (players.length == 2) {
            // Start the game
            emit StartGame(players[0]._address, players[1]._address);
            moves.push(Player(address(0), block.timestamp));
        } 
    }

    /*
    * Collects the profit and moves it into the owner's account.
    */ 
    function collectProfit() public {
        uint profit = checkCryptoSOSBalance();
        (bool sent, ) = payable(owner).call{value:profit}("");
        require(sent, "Collect profit failed.");
    }

    /*
    * Checks if a winner exists.
    */
    function checkForWinner() private view returns (bool) {
        // Perform brute-force checking.
        bool winnerExists = false;
        if (compareStrings(boxes[0], "S") && 
            compareStrings(boxes[1], "O") && compareStrings(boxes[2], "S")) {
            // Horizontal case: 1.
            winnerExists = true;
        } else if (compareStrings(boxes[3], "S") && 
            compareStrings(boxes[4], "O") && compareStrings(boxes[5], "S")) {
            // Horizontal case: 2.
            winnerExists = true;
        } else if (compareStrings(boxes[6], "S") && 
            compareStrings(boxes[7], "O") && compareStrings(boxes[8], "S")) {
            // Horizontal case: 3.
            winnerExists = true;
        } else if (compareStrings(boxes[0], "S") && 
            compareStrings(boxes[3], "O") && compareStrings(boxes[6], "S")) {
            // Vertical case: 1.
            winnerExists = true;
        } else if (compareStrings(boxes[1], "S") && 
            compareStrings(boxes[4], "O") && compareStrings(boxes[7], "S")) {
            // Vertical case: 2.
            winnerExists = true;
        } else if (compareStrings(boxes[2], "S") && 
            compareStrings(boxes[5], "O") && compareStrings(boxes[8], "S")) {
            // Vertical case: 3.
            winnerExists = true;
        } else if (compareStrings(boxes[0], "S") && 
            compareStrings(boxes[4], "O") && compareStrings(boxes[8], "S")) {
            // Diagonal case: 1.
            winnerExists = true;
        } else if (compareStrings(boxes[2], "S") && 
            compareStrings(boxes[4], "O") && compareStrings(boxes[6], "S")) {
            // Diagonal case: 2.
            winnerExists = true;
        }
        return winnerExists;
    }

    /*
    * Checks if all boxes are filled.
    */
    function checkIfAllBoxesAreFilled() private view returns (bool) {
        bool flag = true;
        for (uint i=0; i<9; i++) {
            if (!(compareStrings(boxes[i], "S") || compareStrings(boxes[i], "O"))) {
                flag = false;
            }
        }
        return flag;
    }

    /*
    * Compares two strings.
    */
    function compareStrings(string memory str1, string memory str2) private pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    /*
    * Cancels the current player from the list of players if there is no
    * second player involved, and the duration of wait exceeds 2 minutes.
    */
    function cancel() public {
        address currentPlayer = msg.sender;

        // Requirements
        require(players.length == 1, "Only one player can cancel the game.");
        require(players[0]._address == currentPlayer, "You are not registered to play this game.");
        require(block.timestamp - players[0].startTime >= DURATION, "The time range needed for this action, was no longer than 2 minutes.");

        // Return the money to the player.
        (bool sent, ) = payable(currentPlayer).call{value:TICKET_PRICE}("");
        require(sent, "Refund to player (due to long wait) failed.");
        players.pop();
    }

    /*
    * Returns the prize to the sender in the case the opponent did not respond 
    * in the time range of 1 minute from the sender's last move.
    */
    function ur2slow() public {
        address currentPlayer = msg.sender;
        
        // Requirements
        require(moves[moves.length - 1]._address == currentPlayer, "Only the last player who placed a box, can act like this.");
        require(block.timestamp - moves[moves.length - 1].startTime >= DURATION_SLOW_GAME, "One minute needs to be passed, in order for this action to be performed.");

        // The sender, can receive the winning prize, and end the game.
        handleWiningState(currentPlayer);
    }

    /*
    * Handles the case a player wins the game.
    */
    function handleWiningState(address winingPlayer) private {
        // Find the address of the losing player.
        address losingPlayer = players[0]._address;
        if (players[0]._address == winingPlayer) {
            losingPlayer = players[1]._address;
        }

        // Emit the winning event. 
        emit Win(winingPlayer);
        
        // Send the prize to the winner
        (bool sent, ) = payable(winingPlayer).call{value:PRIZE}("");
        require(sent, "Could not send the prize to the winner of this game.");

        // Empty the players list
        delete players;
                
        // Empty the moves list
        delete moves;

        // Reset the game state
        resetGameState();

        // Save the players statistics.
        PlayerWins[winingPlayer] = PlayerWins[winingPlayer] + 1;
        PlayerParticipations[winingPlayer] = PlayerParticipations[winingPlayer] + 1;
        PlayerParticipations[losingPlayer] = PlayerParticipations[losingPlayer] + 1;
    }

    /*
    * Handles the case of a draw in a game between 2 players.
    */ 
    function handleDrawState() private {
        // Emit the draw event. 
        emit Win(address(0));

        // Save the players statistics.
        PlayerParticipations[players[0]._address] = PlayerParticipations[players[0]._address] + 1;
        PlayerParticipations[players[1]._address] = PlayerParticipations[players[1]._address] + 1;
        
        // Empty the players list
        delete players;
           
        // Empty the moves list
        delete moves;

        // Reset the game state
        resetGameState();
    }

    /*
    * Returns statistics about a specific player.
    *
    * The function returns a tuple, containing the following:
    *
    * 1) Player's total number of wins.
    * 2) Player's total participations on games.
    */
    function getPlayerStats(address _player) public view returns (uint wins, uint participations) {
        return (PlayerWins[_player], PlayerParticipations[_player]);
    }
}