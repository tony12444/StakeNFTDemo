// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IGovernable} from "../interfaces/IGovernable.sol";
import {INFT} from "../interfaces/INFT.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract NFT is ERC721, INFT {
    using Strings for uint256;

    bytes32 public immutable root;                      // root
    uint256 public immutable cap;                       // max supply

    address public gov;                                 // manager address
    string public baseURI;                              // metadata uri
    uint256 public tokenId = 1;                         // token id, auto increase
    uint256 public startTime;                           // start mint time
    uint256 public endTime;                             // end mint time

    // This is a packed array of booleans.
    mapping(address => bool) public isMinted;           // is already minted

    constructor(address gov_, uint256 cap_, bytes32 root_, string memory name_, string memory symbol_) ERC721 (name_, symbol_){
        gov = gov_;
        cap = cap_;
        root = root_;
    }

    modifier onlyGov() {
        require(msg.sender == IGovernable(gov).gov(), "N_O0");
        _;
    }

    /// @notice change gov contract address ,only manager
    /// @param _gov new gov contract address
    function setGov(address _gov) external override onlyGov {
        gov = _gov;
        emit GovSettled(_gov);
    }

    /// @notice set uri for nft
    /// @param uri metadata uri for nft
    function setBaseURI(string calldata uri) external override onlyGov {
        baseURI = uri;
        emit BaseURISettled(uri);
    }

    /// @notice mint start time
    /// @param time start time
    function setStartTime(uint256 time) external override onlyGov {
        startTime = time;
        emit StartTimeSettled(time);
    }

    /// @notice mint end time
    /// @param time end time
    function setEndTime(uint256 time) external override onlyGov {
        endTime = time;
        emit EndTimeSettled(time);
    }

    /// @notice mint function only by white list minter
    /// @param  account minter address
    /// @param  merkleProof leaf proof hash array
    function whiteListMint(address account, bytes32[] calldata merkleProof) external override {
        require(block.timestamp >= startTime && startTime <= endTime, "N_F0");
        require(!isMinted[account], 'N_F1');
        require(tokenId < cap, 'N_F2');

        // Verify the merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(account));
        require(MerkleProof.verify(merkleProof, root, leaf), 'N_F3');

        // Mark it minted
        isMinted[account] = true;
        _safeMint(account, tokenId);

        emit Minted(account, tokenId);

        tokenId++;
    }

    /// @notice override from ERC721 tokenURI
    /// @param _tokenId nft token id
    /// @return nft uri
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireOwned(_tokenId);
        return bytes(baseURI).length > 0 ? string.concat(baseURI, _tokenId.toString()) : "";
    }
}
