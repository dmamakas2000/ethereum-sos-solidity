# Ethereum SOS-Game Using Solidity
In this repository, we implement a complicated version of the SOS-Game, in an Ethereum smart contract using [#Solidity](https://soliditylang.org/). The contribution, splits into two APIs, which are finally combined to achieve the wanted functionality. Feel free to check out the code by yourself, and test it out using the [Remix IDE](https://remix.ethereum.org/)! 

### Basic Rules of the SOS Game
This game is played by two players alternately. There are 9 squares organized in a 3x3 grid. The squares are initially empty. On each move, the player playing must place one (and only one) *S* or *O* in any empty square he wishes. Play continues until the acronym *SOS* is formed horizontally, vertically, or diagonally, or until there are no more empty squares. If a player forms an SOS he wins the game.

### Structure

1. **CryptoSOS API** <br>
To play, one must call the CryptoSOS ```play()``` function. It then goes into a waiting state until another player calls ```play()```, at which point a game starts. Generally, a player is not allowed to play a game by himself. Then, whenever it is everyone's turn, they can call either ```placeS(uint8)``` or ```placeO(uint8)``` to place S or O in a square of their choice (1 to 9). At any time, one can call the ```getGameState()``` method which returns a string of 9 characters, in which each character comes from the set {-, S, O} and represents the state of the corresponding square (the 1st character from the left for square 1, and so on), where the dash corresponds to an empty square.

- ***Entry Fees and Prizes*** <br>
To participate, a **player must pay 1 Ether** when calling the ```play()``` function. At the end of the hand, **the winner is paid 1.9 Ether**, while the remaining **0.1 remains in the CryptoSOS wallet**. Only the owner of CryptoSOS (i.e. the account that deployed CryptoSOS) can get money from the game reserve, using the ```collectProfit()``` function, which transfers the entire balance to the owner's account.

- ***Safety*** <br>
If a player declares to play, and within 2 minutes a second player has not yet declared to participate, the first player is entitled to get all his money **(1 Ether)** back by calling the ```cancel()``` function. In addition, if the game has started, and 1 minute has passed since any player's move, and at the same time the other player has not yet made a move, then the one who made the last move is entitled to call the ```ur2slow()``` function and **get 1.9 Ether back**, leaving **0.1 Ether profit for the CryptoSOS wallet**, thus ending the game prematurely.

- ***Hall of Fame*** <br>
For each player who has played at least once, the smart contract keeps track of his total game participations, as well as his total wins. The ```getPlayerStats(address)``` function is used to implement this specific functionality. An entry canceled with the ```cancel()``` function, is not considered countable. Instead, a game that ends via ```ur2slow()``` counts as normal participation for both players and as a win for the player who (successfully) called ```ur2slow()```.

2. **MultiSOS API** <br>
MultiSOS API implements the same game style, except that it supports the parallel execution of multiple game sets. The first player to call ```play()``` is put on hold until a second player calls the same method, at which point a game will be started between them. Now if a third and fourth player calls``` play()``` in turn before the first-hand ends, a second game will start immediately, in parallel with the first. Generally, the idea supports the fact that unlimited games could be running simultaneously in parallel.

- **Private Lobby** <br>
A player also has the option to choose to play a hand with a specific other player. For this purpose, in addition to ```play()```, the method ```play(address)```, was implemented, with which the caller will declare the address of his teammate. When that player also calls the same method, with the first player's address, a game will be started between them. A player may call ```play(address)``` repeatedly (logically a few times), making himself available to play with several other players, or with the same teammate many times, but not with himself. Whenever one of these players calls ```play(address)``` also, with the address of the first one, the corresponding game will start. A player will be able to start games with specific teammates and open games. Finally, we state that the feature for the private lobby is only supported in MultiSOS and not in CryptoSOS.
