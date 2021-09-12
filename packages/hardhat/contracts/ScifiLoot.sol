//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LootMetadataSvg.sol";
import "./Alien.sol";
import "./Player.sol";

contract ScifiLoot is ERC721, Ownable {
	using Counters for Counters.Counter;
  	Counters.Counter private _tokenIds;
	Alien alien;
	Player player;
	// address public owner;

	string[] categories = [
		"WEAPON",
		"PILL",
		"VEHICLE",
		"DEFFENSE"
	];
	
	struct ScifiLoot {
		uint256 tokenId;
		uint256 alienId;
		string alienName;
		uint256 rarityLevel;
		uint256 category; 
		bool exists;
	}

	mapping (uint256 => ScifiLoot) public lootItems;
	mapping (uint256 => bool) public deadAliens;
	mapping (address => uint256) public players;

	event LootMinted(uint256 tokenId, uint256 rand);

	// modifier onlyOwner {
  	// 	require(msg.sender == owner);_;
	// }

	// function changeBase(address alienAddress) public onlyOwner returns(bool success) {
	// 	alien = Alien(alienAddress);
	// 	return true;
	// }

	constructor(address alienAddress, address playerAddress) public ERC721("ScifiLoot", "SFL") {
		alien = Alien(alienAddress);
		alien.initialize();
		player = Player(playerAddress);
		player.initialize();
		// owner = msg.sender;
  	}

	function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

	function conditionalMint(uint256 alienId) public returns (string memory) {
		return alien.getAlienName(alienId);
	}

	function transferNft(uint256 tokenId, address address_to) public returns (bool) {
		require(_exists(tokenId), "not exist");
		transferFrom(ownerOf(tokenId), address_to, tokenId);
		return true;
	}

	function mintPlayer(string memory name) external returns (uint256) {
		require(players[msg.sender] == 0, "Player exists in game");
		uint256 id = player.mint(name);
		players[msg.sender] = id;
		return id;
	}

	function mintLoot(uint256 alienId)
		public
		returns (uint256) {
			require(deadAliens[alienId] == false, "Already minted!");
			require(alien.isAlienExists(alienId), "Alien does not exist");
			require(alien.checkCorrectPlayer(alienId, msg.sender), "Incorrect player");
			uint256 rarityLevel = alien.getRarityFromDrop(alienId);
			_tokenIds.increment();
			uint256 id = _tokenIds.current();
     		_mint(msg.sender, id);
			ScifiLoot storage loot = lootItems[id];
			loot.tokenId = id;
			loot.alienId = alienId;
			loot.alienName = alien.getAlienName(alienId);
			loot.rarityLevel = rarityLevel;
			loot.exists = true;
			deadAliens[alienId] = true;

			uint256 rand = random(string(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) )));
			uint256 catIdx = rand % categories.length;

			loot.category = catIdx;

			approve(alien.getAddress(), id);

			emit LootMinted(_tokenIds.current(), rand);
			return id;
		}
	
	function tokenURI(uint256 id) public view override returns (string memory) {
		require(_exists(id), "not exist");
		ScifiLoot storage a = lootItems[id];
		return LootMetadataSvg.tokenURI( ownerOf(id), id, a.alienName, categories[a.category], a.rarityLevel );
	}

	function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

	function isTokenExists(uint256 id) public view returns(bool) {
		return _exists(id);
	}

	function getAddress() public view returns (address) {
		return address(this);
	}
}
