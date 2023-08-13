// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
* Author:               Dimitrios Mamakas 
* Registration number:  f3322209
* Institution:          Athens University of Economics and Business
*/
library StringUtils {
    /*
    * Replaces a character inside a specific string, into a specified position.
    */
    function replaceString(string memory stringToReplace, uint256 position, string memory letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(stringToReplace);
        bytes memory result = new bytes(_stringBytes.length);
        for (uint8 i = 0; i < _stringBytes.length; i++) {
            result[i] = _stringBytes[i];
            if(i==position) {
                result[i]=bytes(letter)[0];
            }
        }
        return  string(result);
    }

    /*
    * Compares two strings. It  returns true if they are identical, else false.
    */
    function compareStrings(string memory str1, string memory str2) internal pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    /*
    * Returns the substring of a specific string, on the range specified.
    */ 
    function substring(string memory stringToRetrieve, uint start, uint end) internal pure returns (string memory) {
        bytes memory strBytes = bytes(stringToRetrieve);
        bytes memory result = new bytes(end-start);
        for (uint i = start; i < end; i++) {
            result[i-start] = strBytes[i];
        }
        return string(result);
    }
}

library MathUtils {
    /*
    * Generates a random number.
    */
    function random(uint number) internal view returns(uint32) {
        return uint32(uint(blockhash(number)));
    }
}

contract MultiSOS {
    /*
    * Structs. 
    */
    struct Player {
        address _address;
        uint startTime;
    }

    struct Game {
        uint32 gameId;
        Player playerOne;
        Player playerTwo;
        string boxes;
        address lastMove;
        uint lastMoveTime;
    }

    struct Lobby {
        address caller;
        address wanted;
    }

    /*
    * Attributes. 
    */
    Game[] private openGames;
    Lobby[] private waitingList;
    address owner;

    /*
    * Constants.
    */
    uint constant TICKET_PRICE = 1 ether;
    uint constant PRIZE = 1900000000000000000;
    uint constant DURATION = 2 minutes;
    uint constant DURATION_SLOW_GAME = 1 minutes;
    string constant EMPTY_BOXES = "---------";
    uint initialNumber;

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
        owner = msg.sender;
        initialNumber = 1;
    }

    /*
    * Places a 'S' unit to a specified box, to a specified game.
    */
    function placeS(uint8 _unit, uint32 _gameId) public {
        uint8 _box = _unit - 1;
        address currentPlayer = msg.sender;

        // Requirements.
        require(checkIfSpecificGameExists(_gameId));
        require(_box >= 0 && _box<=8, "BR");
        
        Game memory game = getSpecificGame(_gameId);
        require(currentPlayer == game.playerOne._address || currentPlayer == game.playerTwo._address, "NR"); 
        require(game.lastMove != currentPlayer, "PA");
        require(StringUtils.compareStrings(StringUtils.substring(openGames[findElementInArray(_gameId)].boxes, _box, _box+1), "-"), "AB");
        
        // Place a 'S'.
        openGames[findElementInArray(_gameId)].boxes = StringUtils.replaceString(game.boxes, _box, "S");
        emit Move(_unit, 1, currentPlayer);
        
        // Modify the last move.
        openGames[findElementInArray(_gameId)].lastMove = currentPlayer;
        openGames[findElementInArray(_gameId)].lastMoveTime = block.timestamp;

        // Check for winner.
        if (checkForWinner(_gameId)) {
            // There is a winner to this game!
            handleWiningState(currentPlayer, game);
        } else if (checkIfAllBoxesAreFilled(_gameId) && !checkForWinner(_gameId)) {
            // There is a draw to this game.
            handleDrawState(game.gameId, game.playerOne._address, game.playerTwo._address);    
        }
    }

    /*
    * Places an 'O' unit to a specified box, to a specified game.
    */
    function placeO(uint8 _unit, uint32 _gameId) public {
        uint8 _box = _unit - 1;
        address currentPlayer = msg.sender;

        // Requirements.
        require(checkIfSpecificGameExists(_gameId));
        require(_box >= 0 && _box<=8, "BR");
        
        Game memory game = getSpecificGame(_gameId);
        require(currentPlayer == game.playerOne._address || currentPlayer == game.playerTwo._address, "NR"); 
        require(game.lastMove != currentPlayer, "PA");
        require(StringUtils.compareStrings(StringUtils.substring(openGames[findElementInArray(_gameId)].boxes, _box, _box+1), "-"), "AB");

        // Places an 'O'.
        openGames[findElementInArray(_gameId)].boxes = StringUtils.replaceString(game.boxes, _box, "O");
        emit Move(_unit, 2, currentPlayer);
        
        // Modify the last move.
        openGames[findElementInArray(_gameId)].lastMove = currentPlayer;
        openGames[findElementInArray(_gameId)].lastMoveTime = block.timestamp;

        // Check for winner.
        if (checkForWinner(_gameId)) {
            // There is a winner to this game!
            handleWiningState(currentPlayer, game);
        } else if (checkIfAllBoxesAreFilled(_gameId) && !checkForWinner(_gameId)) {
            // There is a draw to this game.
            handleDrawState(game.gameId, game.playerOne._address, game.playerTwo._address); 
        }
    }

    /*
    * Starts one game.
    */
    function play() payable external {
        // Require 1 ether to play this game.
        require(msg.value == TICKET_PRICE, "1ET");
        address player = msg.sender;
        initialNumber = initialNumber + 1;

        if (openGames.length > 0) {
            // There are more games started.
            
            // Retrieve the last game.
            Game memory game = openGames[openGames.length - 1];
            if (game.playerOne._address != address(0) && game.playerTwo._address != address(0)) {
                // Start a new game.
                openGames.push(Game(
                    MathUtils.random(initialNumber), 
                    Player(player, block.timestamp), 
                    Player(address(0), 0), 
                    EMPTY_BOXES, 
                    address(0), 
                    block.timestamp
                )
            );
            } else if (game.playerOne._address != address(0) && game.playerTwo._address == address(0)) {
                // Add this player to the currently registered game.
                require(game.playerOne._address != player, "CRA");
                openGames[openGames.length - 1].playerTwo._address = player;
                openGames[openGames.length - 1].playerTwo.startTime = block.timestamp;
            }
        } else {
            // This is the first ever game to start.
            openGames.push(Game(
                    MathUtils.random(initialNumber), 
                    Player(player, block.timestamp), 
                    Player(address(0), 0), 
                    EMPTY_BOXES, 
                    address(0), 
                    block.timestamp
                )
            );
        }
    }

    /*
    * Starts one game with a specific player.
    */
    function play(address player) payable external {
        // Require 1 ether to play this game.
        require(msg.value == TICKET_PRICE, "1ET");
        address _player = msg.sender;
        initialNumber = initialNumber + 1;

        // The player can't play with himself!
        require(_player != player, "CPY");

        waitingList.push(Lobby(_player, player));

        if (checkForLobbyMatch(_player, player)) {
            // There is a match! Start a game.
            openGames.push(Game(
                    MathUtils.random(initialNumber), 
                    Player(_player, block.timestamp), 
                    Player(player, block.timestamp), 
                    EMPTY_BOXES, 
                    address(0), 
                    block.timestamp
                )
            );
        }
    }

    /*
    * Checks the case there is a match in the lobby between two players.
    */
    function checkForLobbyMatch(address caller, address wanted) private view returns (bool) {
        uint numFound = 0;
        for (uint8 i=0; i<waitingList.length; i++) {
            if (waitingList[i].caller == caller && waitingList[i].wanted == wanted) {
                numFound = numFound + 1;
            } else if (waitingList[i].caller == wanted && waitingList[i].wanted == caller) {
                numFound = numFound + 1;
            }
        }
        if (numFound == 2) {
            // We found a match!
            return true;
        } else {
            return false;
        }
    }

    /*
    * Returns the current balance of this smart contract.
    */
    function checkCryptoSOSBalance() public view returns (uint) {
        return address(this).balance;
    }

    /*
    * Collects the profit and moves it into the owner's account.
    */ 
    function collectProfit() public {
        uint profit = checkCryptoSOSBalance();
        (bool sent, ) = payable(owner).call{value:profit}("");
        require(sent, "CPF");
    }

    /*
    * Returns a specific game.
    */
    function getSpecificGame(uint32 _gameId) private view returns (Game memory) {
        for (uint8 i=0; i<openGames.length; i++) {
            if (openGames[i].gameId == _gameId) {
                return openGames[i];
            }
        }
        revert("NE");
    }

    /*
    * Returns all game ids.
    */ 
    function getAllGameIds() public view returns (uint32[] memory) {
        uint32[] memory ids = new uint32[](openGames.length);
        for (uint8 i=0; i<openGames.length; i++) {
            ids[i] = openGames[i].gameId;
        }
        return ids;
    }

    /*
    * Returns the current game state.
    */
    function getGameState(uint32 _gameId) public view returns (string memory) {
        if (checkIfSpecificGameExists(_gameId)) {
            // If the game exists
            return getSpecificGame(_gameId).boxes;
        }
        revert("NE");
    }

    /*
    * Checks if whether a specific game exists.
    */
    function checkIfSpecificGameExists(uint32 _gameId) private view returns (bool) {
        bool exists = false;
        for (uint8 i=0; i<openGames.length; i++) {
            if (openGames[i].gameId == _gameId) {
                exists = true;
            }
        }
        return exists;
    }

    /*
    * Checks if a winner exists by performing brute-force checks.
    */
    function checkForWinner(uint32 _gameId) private view returns (bool) {
        bool winnerExists = false;
        if (checkIfSpecificGameExists(_gameId)) {
            Game memory game = getSpecificGame(_gameId);
            // Perform brute-force checking.
            if (StringUtils.compareStrings(StringUtils.substring(game.boxes, 0, 1), "S") && 
                StringUtils.compareStrings(StringUtils.substring(game.boxes, 1, 2), "O") && 
                StringUtils.compareStrings(StringUtils.substring(game.boxes, 2, 3), "S")) {
                // Horizontal case: 1.
                winnerExists = true;
            } else if (StringUtils.compareStrings(StringUtils.substring(game.boxes, 1, 2), "S") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 2, 3), "O") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 3, 4), "S")) {
                // Horizontal case: 2.
                winnerExists = true;
            } else if (StringUtils.compareStrings(StringUtils.substring(game.boxes, 2, 3), "S") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 3, 4), "O") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 4, 4), "S")) {
                // Horizontal case: 3.
                winnerExists = true;
            } else if (StringUtils.compareStrings(StringUtils.substring(game.boxes, 0, 1), "S") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 3, 4), "O") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 6, 7), "S")) {
                // Vertical case: 1.
                winnerExists = true;
            } else if (StringUtils.compareStrings(StringUtils.substring(game.boxes, 1, 2), "S") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 4, 5), "O") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 7, 8), "S")) {
                // Vertical case: 2.
                winnerExists = true;
            } else if (StringUtils.compareStrings(StringUtils.substring(game.boxes, 2, 3), "S") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 5, 6), "O") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 8, 9), "S")) {
                // Vertical case: 3.
                winnerExists = true;
            } else if (StringUtils.compareStrings(StringUtils.substring(game.boxes, 0, 1), "S") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 4, 5), "O") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 8, 9), "S")) {
                // Diagonal case: 1.
                winnerExists = true;
            } else if (StringUtils.compareStrings(StringUtils.substring(game.boxes, 2, 3), "S") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 4, 5), "O") && 
                        StringUtils.compareStrings(StringUtils.substring(game.boxes, 6, 7), "S")) {
                // Diagonal case: 2.
                winnerExists = true;
            }
        }
        return winnerExists;
    }

    /*
    * Checks if all boxes are filled.
    */
    function checkIfAllBoxesAreFilled(uint32 _gameId) private view returns (bool) {
        bool flag = true;
        if (checkIfSpecificGameExists(_gameId)) {
            Game memory game = getSpecificGame(_gameId);
            for (uint i=0; i<9; i++) {
                if (!(StringUtils.compareStrings(StringUtils.substring(game.boxes, i, i+1), "S") 
                    || StringUtils.compareStrings(StringUtils.substring(game.boxes, i, i+1), "O"))) {
                    flag = false;
                }
            }
        }
        return flag;
    }

    /*
    * Cancels the current player from the list of players if there is no
    * second player involved, and the duration of wait exceeds 2 minutes.
    */
    function cancel(uint32 _gameId) public {
        if (checkIfSpecificGameExists(_gameId)) {
            address currentPlayer = msg.sender;
            Game memory game = getSpecificGame(_gameId);

            // Requirements.
            require((game.playerOne._address != address(0) && game.playerOne.startTime != 0)
                    && (game.playerTwo._address == address(0) && game.playerTwo.startTime == 0)
                , "O1C");            
            require(game.playerOne._address == currentPlayer, "NR");
            require(block.timestamp - game.playerOne.startTime >= DURATION, "TR");

            // Return the money to the player.
            (bool sent, ) = payable(currentPlayer).call{value:TICKET_PRICE}("");
            require(sent, "RF");
            
            // Now remove the game from the open games list.
            removeGame(findElementInArray(game.gameId) + 1);
        }
    }

    /*
    * Returns the prize to the sender in the case the opponent did not respond 
    * in the time range of 1 minute from the sender's last move.
    */
    function ur2slow(uint32 _gameId) public {
        if (checkIfSpecificGameExists(_gameId)) {
            address currentPlayer = msg.sender;
            Game memory game = getSpecificGame(_gameId);

            // Requirements
            require(game.lastMove == currentPlayer, "LP");
            require(block.timestamp - game.lastMoveTime >= DURATION_SLOW_GAME, "1M");

            // The sender, can receive the winning prize, and end the game.
            handleWiningState(currentPlayer, game);
        }
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

    /*
    * Handles the case a player wins the game.
    */
    function handleWiningState(address winingPlayer, Game memory game) private {
        address losingPlayer = game.playerOne._address;
        if (winingPlayer == game.playerOne._address) {
            losingPlayer = game.playerTwo._address;
        }
        // Emit the winning event. 
        emit Win(winingPlayer);
        
        // Send the prize to the winner.
        (bool sent, ) = payable(winingPlayer).call{value:PRIZE}("");
        require(sent, "CSP");

        // Save the players statistics.
        PlayerWins[winingPlayer] = PlayerWins[winingPlayer] + 1;
        PlayerParticipations[winingPlayer] = PlayerParticipations[winingPlayer] + 1;
        PlayerParticipations[losingPlayer] = PlayerParticipations[losingPlayer] + 1;

        // Now remove the game from the open games list.
        removeGame(findElementInArray(game.gameId) + 1);
    }

    /*
    * Handles the case of a draw in a game between 2 players.
    */ 
    function handleDrawState(uint32 _gameId, address p1, address p2) private {
        // Emit the draw event. 
        emit Win(address(0));

        // Save the players statistics.
        PlayerParticipations[p1] = PlayerParticipations[p1] + 1;
        PlayerParticipations[p2] = PlayerParticipations[p2] + 1;

        // Now remove the game from the open games list.
        removeGame(findElementInArray(_gameId) + 1);
    }

    /*
    * Removes a game from the open games list.
    */
    function removeGame(uint256 index) private {
        require(index >= openGames.length, "NE");
        for (uint i = index; i<openGames.length-1; i++){
            openGames[i] = openGames[i+1];
        }
        openGames.pop();
    }

    /*
    * Returns the game type.
    */
    function getGameType() public pure returns(string memory) {
        return "MultiSOS";
    }

    /*
    * Return the index of a specific element inside a game array.
    */
    function findElementInArray(uint32 _gameId) private view returns(uint) {
        for (uint i = 0 ; i < openGames.length; i++) {
            if (_gameId == openGames[i].gameId) {
                return i;
            }
        }
        revert("NE");
    }
}