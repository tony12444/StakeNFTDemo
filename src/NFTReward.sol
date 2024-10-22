// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {INFT} from "./interfaces/INFT.sol";
import {IBaseToken} from "./interfaces/IBaseToken.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IGovernable} from "./interfaces/IGovernable.sol";
import {INFTReward} from "./interfaces/INFTReward.sol";
import {NFT} from "./tokens/NFT.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "openzeppelin-contracts/lib/forge-std/src/interfaces/IERC721.sol";


contract NFTReward is INFTReward, IERC721Receiver, ReentrancyGuard {
    address public gov;                                            // manager contract address
    address public AZT;                                            // reward token
    address public stakeNFT;                                       // stake nft address

    uint256 constant public INIT_REWARD = 1000 * 1e18;             // init reward amount
    uint256 public interestRate;                                   // interest rate, compound interest ,scale 1e4

    struct StakeInfo {
        uint256 totalReward;
        uint256 claimed;
        uint256 lastUpdateTime;
    }

    mapping(uint256 => StakeInfo) public stakeInfos;                // tokenId => stake info
    mapping(uint256 => bool) public isClaimedInitialReward;         // tokenId => bool

    constructor(address gov_, address AZT_, address stakeNFT_){
        gov = gov_;
        AZT = AZT_;
        stakeNFT = stakeNFT_;
    }

    modifier onlyGov() {
        require(msg.sender == IGovernable(gov).gov(), "R_O0");
        _;
    }

    function setGov(address _gov) external override onlyGov {
        gov = _gov;
        emit GovSettled(_gov);
    }

    function setInterestRate(uint256 rate) external override onlyGov {
        interestRate = rate;
        emit InterestRateSettled(rate);
    }

    /// @notice withdraw token function
    /// @param token , withdraw token address
    /// @param dst, transfer address
    /// @param amount, transfer amount
    function withdrawToken(address token, address dst, uint256 amount) external override nonReentrant onlyGov {
        IERC20(token).transfer(dst, amount);
        emit WithdrawToken(token, dst, amount);
    }

    /// @notice stake function
    /// @param tokenId nft token id
    function stake(uint256 tokenId) external override nonReentrant {
        // transfer nft from owner
        IERC721(stakeNFT).safeTransferFrom(msg.sender, address(this), tokenId);
        _stake(msg.sender, tokenId);
    }

    /// @notice unStake function
    /// @param tokenId nft token id
    /// @param receiver asset receive address
    function unStake(uint256 tokenId, address receiver) external override nonReentrant {
        _unStake(msg.sender, tokenId, receiver);
    }

    /// @notice claim reward
    /// @param tokenId nft token id
    /// @param receiver, receiver address
    function claim(uint256 tokenId, address receiver) external override nonReentrant {
        address owner = IERC721(stakeNFT).ownerOf(tokenId);
        require(owner == msg.sender, 'N_C0');

        StakeInfo storage info = stakeInfos[tokenId];
        info.totalReward = _claimable(tokenId);
        uint256 claimableReward;
        if (info.totalReward > 0) {
            info.lastUpdateTime = block.timestamp;
            claimableReward = info.totalReward - stakeInfos[tokenId].claimed;

            if (claimableReward > 0) {
                IBaseToken(AZT).mint(receiver, claimableReward);
                info.claimed += claimableReward;
            }
        }

        emit Claimed(msg.sender, tokenId, receiver, claimableReward);
    }

    /// @notice calculate available rewards amount
    /// @param tokenId, nft token id
    function claimable(uint256 tokenId) external override view returns (uint256) {
        uint256 totalRewards = _claimable(tokenId);
        return totalRewards - stakeInfos[tokenId].claimed;
    }

    /// @notice internal stake function
    /// @param account owner of nft
    /// @param tokenId nft token id
    function _stake(address account, uint256 tokenId) internal {
        // If it's the initial stake, a reward of 1000 AZT  will be given.
        // Otherwise, you need to transfer 1000 AZT to the contract.
        if (isClaimedInitialReward[tokenId]) {
            // mint initial stake reward
            IBaseToken(AZT).mint(address(this), INIT_REWARD);
            isClaimedInitialReward[tokenId] = true;
        } else {
            // transfer principal from token owner
            IERC20(AZT).transferFrom(account, address(this), INIT_REWARD);
        }

        // update last time
        stakeInfos[tokenId].lastUpdateTime = block.timestamp;

        emit Staked(account, tokenId);
    }

    /// @notice unStake nft and init reward token
    /// @param account nft owner
    /// @param tokenId token id
    /// @param receiver asset receive address
    function _unStake(address account, uint256 tokenId, address receiver) internal {
        address owner = IERC721(stakeNFT).ownerOf(tokenId);
        require(owner == account, 'N_U0');

        StakeInfo memory info = stakeInfos[tokenId];
        // no staked
        require(info.lastUpdateTime == 0, 'N_U0');
        uint256 claimableReward = _claimable(tokenId) - info.claimed;
        // mint reward to owner
        if (claimableReward > 0) {
            IBaseToken(AZT).mint(receiver, claimableReward);
        }
        // nft and principal back to nft owner
        IERC721(stakeNFT).safeTransferFrom(address(this), receiver, tokenId);
        IERC20(AZT).transfer(receiver, INIT_REWARD);

        delete stakeInfos[tokenId];

        emit UnStaked(account, tokenId, receiver, claimableReward + INIT_REWARD);
    }

    /// @notice calculate total reward
    function _claimable(uint256 tokenId) internal view returns (uint256){
        StakeInfo memory info = stakeInfos[tokenId];
        if (info.lastUpdateTime == 0) return 0;
        // calculate the number of full days since the deposit
        uint256 deltaDays = (block.timestamp - info.lastUpdateTime) / 1 days;
        // use Taylor Expansion
        uint256 interestAndPrincipal = (info.totalReward + INIT_REWARD) * calculateCompoundedInterest(deltaDays) / 1e4;
        return interestAndPrincipal - INIT_REWARD;
    }

    /**
   * @dev Function to calculate the interest using a compounded interest rate formula
    * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
    *
    *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)]*x^3...
    *
    * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
    * gas cost reductions.

    * @notice calculate current interest
    * @param deltaDays interest rate per hour
    */
    function calculateCompoundedInterest(uint256 deltaDays) internal view returns (uint256) {
        uint256 expMinusOne = deltaDays > 1 ? deltaDays - 1 : 0;
        uint256 expMinusTwo = deltaDays > 2 ? deltaDays - 2 : 0;

        uint256 basePowerTwo = interestRate * interestRate / 1e4;
        uint256 basePowerThree = basePowerTwo * interestRate / 1e4;

        uint256 secondTerm = deltaDays * expMinusOne * basePowerTwo / 2;
        uint256 thirdTerm = deltaDays * expMinusOne * expMinusTwo * basePowerThree / 6;

        return 1e4 + (interestRate * deltaDays) + secondTerm + thirdTerm;
    }

    /// @notice  a contract address must implement this method to receive NFTs
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        (operator, from,tokenId,data);
        return this.onERC721Received.selector;
    }
}
