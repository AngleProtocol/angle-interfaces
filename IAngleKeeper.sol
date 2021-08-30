// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

interface IAgToken {}

interface IOracle {}

interface IStakingRewards {}

/// @notice Interface for the `RewardsDistributor` contract
interface IRewardsDistributor {
    /// @notice Sends governance token to the staking contract
    /// @param stakingContract Reference to the staking contract
    function drip(IStakingRewards stakingContract) external returns (uint256);
}

interface Strategy{
    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting
    /// the Strategy's position.
    function harvest() external;

    /// @notice Provides an indication of whether this strategy is currently "active"
    /// in that it is managing an active position, or will manage a position in
    /// the future.
    /// @return True if the strategy is actively managing a position.
    function isActive() external view returns (bool);

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

/// @notice Interface of the contract managing perpetuals
interface IPerpetualManager{
    /// @notice Allows an outside caller to liquidate perpetuals if their position is
    /// under the maintenance margin
    /// @param perpetualIDs ID of the targeted perpetuals
    function liquidatePerpetuals(uint256[] memory perpetualIDs) external;

    /// @notice Allows an outside caller to cash out a perpetual if too much of the collateral from
    /// users is covered by HAs
    /// @param perpetualIDs IDs of the targeted perpetuals
    /// @dev This function allows to make sure that the protocol will not have too much HAs for a long period of time
    function forceCashOutPerpetuals(uint256[] memory perpetualIDs) external;
}

/// @notice Interface for the `FeeManager` contract
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
    ///     - The part of the fee taken from HAs when they create a perpetual or add collateral in it. This allows
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