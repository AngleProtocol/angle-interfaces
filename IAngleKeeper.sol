// SPDX-License-Identifier: GNU GPLv3
pragma solidity >=0.8.2;

// ============================ IAngleKeeper.sol ===================================
// This file contains the interfaces for the contracts of Angle protocol with just
// the functions keepers can interact with. Anyone can be a keeper within Angle Protocol.
// Keepers interact with functions that are expensive to compute at each protocol interaction
// but that should still be called once in a while


/// @notice Interface for the keeper functions of `RewardsDistributor` contract
interface IRewardsDistributor {
    /// @notice Sends governance token to the staking contract
    /// @param stakingContract Reference to the staking contract
    /// @dev The keeper calling this function gets an incentive under the form of `ANGLE` tokens
    /// or another reward token
    function drip(IStakingRewards stakingContract) external returns (uint256);
}

interface Strategy{
    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting
    /// the Strategy's position.
    /// @dev Keepers do not get anything specific for calling this function. We expect 
    /// SLPs to be calling this function since they will be able to profit directly from 
    /// this call
    /// @dev Governance could vote to give rewards in the future to keepers calling this 
    /// function
    function harvest() external;

    /// @notice Provides a signal to the keeper that `harvest()` should be called. The
    /// keeper will provide the estimated gas cost that they would pay to call
    /// `harvest()`, and this function should use that estimate to make a
    /// determination if calling it is "worth it" for the keeper. This is not
    /// the only consideration into issuing this trigger, for example if the
    /// position would be negatively affected if `harvest()` is not called
    /// shortly, then this can return `true` even if the keeper might be "at a
    /// loss"
    /// @param callCostInWei The keeper's estimated gas cost to call `harvest()` (in wei).
    /// @return `true` if `harvest()` should be called, `false` otherwise.
    function harvestTrigger(uint256 callCostInWei) external view returns (bool);
}

/// @notice Interface for the keeper functions of the contract managing perpetuals
interface IPerpetualManager{
    /// @notice Allows an outside caller to liquidate perpetuals if their position is
    /// under the maintenance margin
    /// @param perpetualIDs ID of the targeted perpetuals
    /// @dev Keepers calling this function get a fraction of the remaining cash out amount
    /// of the perpetuals they liquidated
    function liquidatePerpetuals(uint256[] memory perpetualIDs) external;

    /// @notice Allows an outside caller to close perpetuals if too much of the collateral from
    /// users is hedged by HAs
    /// @param perpetualIDs IDs of the targeted perpetuals
    /// @dev This function allows to make sure that the protocol will not have too much HAs for a long period of time
    /// @dev The call to the function above will revert if HAs cannot be cashed out
    /// @dev As keepers may directly profit from this function, there may be front-running problems with miners bots,
    /// we may have to put an access control logic for this function to only allow white-listed addresses to act
    /// as keepers for the protocol
    function forceClosePerpetuals(uint256[] memory perpetualIDs) external;
}

/// @notice Interface for the `FeeManager` contract used to induce a dependency on collateral ratio for the users 
/// minting/burning fees
interface IFeeManager {
    /// @notice Updates the SLP and Users fees associated to the pair stablecoin/collateral in
    /// the `StableMaster` contract
    /// @dev This function updates:
    /// 	-	`bonusMalusMint`: part of the fee induced by a user minting depending on the collateral ratio
    ///                   In normal times, no fees are taken for that, and so this fee should be equal to BASE_PARAMS
    ///		-	`bonusMalusBurn`: part of the fee induced by a user burning depending on the collateral ratio
    ///		-	Slippage: what's given to SLPs compared with their claim when they exit
    ///		-	SlippageFee: that is the portion of fees that is put aside because the protocol
    ///         is not well collateralized
    /// @dev `bonusMalusMint` and `bonusMalusBurn` allow governance to add penalties or bonuses for users minting
    /// and burning in some situations of collateral ratio. These parameters are multiplied to the fee amount depending
    /// on coverage by Hedging Agents to get the exact fee induced to the users
    function updateUsersSLP() external;

    /// @notice Updates HA fees associated to the pair stablecoin/collateral in the `PerpetualManager` contract
    /// @dev This function updates:
    ///     - The part of the fee taken from HAs when they open a perpetual or add collateral in it. This allows
    ///        governance to add penalties or bonuses in some occasions to HAs opening their perpetuals
    ///     - The part of the fee taken from the HA when they withdraw collateral from a perpetual. This allows
    ///       governance to add penalty or bonuses in some occasions to HAs closing their perpetuals
    /// @dev Penalties or bonuses for HAs should almost never be used
    /// @dev In the `PerpetualManager` contract, these parameters are multiplied to the fee amount depending on the HA
    /// coverage to get the exact fee amount for HAs
    /// @dev For the moment, these parameters do not depend on the collateral ratio, and they are just an extra
    /// element that governance can play on to correct fees taken for HAs
    function updateHA() external;

}


interface IStakingRewards {}
